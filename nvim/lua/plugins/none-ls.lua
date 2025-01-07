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
				null_ls.builtins.formatting.black, -- python
				null_ls.builtins.formatting.isort, -- python
			},
		})

		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
	end,
}
