-- liquidglass — border and glow, the part that reads as a light source.
--
-- Installed to ~/.config/hypr/theme/borders.lua and required from hyprland.lua
-- AFTER `require("noctalia").apply_theme()`. That ordering is why this is separate
-- from appearance.lua: apply_theme() sets col.active_border/inactive_border from the
-- palette, so anything set before it is silently overwritten.
--
-- ALL border settings live here, thickness included. appearance.lua deliberately
-- does NOT set general.border_size any more — one place to look.
--
-- THE IDEA. Real glass doesn't have a uniform edge — it has a specular hot spot
-- where the light hits, a bright falloff either side, and a dark side where the
-- surface curves away from the light. A multi-stop gradient border at a fixed angle
-- is exactly that: the "light" sits at LIGHT_ANGLE and the rim rolls off around it.
-- hyprglass supplies refraction and aberration *inside* the pane; this draws the rim.
--
-- SCOPE — a hard limit, not an oversight: this file affects WINDOWS ONLY. Hyprland
-- cannot draw borders, glow, rounding or shadows on layer surfaces at all;
-- HL.LayerRuleSpec exposes only blur / blur_popups / xray / ignore_alpha / order /
-- animation / dim_around. The Noctalia bar and panels get their edge from elsewhere:
--   * hyprglass's own fresnel + specular, tuned per surface in glass.lua
--   * Noctalia's own chrome settings in noctalia.toml — bar.default.border,
--     bar.default.border_width, shell.* borders / radii / shadows
-- Neither supports a multi-stop gradient, so layers can match this in weight and
-- colour temperature but not in the specular ramp itself.

-- ═══ TUNING ═══════════════════════════════════════════════════════════

-- Border thickness, px. The gradient needs a couple of pixels to read at all, but
-- past ~3 the rim stops looking like an edge and starts looking like a frame.
local BORDER_SIZE = 2

-- Where the light comes from, in degrees. 45 = upper-left, which is what UI shading
-- conventions assume, so it reads as "lit" rather than merely "coloured".
local LIGHT_ANGLE = 45

-- The rim ramp, brightest first. Alpha does all the work, and these are deliberately
-- restrained: at high alpha a white stop stops reading as reflection and starts
-- reading as a painted outline. Raise `specular` first if you want more.
local rim = {
	specular = "rgba(ffffff99)", -- the hot spot
	falloff = "rgba(ffffff40)", -- rolling away from the light
	shadow = "rgba(12141a66)", -- the far side, curved away from the light
	bounce = "rgba(ffffff1a)", -- faint bounce light returning on the far edge
}

-- Outer glow: light bleeding off the edge of the pane.
local glow = {
	enabled = true,
	range = 14, -- px
	render_power = 3, -- falloff exponent, same meaning as on shadows
	color = "rgba(cfe4ff59)", -- cool white, matching the rim's colour temperature
}

-- ═══ APPLY ════════════════════════════════════════════════════════════
-- Active and inactive are intentionally identical — this theme does not signal focus
-- visually, in opacity or in border. Don't reintroduce a split.

local ramp = {
	-- Stops run in listed order around the angle: hot spot -> falloff -> dark far
	-- side -> faint bounce.
	colors = { rim.specular, rim.falloff, rim.shadow, rim.bounce },
	angle = LIGHT_ANGLE,
}

hl.config({
	general = {
		border_size = BORDER_SIZE,
		col = {
			active_border = ramp,
			inactive_border = ramp,
		},
	},

	decoration = {
		glow = {
			enabled = glow.enabled,
			range = glow.range,
			render_power = glow.render_power,
			color = glow.color,
			color_inactive = glow.color,
		},
	},
})
