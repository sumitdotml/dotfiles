--vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " " -- <space> is my leader key
local opts = { noremap = true, silent = true }

-- =========================== VIM OPTIONS ===========================
-- vim.wo.number = true -- for absolute line numbering
-- vim.wo.relativenumber = true -- for relative line numbering

-- when both of the two below are true, it becomes a “hybrid” line numbering – showing
-- relative numbers on all lines except the current line, which shows the absolute line number
vim.opt.number = true         -- show absolute line number
vim.opt.relativenumber = true -- show relative numbers

-- show a thin highlight on the line number ONLY
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number" -- don't highlight the whole line, just the nr

-- highlighting while yanking
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- =========================== GLOBAL KEYMAPS ===========================
-- Note: there are individual keymaps that have been set in the plugins
-- as well, such as in the lsp-config.lua and git.lua files.
-- This file is for global keymaps that are not specific to any plugin.
--
-- Keys:
-- <C-...> = Ctrl + ... (e.g. <C-s> = Ctrl + s)
-- <CR> = Enter key
-- <cmd> = Command mode, same as using the colon (e.g. <cmd>q<CR> = :q<CR>)

local keymap = vim.keymap.set

keymap("n", "<Leader><Leader>s", "<cmd>source %<CR>", { desc = "Source the changes in the neovim config" })
keymap("i", "jk", "<Esc>", { desc = "Exit insert mode with 'jk'" })
keymap("v", "jk", "<Esc>", { desc = "Exit view mode with 'jk'" })

-- staying in indent mode
keymap("v", ">", ">gv", { desc = "Indent right and stay in visual mode" })
keymap("v", "<", "<gv", { desc = "Indent left and stay in visual mode" })

-- moving text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected text down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected text up" })

-- join lines (this moves the line that is just below the cursor to the line above)
keymap("n", "J", "mzJ`z", { desc = "Join lines without moving the cursor" })

-- moving to the start and end of the line
keymap("n", "<leader>s", "^", opts, { desc = "Move to the start of the line" })
keymap("n", "<leader>e", "$", opts, { desc = "Move to the end of the line" })

-- visual mode from the current position to the end of the line
keymap("n", "ve", "v$", { desc = "Select from the current position to the end of the line" })

-- visual mode from the current position to the start of the line
keymap("n", "vs", "v^", { desc = "Select from the current position to the start of the line" })

-- Clear the search highlight
keymap("n", "<C-l>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Doing undo in insert mode
keymap("i", "<C-z>", "<C-o>u", { desc = "Undo in insert mode" })

-- =================== DIAGNOSTIC DEBUGGING ONLY (you can remove this if you want) ====================
-- I did this mainly because I had issues with the floating diagnostics appearing twice ever since I updated to
-- neovim v0.11.0, but it's been fixed (just had to remove mason-lspconfig)
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
end, { desc = "Debug diagnostic config" })
