return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		opts = {
			auto_install = true,
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp" },
		lazy = false,
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local lspconfig = require("lspconfig")
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			}) -- lua

			lspconfig.ts_ls.setup({
				capabilities = capabilities,
			}) -- js, ts

			lspconfig.pylsp.setup({
				capabilities = capabilities,
			}) -- python

			lspconfig.mdx_analyzer.setup({
				capabilities = capabilities,
			}) -- mdx

			lspconfig.marksman.setup({
				capabilities = capabilities,
			}) -- markdown

			lspconfig.clangd.setup({
				capabilities = capabilities,
			}) -- c++

			lspconfig.vimls.setup({
				capabilities = capabilities,
			}) -- vim

			lspconfig.astro.setup({
				capabilities = capabilities,
			}) -- astro

			lspconfig.zls.setup({
				capabilities = capabilities,
			}) -- zig
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gr", vim.lsp.buf.references, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
