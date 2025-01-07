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
		}
		-- config = function()
			-- require("mason-lspconfig").setup({
				-- ensure_installed = { "lua_ls", "ts_ls", "pylsp", "mdx_analyzer"}
			-- })
		-- end
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = require('cmp_nvim_lsp').default_capabilities()
			local lspconfig = require("lspconfig")
			lspconfig.lua_ls.setup({
				capabilities = capabilities
			}) -- lua

			lspconfig.ts_ls.setup({
				capabilities = capabilities
			}) -- js, ts

			lspconfig.pylsp.setup({
				capabilities = capabilities
			}) -- python

			lspconfig.mdx_analyzer.setup({
				capabilities = capabilities
			}) -- mdx

			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gr", vim.lsp.buf.references, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		end
	}
}
