return {
	"shortcuts/no-neck-pain.nvim",
	version = "*",
	priority = 100,
	config = function()
		require("no-neck-pain").setup({
		width = 120,
		fallbackOnBufferDelete = true,
		autocmds = {
			enableOnVimEnter = true,
			reloadOnColorSchemeChange = true,
		},
	})
	end
}
