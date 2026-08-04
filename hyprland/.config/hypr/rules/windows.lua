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

-- The Noctalia Settings opacity rule USED TO LIVE HERE. It moved to the theme on
-- 2026-08-03, for two reasons:
--
-- 1. It was DEAD. It matched `^dev\.noctalia\.Noctalia\.Settings$`, and `hyprctl
--    clients` reports the class as `dev.noctalia.Noctalia` — Noctalia dropped the
--    `.Settings` suffix. Hyprland does not warn about a window rule that matches
--    nothing, so it just quietly stopped applying.
-- 2. It does not belong in a theme-independent file. Window alpha is what hyprglass
--    draws behind, so whether that window should be translucent is a property of
--    the LOOK, not of the machine — comicmono and paper_bw have no glass to reveal
--    and a see-through Settings window there is just washed out.
--
-- It now lives in the `translucent` table at the bottom of theme/appearance.lua,
-- which is the mechanism built for exactly this in commit ef0bd81.
