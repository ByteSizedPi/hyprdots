-- Layer rules for the Noctalia shell surfaces — THEME-OWNED.
--
-- Why this isn't in rules/: hyprglass does NOT deconflict with Hyprland's layer
-- blur. It auto-sets `noblur` on glassed *windows* (manage_window_blur), but there
-- is no layer equivalent — so a layer that is both blurred here and glassed by
-- hyprglass gets two blur passes and looks wrong. A theme that hands a surface to
-- hyprglass must therefore drop its rule here. See docs/problems.md → "hyprglass".
--
-- This is the no-glass default: Hyprland blurs everything itself.
--
-- Namespaces are measured, not guessed (docs/problems.md has the table). Note
-- `noctalia-panel` covers the launcher, control-center, wallpaper AND session
-- panels — they are indistinguishable at the namespace level.
-- `noctalia-wallpaper` and `noctalia-desktop-widget-*` are deliberately absent.

hl.layer_rule({
	name = "noctalia-bar-blur",
	match = { namespace = "^noctalia-bar.*" },
	blur = true,
	blur_popups = true,
	xray = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-panel-blur",
	match = { namespace = "^noctalia-panel" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-screen-corner-blur",
	match = { namespace = "^noctalia-screen-corner" },
	blur = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-notification-blur",
	match = { namespace = "^noctalia-notification$" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	name = "noctalia-osd-blur",
	match = { namespace = "^noctalia-osd$" },
	blur = true,
	ignore_alpha = 0.5,
})
