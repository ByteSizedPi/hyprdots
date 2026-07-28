-- liquidglass — Hyprland appearance.
--
-- Tuned for hyprglass. The important bit: WINDOWS MUST BE TRANSLUCENT. hyprglass
-- draws the glass slab *behind* the window surface, so at opacity 1.0 the window
-- covers it completely and you see nothing — the single most common "glass isn't
-- working" cause. That's why active/inactive_opacity are below 1 here.
--
-- Owns ONLY appearance. Behaviour (layout, dwindle/master, misc, debug,
-- resize_on_border) lives in modules/behaviour.lua so swapping themes can't revert it.
-- Layer rules live in theme/layers.lua; border COLORS come from noctalia.lua.

hl.config({
	general = {
		-- Wider gaps than the flat themes: glass edges are the effect, and touching
		-- windows hide them.
		gaps_in = 2,
		gaps_out = 4,
		border_size = 2,
	},

	decoration = {
		-- Generous radius — refraction reads best on a curve.
		rounding = 14,
		rounding_power = 2,

		-- REQUIRED for glass to be visible at all. Raise toward 1.0 and the effect
		-- disappears; drop too far and text gets hard to read.
		active_opacity = 0.88,
		inactive_opacity = 0.80,
		dim_special = 0,
		dim_inactive = false,

		-- hyprglass force-enables shadows regardless (only their presence matters to
		-- it, not the values). Set explicitly so the config doesn't lie about state.
		shadow = {
			enabled = false,
			range = 12,
			render_power = 3,
			color = 0x66000000,
		},

		-- Applies to layers glass doesn't own (screen corners). Glassed windows get
		-- `noblur` set automatically, so these values don't reach them.
		blur = {
			enabled = false,
			size = 8,
			passes = 3,
			special = false,
			xray = true,
			vibrancy = 0.17,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "quick" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "quick", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "quick", style = "popin 80%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
