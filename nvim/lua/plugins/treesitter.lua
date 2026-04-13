return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	opts = {
		ensure_installed = { "markdown", "markdown_inline", "tsx", "typescript" },
		auto_install = true,
	},
	config = function(_, opts)
		vim.treesitter.language.register("tsx", "mdx")
		require("nvim-treesitter").setup(opts)
	end,
}
