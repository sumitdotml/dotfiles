local bootstrap_parsers = {
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
	"ini",
	"java",
	"javascript",
	"jinja",
	"jsdoc",
	"json",
	"json5",
	"jsonnet",
	"just",
	"kotlin",
	"latex",
	"lua",
	"luadoc",
	"make",
	"markdown",
	"markdown_inline",
	"mermaid",
	"nix",
	"php",
	"prisma",
	"python",
	"query",
	"regex",
	"ruby",
	"rust",
	"scss",
	"sql",
	"svelte",
	"terraform",
	"tmux",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"vue",
	"xml",
	"yaml",
}

local installing = {}
local available_parsers

local function contains(values, value)
	return vim.tbl_contains(values, value)
end

local function parser_available(treesitter, parser)
	available_parsers = available_parsers or treesitter.get_available()
	return contains(available_parsers, parser)
end

local function parser_for_buffer(bufnr)
	local filetype = vim.bo[bufnr].filetype
	if filetype == "" then
		return nil
	end

	return vim.treesitter.language.get_lang(filetype) or filetype
end

local function ensure_parser(treesitter, bufnr)
	local parser = parser_for_buffer(bufnr)
	if not parser then
		return
	end

	if contains(treesitter.get_installed("parsers"), parser) or installing[parser] then
		return
	end

	if not parser_available(treesitter, parser) then
		return
	end

	installing[parser] = true
	local ok = pcall(treesitter.install, parser)
	if not ok then
		installing[parser] = nil
		return
	end

	vim.defer_fn(function()
		installing[parser] = nil
		if vim.api.nvim_buf_is_valid(bufnr) then
			pcall(vim.treesitter.start, bufnr)
		end
	end, 3000)
end

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = function()
		require("nvim-treesitter").install(bootstrap_parsers):wait(300000)
	end,
	config = function()
		vim.treesitter.language.register("tsx", "mdx")

		local treesitter = require("nvim-treesitter")

		treesitter.setup()

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			callback = function(args)
				ensure_parser(treesitter, args.buf)
				pcall(vim.treesitter.start, args.buf)
				pcall(function()
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end)
			end,
		})
	end,
}
