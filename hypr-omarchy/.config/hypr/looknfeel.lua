-- Change the default Omarchy look'n'feel.

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- ── Home parity (hyprdots themes/catppuccin/hypr/appearance.lua + modules/effects.lua) ──
-- Loaded after Omarchy's defaults AND after the theme's hyprland.lua, so these win.
-- Border COLOURS come from the theme (colors.toml hyprland_*_border), not from here.

hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 4,
    border_size = 2,
  },

  decoration = {
    rounding_power = 2,
    active_opacity = 1,
    inactive_opacity = 1,
    dim_special = 0,
    dim_inactive = false,
    shadow = { enabled = false },

    -- Motion blur (Hyprland 0.56): smear windows along their direction of travel.
    motion_blur = { enabled = true, samples = 7 },
  },
})

-- Snappier window motion than Omarchy's defaults. `windows` (reflow) MUST match
-- windowsIn/Out, or a new window finishes popping in while neighbours still slide.
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "quick", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "quick", style = "popin 80%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "quick" })
-- Workspace switching instant (Omarchy disables `workspaces` too; be explicit).
hl.animation({ leaf = "workspacesIn", enabled = false })
hl.animation({ leaf = "workspacesOut", enabled = false })
-- Scratchpads slide in vertically.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert" })
-- Cursor zoom (used by the SUPER+pinch / SUPER+CTRL+= zoom binds, if ported).
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- Blur behind the see-through shell surfaces (home: themes/catppuccin/hypr/layers.lua).
-- Omarchy turns blur off globally; windows here are opaque, so enabling it only
-- affects these layers. Hyprland's stock blur values, as at home.
hl.config({ decoration = { blur = { enabled = true, size = 8, passes = 1 } } })
hl.layer_rule({ name = "home-bar-blur", match = { namespace = "^omarchy-bar$" }, blur = true, blur_popups = true, xray = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "home-notification-blur", match = { namespace = "^omarchy-notifications$" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "home-osd-blur", match = { namespace = "^omarchy-osd$" }, blur = true, ignore_alpha = 0.5 })
