-- Special-workspace scratchpads: what launches in them, and how they look.
--
-- These are `on_created_empty` rules, so the command runs the first time the
-- scratchpad is summoned and never again — the session persists across toggles.
-- Bound to SUPER+S / SUPER+A in modules/keybinds.lua.

local terminal = require("lib.terminal")

-- zellij: a local persistent multiplexer session.
hl.workspace_rule({
	workspace = "special:zellij",
	on_created_empty = terminal .. " zellij attach main --create",
})

-- jjserver: launch with a dedicated kitty config (jjserver.conf) that re-pins the
-- cobalt theme after the wallpaper include, so a live theme reload (SIGUSR1) keeps
-- this window cobalt instead of reverting to the wallpaper palette. kitten ssh +
-- ssh.conf also set the color_scheme on connect. Hardcoded to kitty (not `terminal`)
-- because the ssh kitten and --config are kitty-specific.
hl.workspace_rule({
	workspace = "special:jjserver",
	on_created_empty = "kitty --config ~/.config/kitty/jjserver.conf kitten ssh -t jjserver@100.68.211.32 zellij attach jjserver --create",
})

-- jjserver border: colored by the palette primary (generated into theme/jjserver.lua
-- by scripts/server-theme/deploy.sh) so the special-workspace border matches the cobalt
-- nvim/zellij/kitty theme rather than the wallpaper. pcall so a machine without the
-- generated file still loads cleanly.
local ok, jj = pcall(require, "theme.jjserver")
if ok and type(jj) == "table" and jj.primary then
	local c = "rgb(" .. jj.primary .. ")"
	hl.window_rule({
		name = "jjserver-border",
		match = { workspace = "special:jjserver" },
		border_color = c .. " " .. c,
	})
end
