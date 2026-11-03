-- Special workspaces (SUPER+S, SUPER+Y, SUPER+B): a blurred background, so the
-- normal workspace behind shows only as blur.
--
-- Loaded from hyprland.lua AFTER the theme, because every theme sets
-- decoration.dim_special in theme/appearance.lua (mostly 0), which would
-- overwrite this.
--
-- dim_special is the opacity of a black layer that Hyprland draws between the
-- normal workspace and a special workspace on top of it. 1 = solid black, so
-- the gaps show black instead of the windows behind (2026-10-07; every theme had
-- 0, fully see-through).
--
-- 2026-11-01: blurred background replaces the black one. dim_special = 0 removes
-- the black layer. blur.special makes Hyprland blur behind the special workspace.
-- size, passes and xray are the values in themes/noctalia. They are
-- global: they also change the blur on Noctalia surfaces in every theme.
-- blur.special is expensive on the iGPU when undocked. See docs/problems.md,
-- "Special-workspace slide stutters on laptop panel when undocked".
-- No vibrancy key: Hyprland caps it at 1.0, and the old value 9 failed with a
-- config error (2026-11-03). The default 0.1696 applies.
--
-- History (2026-10-20): this file used to hide the Noctalia bar while a special
-- workspace showed (`noctalia msg bar-hide` / `bar-show`). Removed: glitchy.
-- Then a tertiary border on special windows was tried and removed: not liked.
-- Special windows now look like all others. See docs/problems.md.
hl.config({
	decoration = {
		dim_special = 0,
		blur = {
			special = true,
			size = 10,
			passes = 3,
			xray = true,
		},
	},
})
