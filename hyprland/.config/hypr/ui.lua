-- Hyprland BEHAVIOUR. Appearance lives in ui-theme.lua (generated per theme).
--
-- The split exists so switching themes can't silently revert the dwindle-crash
-- workaround, misc/, or debug/ — see themes/README.md.

hl.config({
	general = {
		-- layout = "master", -- master (not dwindle) to avoid CDwindleAlgorithm shutdown crash; see docs/hyprland-plasma-diagnosis.md ISSUE 2
		resize_on_border = true,
		-- allow_tearing = false,
	},
})

hl.config({
	dwindle = {
		preserve_split = true,
	},
})

hl.config({
	master = {
		new_status = "master",
	},
})

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		-- render_unfocused_fps = 60,
	},
})

hl.config({
	debug = {
		vfr = false,
		-- damage_tracking = 0,
	},
})

-- Appearance: gaps, border_size, rounding, opacity, shadow, blur, animations.
-- Installed by scripts/desktop-theme/apply.sh; gitignored (generated output).
require("ui-theme")
