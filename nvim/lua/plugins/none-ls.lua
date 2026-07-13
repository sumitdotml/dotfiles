return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.stylua,
				require("none-ls.diagnostics.eslint_d"), --js, ts
				require("none-ls.formatting.ruff"),   -- python
				-- require("none-ls.diagnostics.ruff"),  -- python
				null_ls.builtins.formatting.clang_format.with({
					filetypes = { "c", "cpp", "cuda" },
					extra_args = { "--style=file" },
				}),
			},
		})

		vim.keymap.set("n", "<leader>gf", function()
			local bufnr = vim.api.nvim_get_current_buf()
			local has_null_ls = vim.iter(vim.lsp.get_clients({ bufnr = bufnr })):any(function(client)
				return client.name == "null-ls" and client:supports_method("textDocument/formatting")
			end)

			vim.lsp.buf.format({
				bufnr = bufnr,
				filter = has_null_ls and function(client)
					return client.name == "null-ls"
				end or nil,
			})
		end, {})
	end,
}
