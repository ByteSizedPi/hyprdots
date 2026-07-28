-- The theme surface: everything that changes when you switch looks.
--
-- Required LAST from hyprland.lua, because the palette must win over anything
-- set earlier (notably border colours).
--
-- Every file here is GENERATED — don't hand-edit for keeps, the next
-- apply.sh/deploy.sh run overwrites it. Edit the tracked input instead:
--   appearance.lua   <- themes/<name>/hypr/appearance.lua   (apply.sh)
--   layers.lua       <- themes/<name>/hypr/layers.lua       (apply.sh)
--   glass.lua        <- themes/<name>/hypr/glass.lua        (apply.sh)
--   jjserver.lua     <- noctalia palettes/<name>.json       (deploy.sh)
--   ../noctalia.lua  <- Noctalia builtin template (fixed path, can't be moved)
--
-- pcall so a fresh machine that hasn't run apply.sh yet still parses cleanly
-- rather than dying on a missing fragment. If a look silently doesn't apply,
-- suspect a fragment that failed to load and run apply.sh again.
local function optional(mod)
	pcall(require, mod)
end

optional("theme.appearance") -- gaps, rounding, opacity, shadow, blur, animations
optional("theme.layers") -- layer rules: native blur, or ceded to hyprglass
optional("theme.glass") -- hyprglass config, or an explicit disable stub

-- Noctalia's palette. Must come after the above: it overrides border colours.
require("noctalia").apply_theme()
