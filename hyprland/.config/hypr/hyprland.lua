-- Hyprland Lua config — ~/.config/hypr/hyprland.lua
-- Wiki: https://wiki.hypr.land/Configuring/Start/
--
-- This file is a table of contents; the config lives in the modules below.
-- Layout of this directory is documented in README.md — read that before moving
-- things, because two files here are written by Noctalia at fixed paths.
--
-- Order matters in one place: `theme` goes last, because the palette has to
-- override border colours set by anything before it.

require("modules.environment")
require("modules.monitors")
require("modules.input")
require("modules.behaviour")
require("modules.keybinds")
require("modules.autostart")
require("modules.scratchpads")
require("modules.plugins")

require("rules")
require("theme")

-- Noctalia's palette. Two reasons this call is HERE and not in theme/init.lua,
-- where it would otherwise belong:
--
-- 1. Noctalia's template post_hook (/usr/share/noctalia/assets/templates/hyprland/
--    apply.sh) greps THIS FILE for the literal string `require("noctalia")` and
--    appends its own copy if it doesn't find one. The restructure moved the call
--    into theme/init.lua, so on the next login Noctalia duly appended a duplicate.
--    Keeping the literal here is what stops that.
-- 2. It has to run last anyway: it overrides border colours set by everything above.
--
-- So: don't move it, don't reword it, and don't let the string drift.
require("noctalia").apply_theme()

-- Anything that must OVERRIDE the palette goes after it. apply_theme() sets
-- col.active_border and col.inactive_border, so a theme's gradient borders and glow
-- have to be applied here or they'd be silently overwritten. pcall: most themes
-- ship none, and then Noctalia's plain borders are exactly what we want.
pcall(require, "theme.borders")
