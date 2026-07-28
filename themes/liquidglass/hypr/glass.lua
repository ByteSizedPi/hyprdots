-- liquidglass — hyprglass configuration.
--
-- Installed to ~/.config/hypr/theme/glass.lua by scripts/desktop-theme/apply.sh
-- because themes/liquidglass/manifest.conf says `hyprglass = on`.
--
-- HAND-AUTHORED. save.sh cannot capture this — hg.layer()/hg.preset() are Lua-side
-- registrations with no readback. Edit here, `hyprctl reload`, look, repeat.
-- See docs/theming.md → "hyprglass: glass is a per-theme thing".

if not hl.plugin.hyprglass then
	return -- plugin not loaded yet; modules/plugins.lua re-parses once hyprpm finishes
end

local hg = hl.plugin.hyprglass

hg.config({
	enabled = true,
	default_theme = "dark",
	default_preset = "noctalia",

	-- Leave manage_window_blur at its default (on): it sets `noblur` on glassed
	-- windows so Hyprland's cached blur doesn't paint over the glass. Turning it
	-- off means managing `noblur` window rules by hand.

	layers = { enabled = true },
})

-- The look. Tuned against a dark palette with ~0.65 chrome opacity; if you switch
-- the Noctalia palette to something light, revisit brightness/adaptive_*.
hg.preset("noctalia", {
	inherits = "clear",
	glass_opacity = 0.75,
	blur_strength = 1.6,
	blur_iterations = 3,
	dark = { brightness = 0.78, adaptive_dim = 0.5 },
	light = { brightness = 1.15, adaptive_boost = 0.4 },
})

-- A softer variant for the big panels, which cover a lot of screen — full-strength
-- refraction over half the desktop reads as noise rather than glass.
hg.preset("noctalia-panel", {
	inherits = "subtle",
	glass_opacity = 0.8,
	blur_strength = 2.0,
})

-- === Layer surfaces ===================================================
-- Namespaces are matched EXACTLY — no regex, unlike hl.layer_rule. These strings
-- are measured, not guessed (docs/problems.md has the table + how to re-measure).
--
-- Whitelisting is opt-in: naming any layer here means ONLY named layers get glass.
-- That is deliberate — an empty whitelist glasses everything, wallpaper included.
--
-- mask_threshold is an alpha cutoff: pixels fainter than this are left alone. It
-- exists to keep layer *shadows* from being treated as content. This theme sets
-- shell.shadow.alpha = 0.2 in noctalia.toml so 0.3 cleanly separates the two.

hg.layer("noctalia-bar-default", { mask_threshold = 0.3 })
hg.layer("noctalia-panel", { preset = "noctalia-panel", mask_threshold = 0.3 })
hg.layer("noctalia-notification", { mask_threshold = 0.3 })
hg.layer("noctalia-osd", { mask_threshold = 0.3 })

-- Deliberately NOT glassed:
--   noctalia-wallpaper         it's the background — glass would sample itself
--   noctalia-screen-corner     opaque corner masks; keeps its native rule in layers.lua
--   noctalia-desktop-widget-*  namespaces carry per-instance hex IDs, so exact
--                              matching can't reach them at all

-- === Per-window exceptions ============================================
-- Glass costs a blur pass per window and actively hurts on video and fullscreen.
hl.window_rule({
	name = "glass-off-fullscreen",
	match = { fullscreen = true },
	tag = "+hyprglass_disabled",
})

hl.window_rule({
	name = "glass-off-video",
	match = { class = "^(mpv|vlc)$" },
	tag = "+hyprglass_disabled",
})
