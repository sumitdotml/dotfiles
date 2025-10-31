return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	ft = { "markdown", "mdx" },
	config = function()
		require("render-markdown").setup({
			enabled = true,
			file_types = { "markdown", "mdx" },
			render_modes = { "n", "c", "i" },
			heading = {
				enabled = true,
			},
			code = {
				enabled = true,
			},
			bullet = {
				enabled = true,
			},
		})

		-- Force enable on FileType
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "markdown", "mdx" },
			callback = function()
				require("render-markdown").enable()

				-- Set keymaps only in markdown/mdx buffers
				vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", {
					buffer = true,
					desc = "Toggle Markdown Rendering",
				})
			end,
		})
	end,
}
