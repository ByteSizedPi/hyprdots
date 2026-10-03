-- Session environment variables set by the compositor itself.
--
-- Anything needed by processes started *outside* Hyprland (greetd, systemd user
-- units) belongs in the `environment` stow package instead — these only reach
-- children of this compositor.

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- The environment package already puts these on PATH, but only uwsm applies
-- environment.d to the compositor. The plain "Hyprland" greetd session starts
-- start-hyprland with a bare PATH, so the zellij server inherits one and a
-- resurrected `claude` pane fails with "Command not found". Prepend them here
-- too, so both sessions give children the same PATH.
local home = os.getenv("HOME")
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
for _, dir in ipairs({ home .. "/bin", home .. "/.local/bin" }) do
    if not (":" .. path .. ":"):find(":" .. dir .. ":", 1, true) then
        path = dir .. ":" .. path
    end
end
hl.env("PATH", path)
