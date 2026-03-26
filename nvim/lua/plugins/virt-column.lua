return {
	"lukas-reineke/virt-column.nvim",
	config = function()
		vim.api.nvim_set_hl(0, "VirtColumnLine", { fg = "#313244" })
		require("virt-column").setup({
			char = "▐",
			highlight = "VirtColumnLine",
		})
	end,
}
