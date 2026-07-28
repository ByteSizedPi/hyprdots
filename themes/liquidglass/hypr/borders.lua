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

-- ═══ PALETTE ══════════════════════════════════════════════════════════
-- Hyprland's glow draws in the GAP outside the window, where there is no window
-- content to sample — so unlike hyprglass's fresnel (which adds light to the
-- already-refracted content and therefore reacts to whatever is underneath), this
-- one has to be given a colour. A fixed colour fights the glass, so take it from
-- Noctalia's palette instead: that palette is derived from the wallpaper, so the
-- glow tracks the desktop rather than cutting across it.
--
-- Safe if noctalia.lua is missing (fresh machine, before the first theme apply) —
-- falls back to the neutral cool white.
local ok_palette, noctalia = pcall(require, "noctalia")
local palette = (ok_palette and type(noctalia) == "table" and noctalia.colors) or {}

-- Noctalia writes "rgb(rrggbb)"; Hyprland gradients need an alpha byte.
local function palette_rgba(role, alpha, fallback)
	local hex = tostring(palette[role] or ""):match("rgb%((%x+)%)")
	return "rgba(" .. (hex or fallback) .. alpha .. ")"
end

-- ═══ TUNING ═══════════════════════════════════════════════════════════
-- These are all still here and still tuned, but the APPLY block below currently has
-- the border, glow and visible shadow commented out. Uncomment there to bring any of
-- them back; the values don't need re-deriving.

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
	specular = "rgba(ffffff66)", -- hot spot; eased so the glow blends into it
	falloff = "rgba(ffffff40)", -- rolling away from the light
	shadow = "rgba(12141a66)", -- the far side, curved away from the light
	bounce = "rgba(ffffff0d)", -- faint bounce light returning on the far edge
}

-- Drop shadow. NOT optional: hyprglass force-enables decoration:shadow at plugin
-- load because it samples the shadow pass to get the correct background — but only
-- once, so a later `hyprctl reload` would turn it back off if the config said false.
-- Since it has to exist anyway, it may as well do useful work: offsetting it away
-- from the light is the cheapest way to sell a light source.
local shadow = {
	distance = 8, -- px the shadow is pushed away from the light
	range = 18, -- blur radius of the shadow itself
	render_power = 3,
	color = "rgba(0a0c12b3)",
}

-- Rotate the gradient continuously — a specular that travels around the pane, which
-- is the most "liquid glass" thing available. Only visible when BORDER_SIZE > 0.
local border_angle_animation = {
	enabled = true,
	speed = 100, -- deciseconds for a full rotation; higher = slower
	style = "loop",
}

-- Outer glow: light bleeding off the edge of the pane.
local glow = {
	enabled = true,
	range = 24, -- px
	render_power = 3, -- falloff exponent, same meaning as on shadows
}

-- Primary at the hot spot, secondary through the mid — a slight hue shift across the
-- ramp reads as dispersion rather than a flat wash. Far side fades to almost nothing:
-- glow is emitted light, so "shadowed" means absent, not dark.
local glow_colors = {
	palette_rgba("primary", "8c", "cfe4ff"),
	palette_rgba("secondary", "40", "cfe4ff"),
	palette_rgba("primary", "08", "cfe4ff"),
	palette_rgba("secondary", "1a", "cfe4ff"),
}

-- ═══ APPLY ════════════════════════════════════════════════════════════
-- CURRENTLY: all border decoration is OFF — no border, no glow, no visible shadow —
-- so every window looks identical and the only edge is hyprglass's own rim.
-- Everything below is left in place, commented, ready to switch back on.

local glow_ramp = { colors = glow_colors, angle = LIGHT_ANGLE }

local ramp = {
	-- Stops run in listed order around the angle: hot spot -> falloff -> dark far
	-- side -> faint bounce.
	colors = { rim.specular, rim.falloff, rim.shadow, rim.bounce },
	angle = LIGHT_ANGLE,
}

-- Shadow falls OPPOSITE the light. Hyprland's gradient angle and its screen
-- coordinates don't share an origin, so this is derived to look right rather than to
-- be trigonometrically pure: at LIGHT_ANGLE 45 (upper-left) it pushes the shadow
-- down and to the right. Flip a sign if you move the light past a quadrant.
local rad = math.rad(LIGHT_ANGLE)
local shadow_offset = { math.sin(rad) * shadow.distance, math.cos(rad) * shadow.distance }

hl.config({
	general = {
		-- Kept as an ACTIVE setting rather than commented out: Hyprland's own default
		-- is 1px, so commenting this would give every window a 1px border in the
		-- palette colour — the opposite of the intent.
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
			color = glow_ramp,
			color_inactive = glow_ramp,
		},

		-- `enabled` MUST stay true. hyprglass samples the shadow pass to get the
		-- correct background and force-enables this at load; with it off the glass
		-- samples wrongly. Its README is explicit that the VISUAL values may be zero
		-- ("only the decoration's presence matters"), so the shadow is present in the
		-- pipeline but draws nothing: zero range, zero offset, fully transparent.
		shadow = {
			enabled = true,
			range = 0,
			offset = { 0, 0 },
			color = "rgba(00000000)",
			color_inactive = "rgba(00000000)",

			-- The visible, light-following version:
			-- offset = shadow_offset,
			-- range = shadow.range,
			-- render_power = shadow.render_power,
			-- color = shadow.color,
			-- color_inactive = shadow.color,
		},
	},
})

-- Rotates the border gradient. Pointless while border_size is 0 — there is nothing
-- to rotate — so it's off too.
-- hl.animation({
-- 	leaf = "borderangle",
-- 	enabled = border_angle_animation.enabled,
-- 	speed = border_angle_animation.speed,
-- 	bezier = "linear",
-- 	style = border_angle_animation.style,
-- })
