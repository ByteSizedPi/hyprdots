-- Theme-independent visual effects. Theme-owned look (gaps, rounding, shadow,
-- blur, glow, animations) stays in theme/; nothing in theme/ sets these keys.
--
-- Motion blur (new in Hyprland 0.56, kept after a trial on 2026-10-07). While a window moves
-- (workspace switch, window move or resize animation, scrolling-layout scroll),
-- Hyprland smears it along its direction of travel. `samples` is how many
-- copies it blends per frame: more is smoother and costs more GPU. 7 is the
-- default.
hl.config({
	decoration = {
		motion_blur = {
			enabled = true,
			samples = 7,
		},
	},
})

-- Tried and removed 2026-10-08: decoration.glow with a primary->secondary gradient
-- on the focused window. On these partly transparent windows it showed as a haze
-- INSIDE the window edge, not as light in the gap outside. Not liked.
