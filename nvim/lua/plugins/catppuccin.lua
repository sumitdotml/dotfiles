return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000, -- load before anything that needs colours
	lazy = false, -- colourscheme should be available immediately

	opts = function()
		require("catppuccin").setup({
			flavour = "mocha", -- or "latte" | "frappe" | "macchiato"
			transparent_background = false,

			custom_highlights = function(c)
				return {
					-- relative numbers
					LineNrAbove = { fg = c.overlay0},
					LineNrBelow = { fg = c.overlay0 },

					-- absolute number on current line
					CursorLineNr = {
						-- available colors: rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender
						fg = c.mauve,
						-- style = { "bold" }
					},

					-- fallback (rarely used if the two groups above exist)
					LineNr = { fg = c.surface1 },
				}
			end,
		})

		-- finally apply the scheme
		vim.cmd.colorscheme("catppuccin-mocha")
	end,
}
