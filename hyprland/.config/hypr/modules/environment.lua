-- Session environment variables set by the compositor itself.
--
-- Anything needed by processes started *outside* Hyprland (greetd, systemd user
-- units) belongs in the `environment` stow package instead — these only reach
-- children of this compositor.

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
