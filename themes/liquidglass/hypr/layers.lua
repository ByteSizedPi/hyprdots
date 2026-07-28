-- liquidglass — layer rules.
--
-- Deliberately SHORTER than themes/_base/hypr/layers.lua, and it has to stay that
-- way. hyprglass does not deconflict with Hyprland's layer blur: it auto-manages
-- `noblur` for *windows* only, never for layers. A surface blurred here AND glassed
-- in glass.lua gets two blur passes and looks muddy.
--
-- Keep the two files in step:
--   glass.lua claims  noctalia-bar-default, noctalia-panel,
--                     noctalia-notification, noctalia-osd
--   this file keeps   noctalia-screen-corner
--
-- HOW THIS GETS OUT OF SYNC: save.sh captures the LIVE layers.lua. Saving
-- liquidglass while a non-glass theme's rules are installed overwrites this with the
-- full _base set — which is exactly what happened while hyprglass was parked
-- (2026-07-28). If glass starts looking muddy, count the rules here: 5 means it's
-- been clobbered and the four glass.lua claims need removing again.

-- Screen corners are opaque corner masks, not chrome. Glassing them would make the
-- rounded corners shimmer, so Hyprland keeps handling them natively.
hl.layer_rule({
	name = "noctalia-screen-corner-blur",
	match = { namespace = "^noctalia-screen-corner" },
	blur = true,
	ignore_alpha = 0.5,
})
