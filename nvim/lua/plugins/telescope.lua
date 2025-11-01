return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})

			-- Load extensions
			require("telescope").load_extension("ui-select")

			-- Keymaps
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<C-p>", builtin.find_files, {
				desc = "Find files"
			})
			vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", {
				desc = "Live grep (search in files)"
			})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {
				desc = "Find buffers"
			})
			vim.keymap.set("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", {
				desc = "Find document symbols"
			})
		end
	},
}
