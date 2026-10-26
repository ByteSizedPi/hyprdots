-- Special workspaces (SUPER+S, SUPER+Y, SUPER+B): an opaque background, so the
-- normal workspace behind does not show through.
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
-- History (2026-10-20): this file used to hide the Noctalia bar while a special
-- workspace showed (`noctalia msg bar-hide` / `bar-show`). Removed: glitchy.
-- Then a tertiary border on special windows was tried and removed: not liked.
-- Special windows now look like all others. See docs/problems.md.
hl.config({
	decoration = {
		dim_special = 1,
	},
})
