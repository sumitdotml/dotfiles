return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
		{
			"folke/snacks.nvim",
			commit = "882c996cf28183f4d63640de0b4c02ec886d01f2",
			init = function()
				if vim.env.TERM_PROGRAM == "rex" then vim.env.SNACKS_KITTY = "1" end
			end,
			opts = { image = { enabled = true, doc = { enabled = false, inline = true, float = false } } },
		},
	},
	ft = { "markdown", "mdx" },
	keys = {
		{ "<leader>mr", function() require("modules.markdown-live").toggle() end, desc = "Toggle Markdown live/source view" },
	},
	config = function()
		require("render-markdown").setup({
			enabled = true,
			file_types = { "markdown", "mdx" },
			render_modes = { "n", "c", "i", "v", "V", "\22" },
			heading = { enabled = false },
			sign = { enabled = false },
			bullet = { icons = { "•", "◦" } },
			code = { width = "block", left_pad = 1, right_pad = 1 },
			-- re-wrapping lines whose hidden link URLs would otherwise still take up room
			on = {
				render = function(ctx) require("modules.markdown-live").reflow(ctx.buf) end,
				clear = function(ctx) require("modules.markdown-reflow").clear(ctx.buf) end,
			},
			win_options = {
				colorcolumn = { default = "100", rendered = "" },
				number = { default = vim.o.number, rendered = false },
				relativenumber = { default = vim.o.relativenumber, rendered = false },
				cursorline = { default = vim.o.cursorline, rendered = false },
				-- reserving the sign column so the first git sign does not shift the text right
				signcolumn = { default = vim.o.signcolumn, rendered = "yes" },
			},
		})

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("MarkdownLiveStyle", { clear = true }),
			pattern = { "markdown", "mdx" },
			callback = function(ev)
				vim.opt_local.linebreak = true
				local ok, ibl = pcall(require, "ibl")
				if ok then ibl.setup_buffer(ev.buf, { enabled = false }) end
			end,
		})
		require("modules.markdown-live").setup()
	end,
}
