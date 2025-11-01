return {
	"supermaven-inc/supermaven-nvim",
	config = function()
		-- Get theme-aware color from Comment highlight group
		local comment_hl = vim.api.nvim_get_hl(0, { name = "Comment" })
		local suggestion_color = comment_hl.fg and string.format("#%06x", comment_hl.fg) or "#909baa"

		require("supermaven-nvim").setup({
			keymaps = {
				accept_suggestion = "<Tab>",
				clear_suggestion = "<C-]>",
				accept_word = "<C-j>",
			},
			ignore_filetypes = { cpp = true }, -- or { "cpp", }
			color = {
				suggestion_color = suggestion_color, -- Theme-aware color (fallback to #909baa)
				cterm = 244,
			},
			log_level = "info",             -- set to "off" to disable logging completely
			disable_inline_completion = false, -- disables inline completion for use with cmp
			disable_keymaps = false,        -- disables built in keymaps for more manual control
			condition = function()
				-- the condition function is for automatically stopping Supermaven
				-- based on certain conditions (like file types, project types, etc.).
				-- It's different from my manual toggle keymap.
				-- I can leave it as return false (which means "never auto-stop") or
				-- customize it based on my needs.
				return false
			end,
		})
		local api = require("supermaven-nvim.api")
		vim.keymap.set("n", "<leader>cp", function()
			if api.is_running() then
				api.stop()
				vim.notify("Supermaven stopped", vim.log.levels.INFO)
			else
				api.start()
				vim.notify("Supermaven started", vim.log.levels.INFO)
			end
		end, { desc = "Toggle Supermaven" })
	end,
}
