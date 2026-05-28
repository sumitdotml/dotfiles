local parsers = {
	"astro",
	"bash",
	"c",
	"cmake",
	"comment",
	"cpp",
	"css",
	"csv",
	"cuda",
	"diff",
	"dockerfile",
	"editorconfig",
	"git_config",
	"git_rebase",
	"gitattributes",
	"gitcommit",
	"gitignore",
	"go",
	"gomod",
	"gosum",
	"gowork",
	"graphql",
	"html",
	"java",
	"javascript",
	"jsdoc",
	"json",
	"jsonc",
	"lua",
	"luadoc",
	"make",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"regex",
	"rust",
	"sql",
	"tmux",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"xml",
	"yaml",
}

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
			callback = function()
				pcall(vim.treesitter.start)
				pcall(function()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end)
			end,
		})
	end,
}
