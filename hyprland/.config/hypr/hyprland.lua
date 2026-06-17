-- Hyprland Lua config — ~/.config/hypr/hyprland.lua
-- Refer to the wiki: https://wiki.hypr.land/Configuring/Start/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

require("monitors")
require("autostart")
require("ui")
require("input")
require("keybinds")
require("windowrules")

-- Noctalia color template integration (must be last)
require("noctalia")
require("noctalia-windowrules")
