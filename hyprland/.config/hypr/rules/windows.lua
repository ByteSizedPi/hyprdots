-- Window rules that hold regardless of theme.
--
-- Layer rules are NOT here — see theme/layers.lua. Whether a noctalia surface gets
-- Hyprland's blur depends on whether the active theme hands that surface to
-- hyprglass, so those rules belong to the theme.
-- Scratchpad workspace rules live in modules/scratchpads.lua.

hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Semi-transparent Noctalia Settings window
hl.window_rule({
	name = "noctalia-settings-opacity",
	match = { class = "^dev\\.noctalia\\.Noctalia\\.Settings$" },
	opacity = "0.8 override 0.8 override",
})
