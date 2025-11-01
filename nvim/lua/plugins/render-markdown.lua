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
		local render_md_group = vim.api.nvim_create_augroup("render-markdown-setup", { clear = true })

		vim.api.nvim_create_autocmd("FileType", {
			desc = "Enable render-markdown for markdown/mdx files",
			group = render_md_group,
			pattern = { "markdown", "mdx" },
			callback = function()
				require("render-markdown").enable()

				-- Set keymaps only in markdown/mdx buffers
				vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", {
					buffer = true,
					desc = "Toggle markdown rendering",
				})
			end,
		})
	end,
}
