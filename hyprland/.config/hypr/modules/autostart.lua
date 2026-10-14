-- Noctalia provides: bar, wallpaper, notifications, launcher, control center,
-- clipboard, lock screen, idle, OSDs, theming, dock, and polkit agent.
hl.on("hyprland.start", function()
	-- Hand the session env to the ksecretd that pam_kwallet5 started at the
	-- greeter, so the wallet it unlocked with the login password joins D-Bus.
	-- Plasma runs this from XDG autostart; Hyprland does not.
	hl.exec_cmd("/usr/libexec/pam_kwallet_init")
	hl.exec_cmd("noctalia --daemon")
end)
