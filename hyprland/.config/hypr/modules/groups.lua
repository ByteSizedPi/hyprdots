-- Window groups (tabs): grouped-window borders and the groupbar (tab bar).
--
-- Loaded from hyprland.lua AFTER require("noctalia").apply_theme(), because
-- apply_theme() sets group.col.* and group.groupbar.col.* and would overwrite
-- anything set earlier. Colours come from the Noctalia palette, so they still
-- follow theme changes.
--
-- Choices (2026-10-07):
--   * Grouped windows get the SAME border as normal windows (primary for both
--     active and inactive, as noctalia.lua sets col.active_border and
--     col.inactive_border). Noctalia's default made them secondary (lavender).
--   * The active tab is filled with primary, the same pink as window borders.
--   * Square tabs (rounding 0) to match the square windows (decoration.rounding 0).
--   * Bigger labels. The defaults (font_size 8, height 14) were unreadable.
--   * gradients = true fills each tab. Without the fill, the dark active-tab text
--     was unreadable on the window behind it.
--   * indicator_height = 0: the thin line under each tab duplicated the fill.
--   * Spacing matches the window spacing. Two tiled windows sit 4 px apart
--     (general.gaps_in 2 on each), so the gap between tabs (gaps_in) and the gap
--     between the bar and the window below (gaps_out) are both 4.
--   * keep_upper_gap = false. The default (true) adds another gaps_out ABOVE the
--     bar, on top of general.gaps_out. Measured: 8 px between the Noctalia bar
--     and the tab bar, against 4 px below it. With false, both gaps are 4 px.
-- The groupbar has no option for a border (outline) around a tab.

local c = require("noctalia").colors

hl.config({
	group = {
		col = {
			border_active = c.primary,
			border_inactive = c.primary,
		},
		groupbar = {
			font_size = 15,
			height = 26,
			font_weight_active = "bold",
			gradients = true,
			rounding = 0,
			gradient_rounding = 0,
			indicator_height = 0,
			gaps_in = 4,
			gaps_out = 4,
			keep_upper_gap = false,
			col = {
				active = c.primary,
				inactive = c.surface,
			},
			text_color = c.surface,
			text_color_inactive = c.on_surface,
		},
	},
})
