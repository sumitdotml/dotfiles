-- Indentation settings
vim.opt.tabstop = 2       -- Number of spaces a tab counts for
vim.opt.softtabstop = 2   -- Number of spaces for tab in insert mode
vim.opt.shiftwidth = 2    -- Number of spaces for auto-indent
vim.opt.expandtab = true  -- Convert tabs to spaces (default, kept explicit)

-- File path search configuration
vim.opt.path:append("**") -- Search recursively in current directory and subdirectories

-- File type suffix additions for gf (go to file) command
vim.opt.suffixesadd:append({ ".astro", ".tsx", ".ts", ".jsx", ".js", ".mdx" })

-- MDX filetype configuration
vim.filetype.add({
	extension = {
		mdx = "mdx",
	},
})

-- Line numbering (hybrid mode)
-- Shows relative numbers on all lines except the current line,
-- which shows the absolute line number
vim.opt.number = true         -- Show absolute line number on current line
vim.opt.relativenumber = true -- Show relative numbers on other lines

-- Cursor line highlighting
vim.opt.cursorline = true       -- Enable cursor line highlighting
vim.opt.cursorlineopt = "number" -- Highlight only the line number, not the whole line
