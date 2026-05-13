local parsers = { "markdown", "markdown_inline", "tsx", "typescript" }

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = function()
		require("nvim-treesitter").install(parsers):wait(300000)
	end,
	opts = {
		ensure_installed = parsers,
	},
	config = function(_, opts)
		vim.treesitter.language.register("tsx", "mdx")

		local treesitter = require("nvim-treesitter")

		treesitter.setup()
		treesitter.install(opts.ensure_installed)

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			pattern = { "markdown", "mdx", "typescript", "typescriptreact" },
			callback = function()
				pcall(vim.treesitter.start)
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
