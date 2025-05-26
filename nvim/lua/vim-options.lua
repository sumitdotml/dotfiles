--vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
-- vim.wo.number = true -- for absolute line numbering
-- vim.wo.relativenumber = true -- for relative line numbering

-- when both of the two below are true, it becomes a “hybrid” line numbering – showing
-- relative numbers on all lines except the current line, which shows the absolute line number
vim.opt.number = true         -- show absolute line number
vim.opt.relativenumber = true -- show relative numbers

-- show a thin highlight on the line number ONLY
vim.opt.cursorline      = true
vim.opt.cursorlineopt   = 'number'   -- don't highlight the whole line, just the nr

-- some keymaps
vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")

-- highlighting while yanking
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})
