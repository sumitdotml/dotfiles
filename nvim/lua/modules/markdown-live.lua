-- native Markdown live view: larger headings and inline images drawn with Snacks
-- Unicode-placeholder placements; buffer text is never touched, only extmarks
--
-- needs a terminal with Kitty Unicode placeholders (Kitty, Ghostty, Rex via
-- SNACKS_KITTY) and, for heading images, macOS with the Command Line Tools;
-- anything else gets text headings without warnings
local M = {}
local api, fn = vim.api, vim.fn
local uv = vim.uv or vim.loop
local root = fn.stdpath("cache") .. "/markdown-live"
local helper = root .. "/heading-image"
local source = fn.stdpath("config") .. "/markdown/heading-image.swift"
local ns = api.nvim_create_namespace("markdown-live")
local FILETYPES = { markdown = true, mdx = true }
local MAX_COLS, MIN_COLS = 100, 20
-- "system" (SF Pro), "serif" (New York), "rounded" (SF Pro Rounded) or "mono" (SF Mono)
local HEADING_FONT = "system"
-- shrinking bigger images, since Rex drops images past its memory limit and a 5K screenshot
-- takes ~60 MB, which left one of a few screenshots on a page blank
local MAX_IMAGE_PX = 1920
local IMAGE_HEIGHT = 0.7 -- tallest image, as a share of the window height

local reflow = require("modules.markdown-reflow")
local states, assets, normalized, failed, warned = {}, {}, {}, {}, {}
local helper_status = "unknown" -- unknown | building | ready | failed | unavailable
local generating, version, query = false, "", nil
local refresh, reveal

local function warn_once(key, msg)
	if warned[key] then return end
	warned[key] = true
	vim.notify("Markdown live: " .. msg, vim.log.levels.WARN)
end

-- reporting a missing executable (vim.system throws) like any failed run
local function run(cmd, opts, on_exit)
	opts = vim.tbl_extend("keep", opts or {}, { text = true, timeout = 15000 })
	local ok, err = pcall(vim.system, cmd, opts, function(result) vim.schedule(function() on_exit(result) end) end)
	if not ok then vim.schedule(function() on_exit({ code = -1, stdout = "", stderr = tostring(err) }) end) end
end

local function png_info(path)
	local file = io.open(path, "rb")
	if not file then return end
	local header = file:read(26)
	file:close()
	if not header or #header < 26 or header:sub(1, 8) ~= "\137PNG\r\n\26\n" then return end
	local function number(pos)
		local a, b, c, d = header:byte(pos, pos + 3)
		return ((a * 256 + b) * 256 + c) * 256 + d
	end
	return { width = number(17), height = number(21), depth = header:byte(25), color = header:byte(26) }
end

-- skipping terminals without placeholders, where Snacks falls back to screen coordinates
local function images_ok()
	local env = Snacks.image.terminal.env()
	return env.supported and env.placeholders or false
end

local function schedule(state, full)
	state.full = state.full or full
	if state.queued then return end
	state.queued = true
	vim.defer_fn(function()
		state.queued = false
		if states[state.buf] == state and state.enabled and api.nvim_buf_is_valid(state.buf) then refresh(state) end
	end, 30)
end

local function each_state(full)
	for _, state in pairs(states) do if state.enabled then schedule(state, full) end end
end

-- converting 16-bit and other non-RGB(A) PNGs in the background, since Rex leaves them blank,
-- and shrinking big ones, which Snacks only does for other formats
local function normalize(path)
	local stat = uv.fs_stat(path)
	if not stat then return path end -- remote URLs, which Snacks downloads itself
	local key = path .. stat.size .. stat.mtime.sec .. stat.mtime.nsec
	if normalized[key] ~= nil then return normalized[key] or nil end
	local info = png_info(path)
	local small = info and info.width <= MAX_IMAGE_PX and info.height <= MAX_IMAGE_PX
	if not info or (small and info.depth == 8 and (info.color == 2 or info.color == 6)) then
		normalized[key] = path
		return path
	end
	local target = root .. "/image-" .. fn.sha256(key .. MAX_IMAGE_PX) .. ".png"
	if uv.fs_stat(target) then
		normalized[key] = target
		return target
	end
	normalized[key] = false
	local tmp = ("%s.%d.tmp"):format(target, uv.os_getpid())
	local magick = fn.executable("magick") == 1 and "magick" or "convert" -- ImageMagick 7 or 6
	local fit = ("%dx%d>"):format(MAX_IMAGE_PX, MAX_IMAGE_PX)
	run({ magick, path, "-depth", "8", "-resize", fit, "PNG32:" .. tmp }, {}, function(result)
		if result.code == 0 and uv.fs_rename(tmp, target) then
			normalized[key] = target
		else
			pcall(uv.fs_unlink, tmp)
			normalized[key] = path
			warn_once("magick", "could not convert " .. fn.fnamemodify(path, ":~:.") .. " (is ImageMagick installed?)")
		end
		each_state(false)
	end)
end

local function close(collection)
	for key, item in pairs(collection) do
		item.placement:close()
		collection[key] = nil
	end
end

local function close_all(state)
	close(state.headings)
	close(state.media)
	if api.nvim_buf_is_valid(state.buf) then api.nvim_buf_clear_namespace(state.buf, ns, 0, -1) end
	reflow.clear(state.buf)
end

-- measuring the narrowest and shortest window showing the buffer, without the sign column
local function text_area(buf)
	local cols, rows = MAX_COLS, math.huge
	for _, win in ipairs(fn.win_findbuf(buf)) do
		cols = math.min(cols, api.nvim_win_get_width(win) - fn.getwininfo(win)[1].textoff)
		rows = math.min(rows, api.nvim_win_get_height(win))
	end
	return cols, rows
end

local function refresh_media(state)
	Snacks.image.doc.find_visible(state.buf, function(matches)
		if not state.enabled or not api.nvim_buf_is_valid(state.buf) then return end
		-- filling the text width like GitHub does, but never taller than most of the window
		local cols, rows = text_area(state.buf)
		local max_width, max_height = math.max(MIN_COLS, cols), math.floor(rows * IMAGE_HEIGHT)
		local keep = {}
		for _, image in ipairs(matches) do
			if image.src then
				local src = normalize(image.src)
				local key = table.concat(image.range or image.pos, ":") .. image.src
				keep[key] = true
				if src and not state.media[key] then
					state.media[key] = { placement = Snacks.image.placement.new(state.buf, src, {
						-- keeping inline: a failed non-inline placement overwrites the buffer with an error report
						pos = image.pos, range = image.range, inline = true, conceal = false,
						max_width = max_width, max_height = max_height, type = image.type,
					}) }
				elseif src then
					local opts = state.media[key].placement.opts
					if opts.max_width ~= max_width or opts.max_height ~= max_height then
						opts.max_width, opts.max_height = max_width, max_height
						state.media[key].placement:update()
					end
				end
			end
		end
		for key, item in pairs(state.media) do
			if not keep[key] then item.placement:close(); state.media[key] = nil end
		end
	end)
end

local function hl_color(names, attr, fallback)
	for _, name in ipairs(names) do
		local value = api.nvim_get_hl(0, { name = name, link = false })[attr]
		if value then return ("%06x"):format(value) end
	end
	return fallback
end

local function style()
	local cell = Snacks.image.terminal.size()
	local s = {
		cw = cell.cell_width > 0 and cell.cell_width or 9,
		ch = cell.cell_height > 0 and cell.cell_height or 18,
		bg = hl_color({ "Normal" }, "bg", "1e1e2e"),
		code = hl_color({ "@markup.raw.markdown_inline", "@markup.raw" }, "fg", "a6e3a1"),
		rule = hl_color({ "RenderMarkdownDash", "LineNr" }, "fg", "45475a"),
		fg = {},
	}
	for level = 1, 3 do
		s.fg[level] = hl_color({ "@markup.heading." .. level .. ".markdown", "@markup.heading", "Title" }, "fg", "cdd6f4")
	end
	return s
end

local function headings(buf)
	local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
	if not ok or not parser then return {} end
	query = query or vim.treesitter.query.parse("markdown", "(atx_heading) @heading")
	local list = {}
	for _, node in query:iter_captures(parser:parse()[1]:root(), buf, 0, -1) do
		local row, col = node:start()
		local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
		-- matching empty headings too ("#" alone), which GitHub draws as just their rule
		local hashes, text = line:match("^(#+)%s*(.-)%s*$")
		-- leaving headings inside quotes and lists (col > 0) as text
		if col == 0 and hashes then
			text = text:gsub("%s+#+$", ""):gsub("^#+$", "")
			list[#list + 1] = { row = row, level = #hashes, text = text, length = #line }
		end
	end
	return list
end

local function lookup(key, s)
	if assets[key] == nil then
		local path = root .. "/heading-" .. key .. ".png"
		local info = png_info(path)
		assets[key] = info and { path = path, rows = math.max(1, math.floor(info.height / s.ch + 0.5)),
			cols = math.max(1, math.floor(info.width / s.cw + 0.5)) } or false
	end
	return assets[key] or nil
end

-- reading the row from the placement's extmark, which follows inserted and deleted lines
local function placed_row(placement)
	local id = placement.eids and placement.eids[1]
	local mark = id and api.nvim_buf_get_extmark_by_id(placement.buf, Snacks.image.placement.ns, id, {})
	return mark and mark[1] or placement.opts.pos[1] - 1
end

local function refresh_headings(state)
	local buf = state.buf
	local cols = text_area(buf)
	-- stopping a column short, since Neovim wraps a line whose inline image fills the window
	-- exactly, which gave the one-row image of an empty # a blank row under it
	local width = cols - 1
	local list = headings(buf)
	-- hiding the # marker on every level; Neovim shows it again on the cursor line
	api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, h in ipairs(list) do
		api.nvim_buf_set_extmark(buf, ns, h.row, 0, { end_col = math.min(h.level + 1, h.length),
			conceal = "", undo_restore = false, invalidate = true })
	end
	if helper_status ~= "ready" or cols < MIN_COLS or not images_ok() then return close(state.headings) end

	local s = style()
	local by_row, keep, pending, rows = {}, {}, {}, reveal(state)
	local typing = api.nvim_get_mode().mode:find("^[iR]") ~= nil
	for placement, entry in pairs(state.headings) do by_row[placed_row(placement)] = entry end
	for _, h in ipairs(list) do
		-- only hiding the # of an empty H3, which has no rule to draw
		if h.level <= 3 and (h.text ~= "" or h.level <= 2) then
			local ident = h.level .. "\0" .. h.text
			-- drawing H1 and H2 across the window with a rule under them, so their image depends on the width
			local rule = h.level <= 2 and s.rule or nil
			local fit = fn.sha256(table.concat({ version, ident, s.cw, s.ch, s.fg[h.level], s.code, s.bg,
				HEADING_FONT, rule and (rule .. width) or "" }, "\0"))
			local wrap = rule and fit or fn.sha256(fit .. width)
			local asset, key = lookup(fit, s), fit
			if not asset or asset.cols > width then asset, key = lookup(wrap, s), wrap end
			-- keeping the old image of the same text until its resized or recoloured copy is ready
			local entry = by_row[h.row]
			if entry and (asset and entry.key ~= key or not asset and entry.ident ~= ident) then entry = nil end
			if not entry and asset then
				local placement = Snacks.image.placement.new(buf, asset.path, { inline = true, conceal = true,
					pos = { h.row + 1, 0 }, range = { h.row + 1, 0, h.row + 1, h.length },
					width = asset.cols, height = asset.rows })
				placement.hidden = rows[h.row + 1] or nil
				entry = { placement = placement, key = key }
			end
			if entry then
				entry.ident, entry.row = ident, h.row
				entry.placement.opts.pos = { h.row + 1, 0 }
				entry.placement.opts.range = { h.row + 1, 0, h.row + 1, h.length }
				keep[entry.placement] = entry
			end
			-- skipping the heading being typed, which would otherwise mean one PNG per keystroke
			if not asset and not (typing and rows[h.row + 1]) and not failed[fit] then
				pending[fit] = { fitKey = fit, wrapKey = wrap, text = h.text, level = h.level,
					width = math.floor(width * s.cw), cellWidth = s.cw, cellHeight = s.ch,
					foreground = s.fg[h.level], code = s.code, background = s.bg, rule = rule, font = HEADING_FONT,
					fitPath = root .. "/heading-" .. fit .. ".png", wrapPath = root .. "/heading-" .. wrap .. ".png" }
			end
		end
	end
	for placement in pairs(state.headings) do
		if not keep[placement] then placement:close() end
	end
	state.headings = keep
	reveal(state)

	local batch = vim.tbl_values(pending)
	if #batch == 0 or generating then return end
	generating = true
	run({ helper }, { stdin = vim.json.encode(batch) }, function(result)
		generating = false
		local ok, made = pcall(vim.json.decode, result.stdout or "")
		if result.code ~= 0 or not ok or type(made) ~= "table" then
			warn_once("helper", "heading images failed, showing text headings: " .. vim.trim(result.stderr or ""))
			made = {}
		end
		local done = {}
		for _, a in ipairs(made) do
			assets[a.key] = { path = a.path, rows = a.rows, cols = a.cols }
			done[a.request] = true
		end
		for _, request in ipairs(batch) do
			if not done[request.fitKey] then failed[request.fitKey] = true end
		end
		each_state(true)
	end)
end

-- showing the Markdown source on each window's cursor line and across a Visual selection
reveal = function(state)
	local rows = {}
	for _, win in ipairs(fn.win_findbuf(state.buf)) do rows[api.nvim_win_get_cursor(win)[1]] = true end
	if api.nvim_get_current_buf() == state.buf and api.nvim_get_mode().mode:find("^[vV\22]") then
		local a, b = fn.line("v"), fn.line(".")
		for row = math.min(a, b), math.max(a, b) do rows[row] = true end
	end
	for placement, entry in pairs(state.headings) do
		if rows[entry.row + 1] then placement:hide() else placement:show() end
	end
	reflow.reveal(state.buf, rows)
	return rows
end

refresh = function(state)
	if #fn.win_findbuf(state.buf) == 0 then return end
	if images_ok() then refresh_media(state) end
	if state.full then
		state.full = false
		refresh_headings(state)
	end
end

function M.attach(buf)
	if not FILETYPES[vim.bo[buf].filetype] or vim.bo[buf].buftype ~= "" then return end
	states[buf] = states[buf] or { buf = buf, enabled = true, headings = {}, media = {} }
	if states[buf].enabled then schedule(states[buf], true) end
end

-- running after each render-markdown pass, once its icons and hidden brackets are in place to copy
function M.reflow(buf)
	local state = states[buf]
	if not state or not state.enabled then return end
	reflow.update(buf, { keep = reveal(state), width = (text_area(buf)),
		avoid = { [ns] = true, [Snacks.image.placement.ns] = true } })
end

function M.toggle()
	local buf = api.nvim_get_current_buf()
	M.attach(buf)
	local state = states[buf]
	if not state then return end
	state.enabled = not state.enabled
	require("render-markdown").set_buf(state.enabled)
	if state.enabled then schedule(state, true) else close_all(state) end
	api.nvim_echo({ { "Markdown: " .. (state.enabled and "live view" or "source view") } }, false, {})
end

-- rebuilding the helper whenever the Swift source changes, which also renames every cached heading
local function build_helper()
	local file = fn.has("mac") == 1 and io.open(source, "rb")
	if not file then
		helper_status = "unavailable"
		return
	end
	version = fn.sha256(file:read("*a"))
	file:close()
	local stamp = helper .. ".version"
	local current = io.open(stamp, "r")
	local built = current and current:read("*l")
	if current then current:close() end
	if built == version and uv.fs_stat(helper) then
		helper_status = "ready"
		return
	end
	helper_status = "building"
	-- checking for the Command Line Tools first, since the /usr/bin/swiftc stub opens an installer dialog without them
	run({ "xcode-select", "-p" }, {}, function(tools)
		if tools.code ~= 0 then
			helper_status = "unavailable"
			return
		end
		local tmp = ("%s.%d.tmp"):format(helper, uv.os_getpid())
		run({ "swiftc", "-O", source, "-o", tmp }, { timeout = 120000 }, function(result)
			if result.code == 0 and uv.fs_rename(tmp, helper) then
				local out = io.open(stamp, "w")
				if out then out:write(version, "\n"); out:close() end
				helper_status = "ready"
			else
				pcall(uv.fs_unlink, tmp)
				helper_status = "failed"
				warn_once("swiftc", "could not build heading images, showing text headings: " .. vim.trim(result.stderr or ""))
			end
			each_state(true)
		end)
	end)
end

-- making every text heading bold like GitHub, which covers H4 to H6 and H1 to H3 without images
local function bold_headings()
	for level = 1, 6 do
		local name = "@markup.heading." .. level .. ".markdown"
		local hl = api.nvim_get_hl(0, { name = name, link = false })
		if not hl.bold then
			hl.bold = true
			api.nvim_set_hl(0, name, hl)
		end
	end
end

function M.setup()
	fn.mkdir(root, "p")
	build_helper()
	bold_headings()
	local group = api.nvim_create_augroup("MarkdownLive", { clear = true })
	local function on(events, callback) api.nvim_create_autocmd(events, { group = group, callback = callback }) end
	on("ColorScheme", bold_headings)
	on({ "FileType", "BufWinEnter" }, function(ev) M.attach(ev.buf) end)
	on({ "CursorMoved", "CursorMovedI", "ModeChanged" }, function()
		local state = states[api.nvim_get_current_buf()]
		if state and state.enabled then reveal(state) end
	end)
	on({ "TextChanged", "TextChangedI", "InsertLeave" }, function(ev)
		local state = states[ev.buf]
		if state and state.enabled then schedule(state, true) end
	end)
	on("WinScrolled", function() each_state(false) end)
	on({ "WinResized", "VimResized", "TabEnter", "ColorScheme" }, function() each_state(true) end)
	on("BufWipeout", function(ev)
		if states[ev.buf] then close_all(states[ev.buf]); states[ev.buf] = nil end
	end)
	M.attach(api.nvim_get_current_buf())
end

return M
