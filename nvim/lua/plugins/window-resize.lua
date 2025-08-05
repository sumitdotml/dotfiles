return {
	"anuvyklack/hydra.nvim",
	config = function()
		local Hydra = require("hydra")

		Hydra({
			name = "Window Resize",
			mode = "n",
			body = "<leader>r",
			heads = {
				{ "<Left>", "<C-w><" },
				{ "<Right>", "<C-w>>" },
				{ "<Up>", "<C-w>-" },
				{ "<Down>", "<C-w>+" },
				{ "q", nil, { exit = true } },
				{ "<Esc>", nil, { exit = true } },
			},
			config = {
				timeout = 2000,
				hint = {
					type = "window",
					position = "bottom",
					border = "rounded",
				},
			},
		})
	end,
}
