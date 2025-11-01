-- Neovim Autocommands Configuration
-- Organized with autocmd groups for better management

-- ==================== Highlight on Yank ====================
-- Flash/highlight text briefly when yanking (copying)

local highlight_group = vim.api.nvim_create_augroup("highlight-yank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = highlight_group,
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- ==================== MDX Filetype Configuration ====================
-- Override gd (go to definition) with gf (go to file) for MDX files
-- This is useful because LSP definition lookup may not work well with MDX imports

local mdx_group = vim.api.nvim_create_augroup("mdx-config", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	desc = "MDX-specific keymaps (gd -> gf for file navigation)",
	group = mdx_group,
	pattern = "mdx",
	callback = function()
		vim.keymap.set("n", "gd", "gf", {
			buffer = true,
			desc = "Go to file (MDX fallback for gd)"
		})
	end,
})
