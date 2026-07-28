-- Neutral Hyprland look — stock defaults, the blank slate for designing a new theme.
-- Copied to ~/.config/hypr/theme/appearance.lua by scripts/desktop-theme/reset.sh.
--
-- This file owns ONLY appearance. Behaviour (layout, dwindle/master, misc, debug,
-- resize_on_border) stays in modules/behaviour.lua so swapping themes can never
-- revert it. Border COLORS come from noctalia.lua, regenerated per palette.

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 20,
		border_size = 2,
	},

	decoration = {
		rounding = 0,
		rounding_power = 2,

		active_opacity = 1,
		inactive_opacity = 1,
		dim_special = 0.2,
		dim_inactive = false,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
		},

		blur = {
			enabled = true,
			size = 8,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})
