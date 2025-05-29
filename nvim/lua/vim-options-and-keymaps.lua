--vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " " -- <space> is my leader key

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

-- staying in indent mode
keymap("v", ">", ">gv", { desc = "Indent right and stay in visual mode" })
keymap("v", "<", "<gv", { desc = "Indent left and stay in visual mode" })

-- moving text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected text down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected text up" })

-- join lines (this moves the line that is just below the cursor to the line above)
keymap("n", "J", "mzJ`z", { desc = "Join lines without moving the cursor" })

-- moving to the start and end of the line
keymap("n", "H", "^", { desc = "Move to the start of the line" })
keymap("n", "L", "$", { desc = "Move to the end of the line" })

-- visual mode from the current position to the end of the line
keymap("n", "VL", "v$", { desc = "Select from the current position to the end of the line" })

-- visual mode from the current position to the start of the line
keymap("n", "VH", "v^", { desc = "Select from the current position to the start of the line" })

-- visual mode for the exact word under the cursor
keymap("n", "VW", "viw", { desc = "Select the word under the cursor" })

-- moving in insert mode without using the arrow keys
keymap("i", "<C-h>", "<Left>", { desc = "Move left in insert mode" })
keymap("i", "<C-l>", "<Right>", { desc = "Move right in insert mode" })
keymap("i", "<C-j>", "<Down>", { desc = "Move down in insert mode" })
keymap("i", "<C-k>", "<Up>", { desc = "Move up in insert mode" })
keymap("i", "<C-a>", "<Home>", { desc = "Move to the start of the line in insert mode" })
keymap("i", "<C-e>", "<End>", { desc = "Move to the end of the line in insert mode" })

-- Moving between words in insert mode
keymap("i", "<C-b>", "<C-o>b", { desc = "Move to the start of the word in insert mode" })
keymap("i", "<C-w>", "<C-o>w", { desc = "Move to the end of the word in insert mode" })

-- Deleting words in insert mode
keymap("i", "<C-d>", "<C-o>dw", { desc = "Delete the word under the cursor in insert mode" })
keymap("i", "<C-h>", "<C-o>db", { desc = "Delete the word before the cursor in insert mode" })
-- Deleting the whole line in insert mode
keymap("i", "<C-u>", "<C-o>dd", { desc = "Delete the whole line in insert mode" })

-- Clear the search highlight
keymap("n", "<C-l>", ":nohlsearch<CR>", { desc = "Clear search highlight" })
