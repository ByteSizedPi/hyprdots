-- Hyprland BEHAVIOUR — what the compositor DOES. Appearance lives in
-- theme/appearance.lua, generated per theme.
--
-- The split exists so switching themes can't silently revert the dwindle-crash
-- workaround, misc/, or debug/ — see themes/README.md.

hl.config({
	general = {
		-- Scrolling on every workspace (chosen 2026-10-07 after a trial on workspace 3).
		-- Per-workspace exceptions live in modules/layouts.lua. This also moves off
		-- dwindle, which had the CDwindleAlgorithm shutdown crash; see
		-- docs/hyprland-plasma-diagnosis.md ISSUE 2.
		layout = "scrolling",
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
