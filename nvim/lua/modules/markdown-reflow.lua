-- re-wrapping lines with hidden text (mostly link URLs), since Neovim wraps by the full source
-- width even where it is concealed (neovim#14409); such a line is hidden and drawn again as
-- virtual lines wrapped by what is on screen, and the cursor line keeps the real text
local M = {}
local api, fn = vim.api, vim.fn
local ns = api.nvim_create_namespace("markdown-reflow")
local BREAKAT = {}
for char in (" \t!@*-+;:,./?"):gmatch(".") do BREAKAT[char] = true end
local queries, groups = {}, {} -- groups[buf] = list of { first, last, marks }

local function list(hl)
	if type(hl) == "table" then return hl end
	return hl and { hl } or {}
end

-- collecting the highlight and conceal spans treesitter draws on rows [top, bot)
local function treesitter_spans(buf, top, bot)
	local spans = {}
	local ok, parser = pcall(vim.treesitter.get_parser, buf)
	if not ok or not parser then return spans end
	parser:for_each_tree(function(tree, ltree)
		local lang = ltree:lang()
		if queries[lang] == nil then queries[lang] = vim.treesitter.query.get(lang, "highlights") or false end
		local query = queries[lang]
		if not query then return end
		for id, node, metadata in query:iter_captures(tree:root(), buf, top, bot) do
			local name = query.captures[id]
			local meta = metadata[id] or {}
			local conceal = meta.conceal or metadata.conceal
			local hl = not name:find("^_") and name ~= "spell" and name ~= "nospell" and name ~= "conceal"
				and ("@" .. name .. "." .. lang) or nil
			if hl or conceal then
				local sr, sc, er, ec = node:range()
				if ec == 0 and er > sr then er, ec = er - 1, math.huge end
				for row = math.max(sr, top), math.min(er, bot - 1) do
					spans[row] = spans[row] or {}
					table.insert(spans[row], { s = row == sr and sc or 0, e = row == er and ec or math.huge,
						hl = list(hl), prio = tonumber(meta.priority or metadata.priority) or 100, conceal = conceal })
				end
			end
		end
	end)
	return spans
end

-- turning one row into chunks of what is on screen, or nil when it should stay as it is
local function render_row(buf, row, line, spans, avoid)
	local inline, overlay, concealed = {}, {}, false
	spans = vim.list_extend({}, spans)
	for _, s in ipairs(spans) do concealed = concealed or s.conceal ~= nil end
	for _, m in ipairs(api.nvim_buf_get_extmarks(buf, -1, { row, 0 }, { row, -1 }, { details = true, overlap = true })) do
		local d = m[4]
		if avoid[d.ns_id] then return end
		if d.ns_id ~= ns then
			-- leaving rows with images, borders or hidden lines of their own to the plugins that drew them
			if d.virt_lines or d.conceal_lines or d.virt_text_win_col or d.virt_text_pos == "eol"
				or d.virt_text_pos == "right_align" then return end
			local sc = m[2] == row and m[3] or 0
			local ec = d.end_row == nil and sc or d.end_row > row and math.huge or d.end_col
			if d.hl_group and ec > sc then
				table.insert(spans, { s = sc, e = ec, hl = list(d.hl_group), prio = d.priority or 4096 })
			end
			if d.conceal and ec > sc then
				table.insert(spans, { s = sc, e = ec, hl = {}, prio = d.priority or 4096, conceal = d.conceal })
				concealed = true
			end
			if d.virt_text and m[2] == row then
				local into = d.virt_text_pos == "inline" and inline or d.virt_text_pos == "overlay" and overlay
				if into then
					into[sc] = into[sc] or {}
					vim.list_extend(into[sc], d.virt_text)
				end
			end
		end
	end
	if not concealed then return end

	local cells, pos = {}, 0
	for char in line:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		cells[#cells + 1] = { s = pos, text = char, hl = {} }
		pos = pos + #char
	end
	for i, s in ipairs(spans) do s.i = i end
	table.sort(spans, function(a, b) return a.prio == b.prio and a.i < b.i or a.prio < b.prio end)
	for _, s in ipairs(spans) do
		local first = true
		for _, cell in ipairs(cells) do
			if cell.s >= s.s and cell.s < s.e then
				vim.list_extend(cell.hl, s.hl)
				if s.conceal then
					cell.hidden = true
					if first and s.conceal ~= "" then cell.repl = s.conceal end
					first = false
				end
			end
		end
	end

	-- laying the cells out as one long run of single characters
	local units, cover = {}, 0
	local function add(text, hl)
		for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
			units[#units + 1] = { text = char, hl = hl, w = fn.strdisplaywidth(char) }
		end
	end
	local function virt(chunks)
		for _, chunk in ipairs(chunks) do add(chunk[1], list(chunk[2])) end
	end
	for _, cell in ipairs(cells) do
		if inline[cell.s] then virt(inline[cell.s]) end
		if overlay[cell.s] and not cell.hidden then
			virt(overlay[cell.s])
			for _, chunk in ipairs(overlay[cell.s]) do cover = cover + fn.strdisplaywidth(chunk[1]) end
		end
		local text = cell.text
		if cell.hidden then text = cell.repl end
		if text and cover > 0 then
			cover = cover - fn.strdisplaywidth(text)
		elseif text then
			add(text, cell.hl)
		end
	end
	if inline[#line] then virt(inline[#line]) end
	return units
end

-- wrapping like 'linebreak': after the last 'breakat' character that fits, letting spaces hang
local function wrap(units, width)
	local rows, row, used, brk = {}, {}, 0, nil
	for _, unit in ipairs(units) do
		if used + unit.w > width and #row > 0 and unit.text ~= " " then
			local rest = {}
			if brk and brk < #row then
				for i = brk + 1, #row do rest[#rest + 1] = row[i] end
				for i = #row, brk + 1, -1 do row[i] = nil end
			end
			rows[#rows + 1] = row
			row, used, brk = rest, 0, nil
			for i, r in ipairs(row) do
				used = used + r.w
				if BREAKAT[r.text] then brk = i end
			end
		end
		row[#row + 1] = unit
		used = used + unit.w
		if BREAKAT[unit.text] then brk = #row end
	end
	rows[#rows + 1] = row
	-- merging runs that share highlights into virtual-text chunks
	local lines = {}
	for _, r in ipairs(rows) do
		local chunks, last = {}, nil
		for _, unit in ipairs(r) do
			local key = table.concat(unit.hl, ",")
			if key == last then
				chunks[#chunks][1] = chunks[#chunks][1] .. unit.text
			else
				chunks[#chunks + 1] = { unit.text, #unit.hl > 0 and unit.hl or "Normal" }
			end
			last = key
		end
		lines[#lines + 1] = chunks
	end
	return lines
end

-- checking that a row is shown and has no virtual lines below it from another plugin
local function free(buf, row)
	if row < 0 then return false end
	for _, m in ipairs(api.nvim_buf_get_extmarks(buf, -1, { row, 0 }, { row, -1 }, { details = true })) do
		local d = m[4]
		if d.ns_id ~= ns and (d.conceal_lines or d.virt_lines and not d.virt_lines_above) then return false end
	end
	return true
end

function M.clear(buf)
	groups[buf] = nil
	if api.nvim_buf_is_valid(buf) then api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
end

-- giving rows (1-based, the cursor and Visual lines) their real text back right away
function M.reveal(buf, rows)
	for i = #(groups[buf] or {}), 1, -1 do
		local group = groups[buf][i]
		for row = group.first, group.last do
			if rows[row + 1] then
				for _, id in ipairs(group.marks) do api.nvim_buf_del_extmark(buf, ns, id) end
				table.remove(groups[buf], i)
				break
			end
		end
	end
end

-- opts: keep, rows to leave alone (1-based); width, the text width; avoid, namespaces (images,
-- headings) whose rows are drawn some other way
function M.update(buf, opts)
	local top, bot = math.huge, 0
	for _, win in ipairs(fn.win_findbuf(buf)) do
		top = math.min(top, fn.line("w0", win) - 11)
		bot = math.max(bot, fn.line("w$", win) + 10)
	end
	top, bot = math.max(0, top), math.min(api.nvim_buf_line_count(buf), bot)
	local spans = treesitter_spans(buf, top, bot)
	local flowed = {}
	for i, line in ipairs(api.nvim_buf_get_lines(buf, top, bot, false)) do
		local row = top + i - 1
		-- skipping rows that do not wrap, and table rows, whose cells render-markdown pads itself
		if not opts.keep[row + 1] and fn.strdisplaywidth(line) > opts.width and not line:find("^%s*|") then
			local units = render_row(buf, row, line, spans[row] or {}, opts.avoid)
			if units then flowed[row] = wrap(units, opts.width) end
		end
	end

	local want, row = {}, top
	while row < bot do
		if flowed[row] then
			local first, last, lines = row, row, {}
			while flowed[last + 1] do last = last + 1 end
			for r = first, last do vim.list_extend(lines, flowed[r]) end
			-- hanging the lines below the previous row, since Ctrl-Y cannot scroll up past a row with
			-- them above it; leaving the group alone when that row has virtual lines from another
			-- plugin, as the order of two plugins' lines on one row is not fixed
			if free(buf, first - 1) then
				local key = ("%d:%d:%s"):format(first, last, vim.json.encode(lines))
				want[key] = { first = first, last = last, lines = lines, key = key }
			end
			row = last + 1
		else
			row = row + 1
		end
	end

	-- touching only groups that changed: render-markdown redraws on every scroll, and recreating
	-- hidden lines then resets the view, which stopped Ctrl-Y from scrolling up
	local kept = {}
	for _, group in ipairs(groups[buf] or {}) do
		local mark = api.nvim_buf_get_extmark_by_id(buf, ns, group.marks[1], {})
		local at = mark[1]
		local inside = at and at <= bot and at + (group.last - group.first) >= top
		if at and want[group.key] and at == group.first then
			want[group.key] = nil
			kept[#kept + 1] = group
		elseif at and not inside then
			kept[#kept + 1] = group
		else
			for _, id in ipairs(group.marks) do api.nvim_buf_del_extmark(buf, ns, id) end
		end
	end
	for _, group in pairs(want) do
		group.marks = {}
		for r = group.first, group.last do
			group.marks[#group.marks + 1] = api.nvim_buf_set_extmark(buf, ns, r, 0, { conceal_lines = "", undo_restore = false })
		end
		group.marks[#group.marks + 1] = api.nvim_buf_set_extmark(buf, ns, group.first - 1, 0,
			{ virt_lines = group.lines, undo_restore = false })
		kept[#kept + 1] = group
	end
	groups[buf] = kept
	-- repainting, since after a scroll Neovim leaves stale rows where these virtual lines are
	if #kept > 0 then
		for _, win in ipairs(fn.win_findbuf(buf)) do api.nvim__redraw({ win = win, valid = false }) end
	end
end

return M
