return {
	"shortcuts/no-neck-pain.nvim",
	version = "*",
	config = function()
		require("no-neck-pain").setup({
			width = 110,
			fallbackOnBufferDelete = true,
			autocmds = {
				enableOnVimEnter = false,
				reloadOnColorSchemeChange = true,
			},
			buffers = {
				setNames = true,
				bo = {
					filetype = "no-neck-pain",
					buftype = "nofile",
				},
			},
			mappings = {
				enabled = true,
				toggle = "<Leader>z",
			},
		})
	end,
}
