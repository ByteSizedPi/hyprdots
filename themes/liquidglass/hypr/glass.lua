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

-- How glassy. The README documents 0-1 for the optics and nothing enforces it — no
-- clamp anywhere in the plugin's C++ — but the range is NOT arbitrary, and going far
-- past it breaks the image rather than intensifying it.
--
-- Fringing is a PRODUCT, not a single dial. From Shaders.hpp:
--     refractionPx = refraction * 50.0
--     baseOffset   = inwardDir * edgeProximity * refractionPx / fullSize
--     chromaSpread = aberration * 0.35
--     offsetR/B    = baseOffset * (1 -/+ chromaSpread)
-- so visible fringing scales with refraction x aberration x edgeProximity. Raising
-- one alone hits diminishing returns; raising them together separates the channels.
--
-- HARD CEILING on aberration: chromaSpread = aberration * 0.35, and the red channel
-- is sampled at (1 - chromaSpread). Past aberration 2.86 that term goes NEGATIVE and
-- red refracts in the opposite direction to green and blue — the image visibly comes
-- apart. 3.0 was tried on 2026-07-28 and looked broken for exactly this reason.
-- Keep aberration <= 1.5; refraction is the safe dial, since it scales all three
-- channels equally and only decides how far the sample travels.
local glass = {
	opacity = 1.0, -- 0-1, overall glass opacity
	blur = 0.4, -- radius = value * 12px, so ~5px. Heavy blur AVERAGES AWAY the
	-- displaced samples refraction creates — the two fight, so keep this low.
	iterations = 2, -- 1-5 gaussian passes
	refraction = 1.8, -- edge bending; * 50 = 90px of sample offset at the edge
	aberration = 0.9, -- spectral fringing; red x0.69 blue x1.31
	-- Rim glow, and now the ONLY rim: Hyprland's border and glow are both off, so
	-- these two replace them. Adds white to the ALREADY-REFRACTED sample, which is
	-- why it reacts to what's behind the window instead of being a painted-on colour.
	-- Additive white peaks at strength * 0.15, so 2.0 = up to 30% at the boundary.
	fresnel = 3.0,
	-- Top-biased highlight, peaks at strength * 0.08. Together with fresnel this is
	-- the light-from-above cue the border gradient used to provide.
	specular = 2.2,
	tint = 0x8899aa22, -- RRGGBBAA; the alpha byte IS the tint strength
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
--   soften  multiplies refraction and aberration (big surfaces need less)
--   rim     multiplies fresnel and specular SEPARATELY, because the rim is the only
--           edge a layer can have: Hyprland cannot draw borders or glow on layer
--           surfaces (HL.LayerRuleSpec has no such fields), so theme/borders.lua
--           reaches windows only. Keeping rim high here is what stops the bar and
--           panels looking flat next to windows.
--   blur    multiplies glass.blur (big surfaces want more, to separate from content)
local surfaces = {
	-- bar, notifications, OSD: thin, so nearly flat geometry
	chrome = { soften = 0.85, rim = 1.00, blur = 1.08, opacity = 0.88, edge = 0.06, dome = 0.20 },
	-- launcher, control-center, session: cover half the screen, so restrained
	-- optics — full-strength refraction over that area reads as noise, not glass
	panel = { soften = 0.60, rim = 0.95, blur = 1.23, opacity = 0.90, edge = 0.08, dome = 0.15 },
}

-- Windows use the globals directly, so their geometry lives here rather than in
-- `surfaces` above.
-- `edge` sets bezelWidthPx = edge * min(window dimension), and EVERY edge term
-- scales with exp(cornerSdf / bezelWidthPx) — refraction, aberration, and the
-- hardcoded inner shadow at Shaders.hpp:257 that has no strength uniform and cannot
-- be switched off. Shrinking this is therefore the only way to reduce that shadow.
-- At 0.14 the band was ~140px on a 1000px window, which is why the rim was obvious;
-- 0.02 keeps refraction as a thin edge and makes the shadow essentially invisible.
-- Do NOT set it to 0: bezelWidthPx would be 0 and cornerSdf/0 is NaN at the boundary.
-- Band width. THIN = SHARP: this is the falloff distance, so a small value crams
-- the distortion into a crisp strip at the boundary, while a large one smears the
-- same effect across half the pane and reads as mush. 0.06 is the plugin default
-- and about the sharpest that still shows depth; 0.035 is tighter still, which
-- concentrates the fresnel rim into a hard edge line rather than a soft band.
-- Two independent things, easy to confuse:
--   strength       sets how BRIGHT the rim is — peak is strength * 0.15 at the
--                  boundary, where edgeProximity is 1, so it does not depend on this
--   edge_thickness sets how DEEP the effect fades inward
-- 0.022 keeps the rim as bright as before while cutting the fresnel tail from ~54px
-- to ~34px into the window; at 0.035 it read as too thick at the corners.
local window = { edge = 0.022, dome = 0.5 }

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
		-- clamped: the plugin's ceiling for these is 1.0
		fresnel_strength = math.min(1.0, glass.fresnel * s.rim),
		specular_strength = math.min(1.0, glass.specular * s.rim),

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
