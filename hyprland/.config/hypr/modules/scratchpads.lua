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

-- ---------------------------------------------------------------------------
-- App scratchpads: YouTube Music and Beeper.
--
-- Each app gets three rules, and all three are needed:
--
--   1. workspace_rule + on_created_empty — launches the app the first time you
--      press the key. This is the closest thing Hyprland has to session restore.
--      Hyprland 0.56.2 has NO window session save or restore (the only "session"
--      keys in the Lua API are misc.session_lock_*, which are lock-screen keys).
--      on_created_empty needs none, because it is config, not saved state: after
--      a reboot the first toggle simply starts the app again.
--   2. window_rule workspace — pins the window to that special workspace however
--      it was started. Both apps are single-instance, so starting them a second
--      time raises the window that already exists instead of making a new one.
--      Without this rule that raised window appears on whatever workspace you
--      are looking at.
--   3. window_rule border_color — a fixed colour that outranks the global
--      col.active_border written by require("noctalia").apply_theme(), so the
--      border stays put through every theme change. Same trick as jjserver above,
--      except jjserver reads its colour from the generated theme/jjserver.lua.
-- ---------------------------------------------------------------------------

-- YouTube Music: a Chromium web app, red border, SUPER+Y.
--
-- The class is `chrome-<app-id>-Default`, where <app-id> is the --app-id in
-- ~/.local/share/applications/chrome-cinhimbnkkaeohfgghhklpknlkffjgod-Default.desktop.
-- The id comes from the app URL, so it survives a reinstall. Two traps: the class
-- says "chrome" but the binary is chromium-browser.sh, and `StartupWMClass` in
-- that .desktop file is `crx_<app-id>`, which does NOT match the live class. Read
-- the class from `hyprctl clients`, never from the .desktop file.
local youtube_class = "^chrome-cinhimbnkkaeohfgghhklpknlkffjgod-Default$"
local youtube_red = "rgb(ff0000)"

hl.workspace_rule({
	workspace = "special:youtube",
	on_created_empty = "/usr/lib64/chromium-browser/chromium-browser.sh"
		.. " --profile-directory=Default"
		.. " --app-id=cinhimbnkkaeohfgghhklpknlkffjgod",
})

hl.window_rule({
	name = "youtube-music-workspace",
	match = { class = youtube_class },
	workspace = "special:youtube silent",
})

hl.window_rule({
	name = "youtube-music-border",
	match = { class = youtube_class },
	border_color = youtube_red .. " " .. youtube_red,
})

-- Beeper: an AppImage in ~/Downloads, brand-blue border, SUPER+B.
--
-- The class is `Beeper`, read from `hyprctl clients` with the window open and
-- verified on 2026-09-03. Here the AppImage `StartupWMClass=Beeper` happens to be
-- right, unlike the YouTube Music case above, but do not trust that in general.
--
-- The launch command globs the version out of the filename, because the AppImage
-- is version-stamped (Beeper-4.2.985-x86_64.AppImage) and a pinned path would break
-- on the next update. `sort -V | tail -1` picks the newest one present.
local beeper_class = "^Beeper$"
local beeper_blue = "rgb(2a7bf6)"

hl.workspace_rule({
	workspace = "special:beeper",
	on_created_empty = "sh -c 'exec \"$(ls -1 ~/Downloads/Beeper-*.AppImage | sort -V | tail -1)\"'",
})

hl.window_rule({
	name = "beeper-workspace",
	match = { class = beeper_class },
	workspace = "special:beeper silent",
})

hl.window_rule({
	name = "beeper-border",
	match = { class = beeper_class },
	border_color = beeper_blue .. " " .. beeper_blue,
})

-- ---------------------------------------------------------------------------
-- MEASURED 2026-09-03: the Noctalia workspaces widget draws the workspace NUMBER,
-- not its name. Do not spend a number slot trying to get an app label into the bar.
--
-- The test: a `persistent = true` workspace 9 with `default_name = "TEST"`. Hyprland
-- accepted the name (`hyprctl workspaces` reported id 9, name "TEST"), but a
-- screenshot of the bar layer (`noctalia-bar-default`) showed a plain "9" pill. The
-- widget also takes only two config keys, `color` and `empty_color`, so there is no
-- label or icon option to turn on either.
--
-- So a bar entry per app needs a Noctalia PLUGIN WIDGET, not a workspace rule —
-- the same mechanism as noctalia/.config/noctalia/plugins/theme-switcher. A widget
-- like that would draw its own icon and run
--     hyprctl dispatch "hl.dsp.workspace.toggle_special('youtube')"
-- on click. The workspace rule was removed after the measurement.
-- ---------------------------------------------------------------------------
