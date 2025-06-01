return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
			"williamboman/mason.nvim",
		},
		lazy = false,
		config = function()
			-- =========================== MANUALLY ENABLED VIRTUAL TEXT DIAGNOSTICS ===========================
			-- I've had to do this manually because neovim's v0.11.0+ does not have this turned on by default.
			-- also, I've had to remove mason-lspconfig because it was causing duplicate diagnostics (and that
			-- it would be redundant as well due to this new neovim update)
			vim.diagnostic.config({
				virtual_text = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.HINT] = "",
						[vim.diagnostic.severity.INFO] = "",
					},
				},
				underline = true,
				update_in_insert = false,
			})
			-- =========================== MANUALLY ENABLED VIRTUAL TEXT DIAGNOSTICS END ===========================

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local lspconfig = require("lspconfig")

			-- lsp config for all the servers
			lspconfig.lua_ls.setup({ capabilities = capabilities })
			lspconfig.ts_ls.setup({ capabilities = capabilities })
			lspconfig.pylsp.setup({ capabilities = capabilities })
			lspconfig.mdx_analyzer.setup({ capabilities = capabilities })
			lspconfig.marksman.setup({ capabilities = capabilities })
			lspconfig.clangd.setup({ capabilities = capabilities })
			lspconfig.vimls.setup({ capabilities = capabilities })
			lspconfig.astro.setup({ capabilities = capabilities })
			lspconfig.zls.setup({ capabilities = capabilities })

			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gr", vim.lsp.buf.references, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
