-- liquidglass — layer rules.
--
-- Deliberately SHORTER than themes/_base/hypr/layers.lua. hyprglass does not
-- deconflict with Hyprland's layer blur: it only auto-manages `noblur` for
-- *windows*. A surface that is blurred here AND glassed in glass.lua gets two
-- blur passes and looks muddy.
--
-- So every namespace listed in glass.lua is absent here:
--   noctalia-bar-default, noctalia-panel, noctalia-notification, noctalia-osd
--
-- What's left is the one surface glass doesn't want.

-- Screen corners are opaque corner masks, not chrome — glassing them would make
-- the rounded corners shimmer. Keep Hyprland's native handling.
hl.layer_rule({
	name = "noctalia-screen-corner-blur",
	match = { namespace = "^noctalia-screen-corner" },
	blur = true,
	ignore_alpha = 0.5,
})
