return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		-- for revealing the floating Neotree
		vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal float<CR>', {})
	end
}
