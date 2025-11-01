return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				globalstatus = true,
				refresh = {
					statusline = 100,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff" },
				lualine_c = { "filename" },
				lualine_x = { "progress" },
				lualine_y = { "os.date('%a %b %d %H:%M')" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {},
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			winbar = {
				lualine_a = {},
				lualine_b = {
					{
						"filename",
						path = 1,
					},
				},
				lualine_c = {},
				lualine_x = { "searchcount", "encoding", "diagnostics" },
				lualine_y = { "filetype" },
				lualine_z = {},
			},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
