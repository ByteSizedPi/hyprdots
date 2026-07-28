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

-- ═══ TUNING ═══════════════════════════════════════════════════════════
-- Every number lives here. Surfaces differ only by the scale factors below, so
-- nudging a dial moves windows, chrome and panels together and keeps their
-- relationship intact — which is the whole point of the split.

-- How glassy. These are the drama dials; all 0-1 except blur.
local glass = {
	opacity = 0.85, -- 0-1, overall glass opacity
	blur = 2.6, -- radius = value * 12px
	iterations = 4, -- 1-5 gaussian passes; 5 costs a lot for little gain
	refraction = 0.9, -- edge bending
	aberration = 0.95, -- rainbow fringing at edges — the most obviously "glassy" one
	fresnel = 0.95, -- bright rim
	specular = 1.0, -- highlight
	tint = 0x8899aa55, -- RRGGBBAA; the alpha byte IS the tint strength
}

-- Tone, shared by every surface so the whole desktop reads as one material.
local dark = {
	brightness = 0.72,
	contrast = 1.05,
	saturation = 0.95,
	vibrancy = 0.30,
	adaptive_dim = 0.60, -- pulls bright backgrounds down so the rim reads
}
local light = {
	brightness = 1.18,
	adaptive_boost = 0.50,
}

-- Alpha cutoff that stops layer SHADOWS being treated as glassable content. Must
-- sit above noctalia.toml's shell.shadow.alpha (0.2). Raise both together or you
-- get glassed shadow halos.
local mask_threshold = 0.3

-- Per-surface deviation. Geometry canNOT be shared: edge_thickness and
-- lens_distortion are fractions of the surface's SMALLEST dimension, so the 0.10
-- bezel that flatters a window swallows a 30px bar.
--   soften  multiplies the four optics dials (big surfaces need less)
--   blur    multiplies glass.blur (big surfaces want more, to separate from content)
local surfaces = {
	-- bar, notifications, OSD: thin, so nearly flat geometry
	chrome = { soften = 0.85, blur = 1.08, opacity = 0.88, edge = 0.04, dome = 0.20 },
	-- launcher, control-center, session: cover half the screen, so restrained
	-- optics — full-strength refraction over that area reads as noise, not glass
	panel = { soften = 0.60, blur = 1.23, opacity = 0.90, edge = 0.05, dome = 0.15 },
}

-- Windows use the globals directly, so their geometry lives here rather than in
-- `surfaces` above.
-- edge is capped at 0.15 by the plugin; 0.14 is as thick as the bezel goes.
-- Paired with rounding_power 4.0 in appearance.lua, the aberration gets a long
-- flat corner arc to spread along instead of a tight circular one.
local window = { edge = 0.14, dome = 0.75 }

-- ═══ APPLY ════════════════════════════════════════════════════════════
-- The baseline goes in the GLOBALS rather than a window preset, for two reasons:
-- windows then need no preset at all, and globals are the only externally checkable
-- part — `hyprctl getoption plugin:hyprglass:<key>` reports globals, while preset
-- values resolve at render time and never show up.
hg.config({
	enabled = true,
	default_theme = "dark",
	layers = { enabled = true },

	glass_opacity = glass.opacity,
	blur_strength = glass.blur,
	blur_iterations = glass.iterations,
	refraction_strength = glass.refraction,
	chromatic_aberration = glass.aberration,
	fresnel_strength = glass.fresnel,
	specular_strength = glass.specular,
	edge_thickness = window.edge,
	lens_distortion = window.dome,
	tint_color = glass.tint,

	dark = dark,
	light = light,
})

-- Build a layer preset from the baseline, softened by that surface's factors.
local function preset_for(s)
	return {
		inherits = "high_contrast",

		glass_opacity = s.opacity,
		blur_strength = glass.blur * s.blur,
		blur_iterations = glass.iterations,

		refraction_strength = glass.refraction * s.soften,
		chromatic_aberration = glass.aberration * s.soften,
		fresnel_strength = glass.fresnel * s.soften,
		specular_strength = glass.specular * s.soften,

		edge_thickness = s.edge,
		lens_distortion = s.dome,
		tint_color = glass.tint,

		dark = dark,
		light = light,
	}
end

hg.preset("noctalia-chrome", preset_for(surfaces.chrome))
hg.preset("noctalia-panel", preset_for(surfaces.panel))

-- ═══ LAYER SURFACES ═══════════════════════════════════════════════════
-- Namespaces are matched EXACTLY — no regex, unlike hl.layer_rule. These strings are
-- measured, not guessed (docs/problems.md has the table and how to re-measure).
--
-- Naming any layer makes this a whitelist: ONLY these get glass. That's deliberate —
-- an empty whitelist glasses everything, wallpaper included.

hg.layer("noctalia-bar-default", { preset = "noctalia-chrome", mask_threshold = mask_threshold })
hg.layer("noctalia-notification", { preset = "noctalia-chrome", mask_threshold = mask_threshold })
hg.layer("noctalia-osd", { preset = "noctalia-chrome", mask_threshold = mask_threshold })
hg.layer("noctalia-panel", { preset = "noctalia-panel", mask_threshold = mask_threshold })

-- Deliberately NOT glassed:
--   noctalia-wallpaper         it's the background — glass would sample itself
--   noctalia-screen-corner     opaque corner masks; keeps its native rule in layers.lua
--   noctalia-desktop-widget-*  namespaces carry per-instance hex ids, so exact
--                              matching can't reach them at all

-- ═══ PER-WINDOW EXCEPTIONS ════════════════════════════════════════════
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
