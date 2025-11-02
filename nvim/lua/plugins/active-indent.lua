-- Built on top of lukas-reineke/indent-blankline.nvim; all core credit to the original author.
-- Original repo: https://github.com/lukas-reineke/indent-blankline.nvim
-- I layered in Catppuccin-aware highlight variants, extra Treesitter scope nodes, and
-- refined gradients so braces, tables, functions, and deep indent levels all stay visually
-- tracked. These tweaks reshape ibl for my workflow while keeping upstream behaviour intact.

-- A wrapper around indent-blankline.nvim (ibl) which highlights the active scope,
-- adds Treesitter scope nodes for brace-based blocks, and exposes gradient colour variants
-- for each indent depth. Optionally underline scope edges by setting
-- `vim.g.ibl_catppuccin_scope_edges = true`. Choose a palette with
-- `vim.g.ibl_catppuccin_variant` (available: "sky_pulse" (default), "mauve_mist", "peach_ember").

---@alias HighlightEntry { group: string, palette: string, hex?: string }

local highlight_groups = {
	indent = { "IblIndent", "IblIndentSoft", "IblIndentStrong" },
	whitespace = { "IblWhitespace" },
	scope = { "IblScope" },
}

local highlight_variants = {
	sky_pulse = {
		indent = {
			{ group = "IblIndent", palette = "surface1" }, -- Level 1 guide: surface1 (subtle graphite)
			{ group = "IblIndentSoft", palette = "surface2" }, -- Level 2 guide: surface2 (soft blend)
			{ group = "IblIndentStrong", palette = "overlay0" }, -- Level 3+ guide: overlay0 (extra contrast)
		},
		whitespace = {
			{ group = "IblWhitespace", palette = "surface0" }, -- Blankline filler: surface0 (dim)
		},
		scope = {
			column = { group = "IblScope", palette = "sky" }, -- Active scope column: sky (cool blue)
			edges = { palette = "sapphire" }, -- Optional scope edge underline: sapphire
		},
	},
	mauve_mist = {
		indent = {
			{ group = "IblIndent", palette = "surface1" }, -- Level 1 guide: surface1 (balanced neutral)
			{ group = "IblIndentSoft", palette = "surface2" }, -- Level 2 guide: surface2 (soft grey)
			{ group = "IblIndentStrong", palette = "overlay0" }, -- Level 3+ guide: overlay0 (gentle contrast)
		},
		whitespace = {
			{ group = "IblWhitespace", palette = "surface0" }, -- Blankline filler: surface0 (dim)
		},
		scope = {
			column = { group = "IblScope", palette = "mauve" }, -- Active scope column: mauve (primary violet)
			edges = { palette = "pink" }, -- Optional scope edge underline: pink
		},
	},
	peach_ember = {
		indent = {
			{ group = "IblIndent", palette = "surface1" }, -- Level 1 guide: surface1 (neutral)
			{ group = "IblIndentSoft", palette = "surface2" }, -- Level 2 guide: surface2 (soft blend)
			{ group = "IblIndentStrong", palette = "overlay0" }, -- Level 3+ guide: overlay0 (extra contrast)
		},
		whitespace = {
			{ group = "IblWhitespace", palette = "surface0" }, -- Blankline filler: surface0 (dim)
		},
		scope = {
			column = { group = "IblScope", palette = "peach" }, -- Active scope column: peach (warm accent)
			edges = { palette = "maroon" }, -- Optional scope edge underline: maroon
		},
	},
}

local function resolve_variant()
	local variant_name = vim.g.ibl_catppuccin_variant or "mauve_mist"
	return highlight_variants[variant_name] or highlight_variants.mauve_mist
end

local function resolve_flags()
	local show_edges = vim.g.ibl_catppuccin_scope_edges
	return {
		show_scope_edges = show_edges ~= nil and show_edges or false,
	}
end

local function apply_highlights(palette, variant, flags)
	local function set_group(entry)
		local colour = entry.hex or (palette and palette[entry.palette])
		if not colour then
			return
		end
		vim.api.nvim_set_hl(0, entry.group, { fg = colour })
	end

	for _, entry in ipairs(variant.indent) do
		set_group(entry)
	end
	for _, entry in ipairs(variant.whitespace) do
		set_group(entry)
	end

	if variant.scope and variant.scope.column then
		set_group(variant.scope.column)
	end

	if
		flags.show_scope_edges
		and variant.scope
		and variant.scope.edges
		and (variant.scope.edges.palette or variant.scope.edges.hex)
	then
		local colour = variant.scope.edges.hex or (palette and palette[variant.scope.edges.palette])
		if colour then
			vim.schedule(function()
				vim.api.nvim_set_hl(0, "@ibl.scope.underline.1", { sp = colour, underline = true })
			end)
		end
	end
end

local indent_highlights = highlight_groups.indent
local whitespace_highlights = highlight_groups.whitespace
local scope_highlights = highlight_groups.scope

return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	opts = function()
		local hooks = require("ibl.hooks")
		local variant = resolve_variant()
		local flags = resolve_flags()

		hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
			local ok, palette = pcall(function()
				local flavour = vim.g.catppuccin_flavour or "mocha"
				return require("catppuccin.palettes").get_palette(flavour)
			end)
			if not ok then
				return
			end

			apply_highlights(palette, variant, flags)
		end)

		local scope_node_types = {
			["*"] = {
				"object",
				"object_pattern",
				"object_expression",
				"initializer_list",
				"literal_value",
				"field_initializer_list",
				"class_body",
				"enum_body",
				"table_constructor",
				"dictionary",
				"dictionary_comprehension",
				"dictionary_expression",
			},
			javascript = { "object", "object_pattern", "class_body" },
			typescript = { "object", "object_pattern", "class_body", "interface_body" },
			typescriptreact = { "object", "object_pattern", "class_body", "interface_body" },
			javascriptreact = { "object", "object_pattern", "class_body" },
			json = { "object" },
			jsonc = { "object" },
			lua = { "table_constructor" },
			go = { "literal_value", "composite_literal" },
			rust = { "field_declaration_list", "struct_expression", "block" },
			c = { "initializer_list", "compound_statement" },
			cpp = { "initializer_list", "compound_statement" },
			java = { "class_body", "constructor_body", "enum_body" },
		}

		return {
			indent = {
				char = "│",
				tab_char = "│",
				highlight = indent_highlights,
			},
			whitespace = {
				highlight = whitespace_highlights,
				remove_blankline_trail = false,
			},
			scope = {
				enabled = true,
				show_start = flags.show_scope_edges, -- underline opening delimiter when enabled
				show_end = flags.show_scope_edges, -- underline closing delimiter when enabled
				highlight = scope_highlights,
				include = {
					node_type = scope_node_types,
				},
			},
		}
	end,
}
