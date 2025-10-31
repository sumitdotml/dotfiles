return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		vim.treesitter.language.register("tsx", "mdx")
		local config = require("nvim-treesitter.configs")
		config.setup({
			ensure_installed = { "markdown", "markdown_inline", "tsx", "typescript" },
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
