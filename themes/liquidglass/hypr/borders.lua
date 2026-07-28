-- liquidglass — border and glow, the part that reads as a light source.
--
-- Installed to ~/.config/hypr/theme/borders.lua and required from hyprland.lua
-- AFTER `require("noctalia").apply_theme()`. That ordering is the whole reason this
-- file exists separately from appearance.lua: apply_theme() sets
-- col.active_border/inactive_border from the palette, so anything set before it is
-- silently overwritten.
--
-- THE IDEA. Real glass doesn't have a uniform edge — it has a specular hot spot
-- where the light hits, a bright falloff either side, and a dark side where the
-- surface curves away from the light. A multi-stop gradient border at a fixed angle
-- is exactly that: the "light" sits at LIGHT_ANGLE and the rim rolls off around it.
-- hyprglass supplies refraction and aberration *inside* the pane; this draws the rim.

-- ═══ TUNING ═══════════════════════════════════════════════════════════
-- Where the light comes from, in degrees. 45 = upper-left, which is what almost
-- every UI shading convention assumes, so it reads as "lit" rather than "odd".
local LIGHT_ANGLE = 45

-- The rim ramp, brightest first. Alpha does the work — a white stop at low alpha
-- over a dark desktop still reads as a highlight, and keeps the border neutral so
-- it doesn't fight whatever palette Noctalia derived from the wallpaper.
local rim = {
	specular = "rgba(ffffffe6)", -- the hot spot, near-opaque white
	falloff = "rgba(ffffff73)", -- rolling away from the light
	shadow = "rgba(12141aa6)", -- the far side, curved away, goes dark
	bounce = "rgba(ffffff40)", -- faint bounce light returning on the far edge
}

-- Inactive windows keep the same shape but a much weaker light, so focus is still
-- readable without touching opacity (which is deliberately identical either way —
-- see appearance.lua). Set these to the same values as `rim` if you want no focus
-- cue at all.
local rim_inactive = {
	specular = "rgba(ffffff73)",
	falloff = "rgba(ffffff33)",
	shadow = "rgba(12141a8c)",
	bounce = "rgba(ffffff1a)",
}

-- Outer glow: light bleeding off the edge of the pane. Range is in px.
local glow = {
	enabled = true,
	range = 14,
	render_power = 3,
	color = "rgba(cfe4ff59)", -- cool white, matching the rim's colour temperature
	color_inactive = "rgba(cfe4ff1a)",
}

-- ═══ APPLY ════════════════════════════════════════════════════════════

hl.config({
	general = {
		col = {
			-- Gradient stops run in listed order around the angle, so this is:
			-- hot spot -> falloff -> dark far side -> faint bounce.
			active_border = {
				colors = { rim.specular, rim.falloff, rim.shadow, rim.bounce },
				angle = LIGHT_ANGLE,
			},
			inactive_border = {
				colors = { rim_inactive.specular, rim_inactive.falloff, rim_inactive.shadow, rim_inactive.bounce },
				angle = LIGHT_ANGLE,
			},
		},
	},

	decoration = {
		glow = {
			enabled = glow.enabled,
			range = glow.range,
			render_power = glow.render_power,
			color = glow.color,
			color_inactive = glow.color_inactive,
		},
	},
})
