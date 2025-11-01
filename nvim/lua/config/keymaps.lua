-- Neovim Global Keymaps Configuration
-- Note: Plugin-specific keymaps are defined in their respective plugin files
-- (e.g., lsp-config.lua, git.lua, telescope.lua, etc.)
--
-- Key notation:
-- <C-...> = Ctrl + ... (e.g. <C-s> = Ctrl + s)
-- <CR> = Enter key
-- <cmd> = Command mode, same as using the colon (e.g. <cmd>q<CR> = :q<CR>)

-- Set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap.set

-- ==================== General Keymaps ====================

keymap("n", "<Leader><Leader>s", "<cmd>source %<CR>", {
	desc = "Source the changes in the neovim config"
})

-- Exit modes with jk
keymap("i", "jk", "<Esc>", {
	desc = "Exit insert mode with 'jk'"
})

keymap("v", "jk", "<Esc>", {
	desc = "Exit visual mode with 'jk'"
})

-- ==================== Visual Mode - Indentation ====================

-- Stay in visual mode after indenting
keymap("v", ">", ">gv", {
	desc = "Indent right and stay in visual mode"
})

keymap("v", "<", "<gv", {
	desc = "Indent left and stay in visual mode"
})

-- ==================== Visual Mode - Moving Text ====================

keymap("v", "J", ":m '>+1<CR>gv=gv", {
	desc = "Move selected text down"
})

keymap("v", "K", ":m '<-2<CR>gv=gv", {
	desc = "Move selected text up"
})

-- ==================== Normal Mode - Text Manipulation ====================

-- Join lines without moving cursor
keymap("n", "J", "mzJ`z", {
	desc = "Join lines without moving the cursor"
})

-- Move to start/end of line
keymap("n", "<leader>s", "^", {
	desc = "Move to the start of the line"
})

keymap("n", "<leader>e", "$", {
	desc = "Move to the end of the line"
})

-- Visual selection to start/end of line
keymap("n", "ve", "v$", {
	desc = "Select from cursor to end of line"
})

keymap("n", "vs", "v^", {
	desc = "Select from cursor to start of line"
})

-- Delete to start/end of line
keymap("n", "<leader>de", "d$", {
	desc = "Delete from cursor to end of line"
})

keymap("n", "<leader>ds", "d0", {
	desc = "Delete from cursor to start of line"
})

-- ==================== Utility ====================

-- Clear search highlight
keymap("n", "<C-l>", ":nohlsearch<CR>", {
	desc = "Clear search highlight"
})

-- Undo in insert mode
keymap("i", "<C-z>", "<C-o>u", {
	desc = "Undo in insert mode"
})

-- ==================== Diagnostic Debugging ====================
-- This keymap helps debug LSP diagnostic issues
-- (e.g., duplicate diagnostics, incorrect configuration)

keymap("n", "<leader>dc", function()
	local config = vim.diagnostic.config()
	print("=== DIAGNOSTIC CONFIG ===")
	print("Virtual text:", vim.inspect(config.virtual_text))
	print("Signs:", config.signs)

	-- Check active LSP clients
	print("\n=== ACTIVE LSP CLIENTS ===")
	local clients = vim.lsp.get_clients()
	for _, client in ipairs(clients) do
		print(string.format("Client: %s (id: %d)", client.name, client.id))
	end

	-- Check what's showing diagnostics
	print("\n=== ACTIVE DIAGNOSTICS ===")
	local diagnostics = vim.diagnostic.get(0)
	print("Count:", #diagnostics)

	-- Try to see where diagnostics are coming from
	print("\n=== NAMESPACES ===")
	local namespaces = vim.diagnostic.get_namespaces()
	for ns_id, ns_data in pairs(namespaces) do
		if ns_data.name then
			local count = #vim.diagnostic.get(0, { namespace = ns_id })
			if count > 0 then
				print(string.format("Namespace %s (%d): %d diagnostics", ns_data.name, ns_id, count))
			end
		end
	end
end, {
	desc = "Debug diagnostic config"
})
