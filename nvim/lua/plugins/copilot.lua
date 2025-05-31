-- for this, you need github copilot. it's free if you're wondering.
-- details: https://github.com/github/copilot.vim

return {
	"github/copilot.vim",
	lazy = false,
	enabled = true,
	-- enable or diable copilot with keymap
	vim.keymap.set("n", "<leader>cp", function()
		if vim.g.copilot_enabled then
			vim.g.copilot_enabled = false
			vim.notify("Copilot disabled")
		else
			vim.g.copilot_enabled = true
			vim.notify("Copilot enabled")
		end
	end, { desc = "Toggle Copilot" })
}
