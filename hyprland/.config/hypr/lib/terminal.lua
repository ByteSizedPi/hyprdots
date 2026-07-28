-- Resolve the terminal emulator once, for everything that needs to spawn one.
--
-- $TERMINAL is set per-session (see the `environment` stow package); the
-- xdg-terminal-exec fallback is what the freedesktop spec says to use when it
-- isn't. Both modules/keybinds.lua and modules/scratchpads.lua used to carry
-- their own copy of this dance.

local t = os.getenv("TERMINAL")

return (t ~= nil and t ~= "" and t) or "xdg-terminal-exec"
