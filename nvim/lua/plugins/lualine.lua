return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				-- component_separators = { left = "", right = "" },
				-- section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				-- always_show_tabline = true,
				globalstatus = true,
				refresh = {
					statusline = 100,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff" }, --'diagnostics'},
				lualine_c = { "filename" },
				-- lualine_x = { "encoding", "fileformat", "filetype" },
				--lualine_y = {'progress'},
				lualine_x = { "progress" },
				lualine_y = { "os.date('%a %b %d %H:%M')" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {}, --{'filename'},
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
