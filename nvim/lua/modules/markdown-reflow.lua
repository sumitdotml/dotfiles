-- re-wrapping lines with hidden text (mostly link URLs), since Neovim wraps by the full source
-- width even where it is concealed (neovim#14409); such a line is hidden and drawn again as
-- virtual lines wrapped by what is on screen, and the cursor line keeps the real text. tables
-- wider than the window are drawn the same way, with each cell wrapped inside its column
local M = {}
local api, fn = vim.api, vim.fn
local ns = api.nvim_create_namespace("markdown-reflow")
local CHAR = "[%z\1-\127\194-\244][\128-\191]*"
local BREAKAT = {}
for char in (" \t!@*-+;:,./?"):gmatch(".") do BREAKAT[char] = true end
-- matching render-markdown's default table border and highlights
local BORDER = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" }
local HEAD, BODY = "RenderMarkdownTableHead", "RenderMarkdownTableRow"
local queries, groups = {}, {} -- groups[buf] = list of { first, last, marks }
local table_query

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

-- finding the pipe tables that overlap rows [top, bot), with each row's cells and each column's alignment
local function find_tables(buf, top, bot)
	local found = {}
	local ok, parser = pcall(vim.treesitter.get_parser, buf)
	if not ok or not parser then return found end
	table_query = table_query or vim.treesitter.query.parse("markdown", "(pipe_table) @table")
	parser:for_each_tree(function(tree, ltree)
		if ltree:lang() ~= "markdown" then return end
		for _, node in table_query:iter_captures(tree:root(), buf, top, bot) do
			local tbl = { rows = {}, align = {} }
			for child in node:iter_children() do
				local kind = child:type()
				if kind == "pipe_table_delimiter_row" then
					for cell in child:iter_children() do
						if cell:type() == "pipe_table_delimiter_cell" then
							local left, right = false, false
							for part in cell:iter_children() do
								left = left or part:type() == "pipe_table_align_left"
								right = right or part:type() == "pipe_table_align_right"
							end
							tbl.align[#tbl.align + 1] = left and right and "center" or right and "right" or "left"
						end
					end
				elseif kind == "pipe_table_header" or kind == "pipe_table_row" then
					local row = { row = (child:range()), cells = {}, head = kind == "pipe_table_header" }
					for cell in child:iter_children() do
						if cell:type() == "pipe_table_cell" then
							local _, sc, _, ec = cell:range()
							row.cells[#row.cells + 1] = { sc, ec }
						end
					end
					tbl.rows[#tbl.rows + 1] = row
				end
			end
			if #tbl.rows > 0 then found[#found + 1] = tbl end
		end
	end)
	return found
end

-- gathering what other plugins draw on a row, or nil when it should stay as it is; a table row
-- leaves out render-markdown's borders and cell padding, since the table is drawn from scratch
local function decorations(buf, row, spans, avoid, in_table)
	local deco = { spans = vim.list_extend({}, spans), inline = {}, overlay = {}, concealed = false }
	for _, s in ipairs(spans) do deco.concealed = deco.concealed or s.conceal ~= nil end
	for _, m in ipairs(api.nvim_buf_get_extmarks(buf, -1, { row, 0 }, { row, -1 }, { details = true, overlap = true })) do
		local d = m[4]
		if avoid[d.ns_id] or d.ns_id ~= ns and d.conceal_lines then return end
		if d.ns_id ~= ns then
			-- leaving rows with images or borders of their own to the plugins that drew them
			if not in_table and (d.virt_lines or d.virt_text_win_col or d.virt_text_pos == "eol"
				or d.virt_text_pos == "right_align") then return end
			local sc = m[2] == row and m[3] or 0
			local ec = d.end_row == nil and sc or d.end_row > row and math.huge or d.end_col
			if d.hl_group and ec > sc then
				table.insert(deco.spans, { s = sc, e = ec, hl = list(d.hl_group), prio = d.priority or 4096 })
			end
			if d.conceal and ec > sc then
				table.insert(deco.spans, { s = sc, e = ec, hl = {}, prio = d.priority or 4096, conceal = d.conceal })
				deco.concealed = true
			end
			if d.virt_text and m[2] == row then
				local into = d.virt_text_pos == "inline" and deco.inline or d.virt_text_pos == "overlay" and deco.overlay
				if in_table and (into == deco.overlay
					or not table.concat(vim.tbl_map(function(chunk) return chunk[1] end, d.virt_text)):find("%S")) then
					into = nil
				end
				if into then
					into[sc] = into[sc] or {}
					vim.list_extend(into[sc], d.virt_text)
				end
			end
		end
	end
	return deco
end

-- working out each character's highlights and whether it is hidden or replaced, ending with an
-- empty cell at the end of the line for virtual text placed there
local function paint(line, spans)
	local cells, pos = {}, 0
	for char in line:gmatch(CHAR) do
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
	cells[#cells + 1] = { s = pos, hl = {} }
	return cells
end

-- laying out the characters that start in bytes [s, e) as single units, as they show on screen
local function layout(cells, deco, s, e)
	local units, cover = {}, 0
	local function add(text, hl)
		for char in text:gmatch(CHAR) do
			units[#units + 1] = { text = char, hl = hl, w = fn.strdisplaywidth(char) }
		end
	end
	local function virt(chunks)
		for _, chunk in ipairs(chunks) do add(chunk[1], list(chunk[2])) end
	end
	for _, cell in ipairs(cells) do
		if cell.s >= s and cell.s < e then
			if deco.inline[cell.s] then virt(deco.inline[cell.s]) end
			if deco.overlay[cell.s] and not cell.hidden then
				virt(deco.overlay[cell.s])
				for _, chunk in ipairs(deco.overlay[cell.s]) do cover = cover + fn.strdisplaywidth(chunk[1]) end
			end
			local text = cell.text
			if cell.hidden then text = cell.repl end
			if text and cover > 0 then
				cover = cover - fn.strdisplaywidth(text)
			elseif text then
				add(text, cell.hl)
			end
		end
	end
	return units
end

-- turning one row into units of what is on screen, or nil when it should stay as it is
local function render_row(buf, row, line, spans, avoid)
	local deco = decorations(buf, row, spans, avoid, false)
	if not deco or not deco.concealed then return end
	return layout(paint(line, deco.spans), deco, 0, math.huge)
end

local function width_of(units)
	local w = 0
	for _, unit in ipairs(units) do w = w + unit.w end
	return w
end

-- wrapping like 'linebreak': after the last 'breakat' character that fits, dropping the spaces
-- left at the end of each row
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
	for _, r in ipairs(rows) do
		while #r > 0 and r[#r].text == " " do r[#r] = nil end
	end
	return rows
end

-- merging runs that share highlights into virtual-text chunks
local function chunks(units)
	local out, last = {}, nil
	for _, unit in ipairs(units) do
		local key = table.concat(unit.hl, ",")
		if key == last then
			out[#out][1] = out[#out][1] .. unit.text
		else
			out[#out + 1] = { unit.text, #unit.hl > 0 and unit.hl or "Normal" }
		end
		last = key
	end
	return out
end

-- drawing a table as virtual lines with each cell wrapped inside its column, or nil when it fits
-- as it is or cannot be copied
local function draw_table(buf, tbl, spans, avoid, width)
	local header = api.nvim_buf_get_lines(buf, tbl.rows[1].row, tbl.rows[1].row + 1, false)[1]
	local indent = header:match("^%s*")
	-- leaving tables inside quotes, whose markers come before the first cell
	if header:sub(#indent + 1, #indent + 1) ~= "|" and tbl.rows[1].cells[1][1] ~= #indent then return end
	local cols = #tbl.align
	local grid = {}
	for i, r in ipairs(tbl.rows) do
		local line = api.nvim_buf_get_lines(buf, r.row, r.row + 1, false)[1]
		local deco = decorations(buf, r.row, spans[r.row] or {}, avoid, true)
		if not deco then return end
		local cells = paint(line, deco.spans)
		grid[i] = {}
		for c = 1, cols do
			local units = r.cells[c] and layout(cells, deco, r.cells[c][1], r.cells[c][2]) or {}
			while #units > 0 and units[1].text == " " do table.remove(units, 1) end
			while #units > 0 and units[#units].text == " " do units[#units] = nil end
			grid[i][c] = units
		end
	end

	-- shrinking the widest column a character at a time, down to its longest word if possible
	local widths, least = {}, {}
	for c = 1, cols do widths[c], least[c] = 1, 1 end
	for _, row in ipairs(grid) do
		for c, units in ipairs(row) do
			local word = 0
			for _, unit in ipairs(units) do
				word = unit.text == " " and 0 or word + unit.w
				least[c] = math.max(least[c], word)
			end
			widths[c] = math.max(widths[c], width_of(units))
		end
	end
	local pad = fn.strdisplaywidth(indent)
	local room, total = width - pad - 3 * cols - 1, 0
	for c = 1, cols do total = total + widths[c] end
	if total <= room then return end
	while total > room do
		local pick
		for c = 1, cols do
			if widths[c] > least[c] and (not pick or widths[c] > widths[pick]) then pick = c end
		end
		if not pick then
			for c = 1, cols do
				if widths[c] > 1 and (not pick or widths[c] > widths[pick]) then pick = c end
			end
		end
		if not pick then return end
		widths[pick], total = widths[pick] - 1, total - 1
	end

	local lead = (" "):rep(pad)
	local function rule(left, mid, right, hl)
		local parts = {}
		for c = 1, cols do parts[c] = BORDER[11]:rep(widths[c] + 2) end
		return { { lead .. left .. table.concat(parts, mid) .. right, hl } }
	end
	local lines = { rule(BORDER[1], BORDER[2], BORDER[3], HEAD) }
	for i, row in ipairs(grid) do
		local hl = tbl.rows[i].head and HEAD or BODY
		local wrapped, height = {}, 1
		for c = 1, cols do
			wrapped[c] = wrap(row[c], widths[c])
			height = math.max(height, #wrapped[c])
		end
		for h = 1, height do
			local line = { { lead .. BORDER[10], hl } }
			for c = 1, cols do
				local units = wrapped[c][h] or {}
				local fill = widths[c] - width_of(units)
				local before = tbl.align[c] == "right" and fill or tbl.align[c] == "center" and math.floor(fill / 2) or 0
				line[#line + 1] = { (" "):rep(before + 1), "Normal" }
				vim.list_extend(line, chunks(units))
				line[#line + 1] = { (" "):rep(fill - before + 1), "Normal" }
				line[#line + 1] = { BORDER[10], hl }
			end
			lines[#lines + 1] = line
		end
		-- separating the rows, since a wrapped cell otherwise runs into the row below it
		if i < #grid then lines[#lines + 1] = rule(BORDER[4], BORDER[5], BORDER[6], i == 1 and HEAD or BODY) end
	end
	lines[#lines + 1] = rule(BORDER[7], BORDER[8], BORDER[9], BODY)
	return lines
end

-- checking that a row is shown and has no virtual lines on the given side from another plugin
local function free(buf, row, above)
	if row < 0 or row >= api.nvim_buf_line_count(buf) then return false end
	for _, m in ipairs(api.nvim_buf_get_extmarks(buf, -1, { row, 0 }, { row, -1 }, { details = true })) do
		local d = m[4]
		if d.ns_id ~= ns and (d.conceal_lines or d.virt_lines and not d.virt_lines_above == not above) then
			return false
		end
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
	local tables, in_table = find_tables(buf, top, bot), {}
	local from, to = top, bot
	for _, tbl in ipairs(tables) do
		from, to = math.min(from, tbl.rows[1].row), math.max(to, tbl.rows[#tbl.rows].row + 1)
		for row = tbl.rows[1].row, tbl.rows[#tbl.rows].row do in_table[row] = true end
	end
	local spans = treesitter_spans(buf, from, to)
	local flowed = {}
	for i, line in ipairs(api.nvim_buf_get_lines(buf, top, bot, false)) do
		local row = top + i - 1
		if not opts.keep[row + 1] and not in_table[row] and fn.strdisplaywidth(line) > opts.width then
			local units = render_row(buf, row, line, spans[row] or {}, opts.avoid)
			if units then flowed[row] = vim.tbl_map(chunks, wrap(units, opts.width)) end
		end
	end

	local want, hidden = {}, {}
	local function shown(r) return not flowed[r] and not in_table[r] and not hidden[r] end
	-- hanging the lines above the row after the hidden rows where possible: Neovim scrolls down
	-- through lines hung there a row at a time, but skips lines hung below the row before them in
	-- one jump; skipping a row with virtual lines from another plugin on that side, as the order of
	-- two plugins' lines on one row is not fixed
	local function add(first, last, lines, bottom)
		local above
		if shown(last + 1) and free(buf, last + 1, true) then
			above = true
		elseif shown(first - 1) and free(buf, first - 1) then
			above = false
		else
			return
		end
		for r = first, last do hidden[r] = true end
		local key = ("%d:%d:%s:%s"):format(first, last, tostring(above), vim.json.encode({ lines, bottom }))
		want[key] = { first = first, last = last, lines = lines, above = above, bottom = bottom, key = key }
	end
	local function blank(r)
		local line = api.nvim_buf_get_lines(buf, r, r + 1, false)[1]
		return r >= 0 and line ~= nil and fn.strdisplaywidth(line) == 0
	end
	-- drawing tables first, so paragraphs do not hang lines on the blank lines tables take over
	for _, tbl in ipairs(tables) do
		local first, last = tbl.rows[1].row, tbl.rows[#tbl.rows].row
		-- taking over the blank line above, where render-markdown draws the top border, unless it
		-- holds the bottom border of a table just above
		if blank(first - 1) and not in_table[first - 2] then first = first - 1 end
		local keep = false
		for r = first, last do keep = keep or opts.keep[r + 1] end
		local lines = not keep and draw_table(buf, tbl, spans, opts.avoid, opts.width)
		if lines then
			-- drawing the bottom border over the blank line below, covering render-markdown's own
			-- across the whole window, since its table is wider than the text width
			local bottom
			if blank(last + 1) then
				local cover = 0
				for _, win in ipairs(fn.win_findbuf(buf)) do cover = math.max(cover, api.nvim_win_get_width(win)) end
				bottom = table.remove(lines)
				bottom[2] = { (" "):rep(math.max(0, cover - fn.strdisplaywidth(bottom[1][1]))), "Normal" }
			end
			add(first, last, lines, bottom)
		end
	end
	local row = top
	while row < bot do
		if flowed[row] then
			local first, last, lines = row, row, {}
			while flowed[last + 1] do last = last + 1 end
			for r = first, last do vim.list_extend(lines, flowed[r]) end
			add(first, last, lines)
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
		if group.bottom then
			group.marks[#group.marks + 1] = api.nvim_buf_set_extmark(buf, ns, group.last + 1, 0,
				{ virt_text = group.bottom, virt_text_pos = "overlay", priority = 8192, undo_restore = false })
		end
		group.marks[#group.marks + 1] = api.nvim_buf_set_extmark(buf, ns,
			group.above and group.last + 1 or group.first - 1, 0,
			{ virt_lines = group.lines, virt_lines_above = group.above, undo_restore = false })
		kept[#kept + 1] = group
	end
	groups[buf] = kept
	-- repainting, since after a scroll Neovim leaves stale rows where these virtual lines are
	if #kept > 0 then
		for _, win in ipairs(fn.win_findbuf(buf)) do api.nvim__redraw({ win = win, valid = false }) end
	end
end

return M
