return {
	"rose-pine/neovim",
	name = "rose-pine",
	priority = 1000,
	config = function()
		require("rose-pine").setup({
			variant = "main", -- auto, main, moon, or dawn
			dark_variant = "main", -- main, moon, or dawn
			dim_inactive_windows = false,
			extend_background_behind_borders = false,

			enable = {
				terminal = true,
			},

			styles = {
				bold = true,
				italic = true,
				transparency = false,
			},

			groups = {
				border = "muted",
				link = "iris",
				panel = "surface",

				error = "love",
				hint = "iris",
				info = "foam",
				note = "pine",
				todo = "rose",
				warn = "gold",

				git_add = "foam",
				git_change = "rose",
				git_delete = "love",
				git_dirty = "rose",
				git_ignore = "muted",
				git_merge = "iris",
				git_rename = "pine",
				git_stage = "iris",
				git_text = "rose",
				git_untracked = "subtle",

				h1 = "iris",
				h2 = "foam",
				h3 = "rose",
				h4 = "gold",
				h5 = "pine",
				h6 = "foam",
			},

			palette = {
				main = {
					base = "#12121a",
					surface = "#12121a",
					overlay = "#1a1a24",
				},
			},

			-- NOTE: Highlight groups are extended (merged) by default. Disable this
			-- per group via `inherit = false`
			highlight_groups = {
				TelescopeSelection = { bg = "iris", fg = "base" },
				TelescopeSelectionCaret = { bg = "iris", fg = "base" },
				IblIndent = { fg = "#4d4d4d" },
				IblScope = { fg = "#a3a3a3" },
				-- Floating window styling
				NormalFloat = { bg = "overlay" },
				FloatBorder = { fg = "subtle", bg = "overlay" },
				FloatTitle = { fg = "text", bg = "overlay" },
				-- Completion menu
				Pmenu = { bg = "overlay" },
				PmenuSel = { bg = "iris", fg = "base" },
				PmenuSbar = { bg = "surface" },
				PmenuThumb = { bg = "muted" },
				-- Cmp specific
				CmpItemAbbrMatch = { fg = "iris", bold = true },
				CmpItemAbbrMatchFuzzy = { fg = "iris", bold = true },
				-- General
				Directory = { fg = "iris" },
			},

			before_highlight = function(group, highlight, palette)
				-- Disable all undercurls
				-- if highlight.undercurl then
				--     highlight.undercurl = false
				-- end
				--
				-- Change palette colour
				-- if highlight.fg == palette.pine then
				--     highlight.fg = palette.foam
				-- end
			end,
		})

		vim.cmd.colorscheme("rose-pine-main")
	end,
}
