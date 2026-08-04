-- Hyprland appearance — GENERATED, do not edit by hand for keeps.
-- Installed by scripts/desktop-theme/apply.sh from themes/<name>/hypr/appearance.lua.
-- Edit freely while designing a look, then bank it: scripts/desktop-theme/save.sh <name>
--
-- Owns ONLY appearance. Behaviour (layout, dwindle/master, misc, debug,
-- resize_on_border) lives in modules/behaviour.lua so swapping themes can't revert it.
-- Layer rules live in theme/layers.lua; border COLORS come from noctalia.lua.

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 4,
		border_size = 2,
	},

	decoration = {
		rounding = 0,
		rounding_power = 2,

		active_opacity = 1,
		inactive_opacity = 1,
		dim_special = 0,
		dim_inactive = false,

		shadow = {
			enabled = false,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a,
		},

		-- blur = {
		-- 	size = 10,
		-- 	passes = 3,
		-- 	special = true,
		-- 	xray = true,
		-- 	vibrancy = 9,
		-- },
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
-- Windows appear, close, and reflow with no animation. `windows` is the parent
-- of windowsIn/windowsOut/windowsMove, but each child is set explicitly as well:
-- `hyprctl animations` reports a non-overridden child as enabled, so relying on
-- inheritance alone makes the state hard to read back.
-- `fade` is off for the same goal: a window that pops in but still fades is not
-- instant. Its layer children (fadeLayersIn/Out) are re-enabled below.
hl.animation({ leaf = "windows", enabled = false })
hl.animation({ leaf = "windowsIn", enabled = false })
hl.animation({ leaf = "windowsOut", enabled = false })
hl.animation({ leaf = "windowsMove", enabled = false })
hl.animation({ leaf = "fadeIn", enabled = false })
hl.animation({ leaf = "fadeOut", enabled = false })
hl.animation({ leaf = "fade", enabled = false })
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
