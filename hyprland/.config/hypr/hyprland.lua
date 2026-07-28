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
