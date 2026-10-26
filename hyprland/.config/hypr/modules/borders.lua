-- Window border colours: primary on EVERY window, focused or not.
--
-- Noctalia's builtin Hyprland template
-- (/usr/share/noctalia/assets/templates/hyprland/hyprland.lua) renders
-- noctalia.lua with inactive_border = surface. Until 2026-10-20 that package
-- file was patched by hand with sudo after every noctalia update (SYSTEM.md).
-- This override replaces the patch: it runs after require("noctalia").apply_theme()
-- in hyprland.lua, reads the same palette, and survives package updates.
--
-- Loaded BEFORE theme.borders, so a theme that ships its own gradient borders
-- still wins.
local c = require("noctalia").colors

hl.config({
	general = {
		col = {
			active_border = c.primary,
			inactive_border = c.primary,
		},
	},
})
