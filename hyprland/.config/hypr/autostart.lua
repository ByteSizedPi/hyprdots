-- Noctalia provides: bar, wallpaper, notifications, launcher, control center,
-- clipboard, lock screen, idle, OSDs, theming, dock, and polkit agent.
hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia --daemon")
end)
