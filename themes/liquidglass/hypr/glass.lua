-- liquidglass — hyprglass configuration.
--
-- Installed to ~/.config/hypr/theme/glass.lua by scripts/desktop-theme/apply.sh
-- because themes/liquidglass/manifest.conf says `hyprglass = on`.
--
-- Edit the installed copy, `hyprctl reload`, look, repeat — then bank it with
-- `scripts/desktop-theme/save.sh liquidglass --force`. See docs/theming.md.
--
-- PREREQUISITE, and the usual reason "glass isn't working": windows must be
-- translucent. The glass slab is drawn BEHIND the window surface, so at
-- active_opacity = 1 the window hides it completely and none of the settings below
-- do anything visible. appearance.lua keeps them at 0.88 / 0.80 for this reason.

if not hl.plugin.hyprglass then
	return -- not loaded yet; modules/plugins.lua re-parses once hyprpm finishes
end

local hg = hl.plugin.hyprglass

-- The dramatic baseline lives HERE, in the globals, rather than in a preset for
-- windows. Two reasons: windows then need no preset at all, and globals are the only
-- part that's externally checkable — `hyprctl getoption plugin:hyprglass:<key>`
-- reports globals, while preset values resolve at render time and never show up.
-- Presets below are used only where a surface needs to deviate.
hg.config({
	enabled = true,
	default_theme = "dark",
	layers = { enabled = true },

	glass_opacity = 0.85,
	blur_strength = 2.6, -- radius = value * 12px
	blur_iterations = 4, -- 1-5; 5 costs noticeably more for little gain

	refraction_strength = 0.9, -- 0-1, edge bending
	chromatic_aberration = 0.8, -- 0-1, the rainbow fringing at edges
	fresnel_strength = 0.95, -- 0-1, bright rim
	specular_strength = 1.0, -- 0-1, highlight
	edge_thickness = 0.10, -- 0-0.15, bezel width; the "thick slab" look
	lens_distortion = 0.7, -- 0-1, centre dome magnification

	tint_color = 0x8899aa55, -- same hue as the default, alpha 0x22 -> 0x55

	dark = {
		brightness = 0.72,
		contrast = 1.05,
		saturation = 0.95,
		vibrancy = 0.30,
		adaptive_dim = 0.60, -- pulls bright backgrounds down so the rim reads
	},
	light = {
		brightness = 1.18,
		adaptive_boost = 0.50,
	},
})

-- === Presets ==========================================================
-- Only for surfaces that must deviate from the globals above. The geometry options
-- scale with the surface — `edge_thickness` is a fraction of the smallest dimension,
-- so the bezel that flatters a window swallows a 30px bar. Windows use the globals
-- and need no preset.

-- THIN CHROME — bar, notifications, OSD. Same optics, restrained geometry: a wide
-- bezel or strong dome on a 30px-tall surface just looks like a smear.
hg.preset("noctalia-chrome", {
	inherits = "high_contrast",

	glass_opacity = 0.88,
	blur_strength = 2.8,
	blur_iterations = 4,

	refraction_strength = 0.75,
	chromatic_aberration = 0.6,
	fresnel_strength = 0.85,
	specular_strength = 0.9,
	edge_thickness = 0.04, -- deliberately thin
	lens_distortion = 0.2, -- almost flat

	tint_color = 0x8899aa44,

	dark = { brightness = 0.75, vibrancy = 0.25, adaptive_dim = 0.5 },
	light = { brightness = 1.15, adaptive_boost = 0.45 },
})

-- LARGE PANELS — launcher, control-center, session. These cover a lot of screen,
-- and full-strength refraction over half the desktop reads as noise rather than
-- glass, so the optics are dialled back while the blur stays heavy.
hg.preset("noctalia-panel", {
	inherits = "high_contrast",

	glass_opacity = 0.90,
	blur_strength = 3.2,
	blur_iterations = 4,

	refraction_strength = 0.55,
	chromatic_aberration = 0.35,
	fresnel_strength = 0.8,
	specular_strength = 0.8,
	edge_thickness = 0.05,
	lens_distortion = 0.15,

	dark = { brightness = 0.7, adaptive_dim = 0.55 },
	light = { brightness = 1.2, adaptive_boost = 0.5 },
})

-- === Layer surfaces ===================================================
-- Namespaces are matched EXACTLY — no regex, unlike hl.layer_rule. These strings are
-- measured, not guessed (docs/problems.md has the table and how to re-measure).
--
-- Naming any layer makes this a whitelist: ONLY these get glass. That's deliberate —
-- an empty whitelist glasses everything, wallpaper included.
--
-- mask_threshold is an alpha cutoff below which pixels are left alone; it exists to
-- stop layer SHADOWS being treated as content. noctalia.toml keeps
-- shell.shadow.alpha = 0.2, so 0.3 separates the two cleanly. Change one, re-check
-- the other or you get glassed shadow halos.

hg.layer("noctalia-bar-default", { preset = "noctalia-chrome", mask_threshold = 0.3 })
hg.layer("noctalia-notification", { preset = "noctalia-chrome", mask_threshold = 0.3 })
hg.layer("noctalia-osd", { preset = "noctalia-chrome", mask_threshold = 0.3 })
hg.layer("noctalia-panel", { preset = "noctalia-panel", mask_threshold = 0.3 })

-- Deliberately NOT glassed:
--   noctalia-wallpaper         it's the background — glass would sample itself
--   noctalia-screen-corner     opaque corner masks; keeps its native rule in layers.lua
--   noctalia-desktop-widget-*  namespaces carry per-instance hex ids, so exact
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
