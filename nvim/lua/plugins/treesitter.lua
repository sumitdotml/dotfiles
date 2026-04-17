return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	build = ":TSUpdate",
	opts = {
		ensure_installed = { "markdown", "markdown_inline", "tsx", "typescript" },
		auto_install = true,
		highlight = { enable = true },
		indent = { enable = true },
	},
	config = function(_, opts)
		vim.treesitter.language.register("tsx", "mdx")
		require("nvim-treesitter.configs").setup(opts)
	end,
}
