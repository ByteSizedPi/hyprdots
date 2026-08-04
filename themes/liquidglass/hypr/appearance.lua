-- liquidglass — Hyprland appearance.
--
-- Tuned for hyprglass. The important bit: WINDOWS MUST BE TRANSLUCENT. hyprglass
-- draws the glass slab *behind* the window surface, so a fully opaque window covers
-- it completely and you see nothing — the single most common "glass isn't working"
-- cause. But that translucency is the APPS' job, not Hyprland's; see the opacity
-- block below for why.
--
-- Owns ONLY appearance. Behaviour (layout, dwindle/master, misc, debug,
-- resize_on_border) lives in modules/behaviour.lua so swapping themes can't revert it.
-- Layer rules live in theme/layers.lua; border COLORS come from noctalia.lua.

hl.config({
	general = {
		-- Wider gaps than the flat themes: glass edges are the effect, and touching
		-- windows hide them.
		gaps_in = 2,
		gaps_out = 4,
		-- border_size is NOT here: all border settings live in theme/borders.lua,
		-- which runs after the palette and would override this anyway.
	},

	decoration = {
		-- Generous radius, and rounding_power 4.0 = a SQUIRCLE rather than a plain
		-- circular corner (1.0 triangular, 2.0 circular, up to 10.0). The flatter
		-- corner run gives hyprglass's edge refraction and chromatic aberration a
		-- longer arc to play along, which is where the effect is most visible.
		--
		-- 20 -> 30 on 2026-08-03. The two settings are independent: `rounding` is the
		-- corner radius in px, `rounding_power` is the exponent of the superellipse
		-- that fills it. Raising the radius alone therefore lengthens the squircle
		-- without making it circular — the shape is unchanged, there is just more of
		-- it. hyprglass agrees on the geometry: its shader takes both as uniforms and
		-- builds the same superellipse SDF (`lpNorm(q, roundingPower)`), so the glass
		-- boundary tracks this exactly rather than approximating it with a circle.
		--
		-- Hyprland clamps the radius to half the window's smallest dimension, so a
		-- short window quietly gets less than 30. Keep that in mind before blaming
		-- the theme for an inconsistent corner on a small floating window.
		rounding = 30,
		rounding_power = 4.0,

		-- FULLY OPAQUE, deliberately — and this is NOT the same as "no glass".
		--
		-- Hyprland's opacity applies to the ENTIRE window surface, and Hyprland has
		-- no idea which pixels are chrome. So a global 0.85 buys glass behind the
		-- terminal background at the price of dimming CONTENT too: video, photos,
		-- PDFs, maps all read as washed out. That was the 0.85 here until now.
		--
		-- The alpha therefore belongs one level down, in the apps, which DO know the
		-- difference. Everything glassy on this desktop already does it that way:
		--   kitty / alacritty  background_opacity  (themes/liquidglass/apps/)
		--   Zen                chrome panes only, content untouched
		--                      (dotfiles/zen/…/chrome/noctalia-transparency.css)
		-- Glass then shows through exactly those surfaces and nothing else — glassy
		-- browser chrome around a YouTube video that stays at full contrast.
		--
		-- Their values were re-derived so the look is UNCHANGED from the 0.85 era:
		-- each app now carries what it used to have multiplied by 0.85
		-- (0.62 -> 0.53 for the terminals, 80% -> 68% for Zen's tint).
		--
		-- Apps that can't do this themselves opt in via `translucent` at the bottom
		-- of this file.
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		dim_special = 0,
		dim_inactive = false,

		-- hyprglass force-enables shadows regardless (only their presence matters to
		-- it, not the values). Set explicitly so the config doesn't lie about state.
		-- hyprglass REQUIRES shadows to be enabled — it samples the shadow pass to get
		-- the correct background, and force-enables this at plugin load
		-- (src/main.cpp: "Shadows must be enabled for the glass effect to sample the
		-- correct background"). But it only does that ONCE, at load: any later
		-- `hyprctl reload` resets the value to whatever this file says. Setting it false
		-- here therefore broke the glass on every reload after the first.
		--
		-- The visual values live in theme/borders.lua, which runs later and overrides
		-- them, so that the shadow direction stays tied to LIGHT_ANGLE.
		shadow = {
			enabled = true,
		},

		-- Applies to layers glass doesn't own (screen corners). Glassed windows get
		-- `noblur` set automatically, so these values don't reach them.
		blur = {
			enabled = false,
			size = 8,
			passes = 3,
			special = false,
			xray = true,
			vibrancy = 0.17,
		},
	},

	animations = {
		enabled = true,
	},
})

-- ═══ BUBBLE CURVES ════════════════════════════════════════════════════
-- Windows open and close like a soap bubble being blown and popped. Two curves do
-- the whole job, because Hyprland has no keyframes: one bezier per animation, and
-- the only way to express "and then it comes back" is a control point OUTSIDE the
-- 0-1 box. Hyprland allows that — its own stock `overshot` curve ends at y = 1.1.
--
-- The bezier's y IS the animation progress, so y outside 0-1 means the window is
-- outside its target size. Combined with `popin`, that reads as physical volume:
--   y > 1  the window is BIGGER than its final size (inflated past the mark)
--   y < 0  the window is BIGGER than its start size (puffed up before collapsing)
--
-- A spring curve (`type = "spring"`) would give a real damped wobble instead of a
-- single overshoot, which is closer to how a bubble actually settles. Not used here:
-- the spring path is untested in this config (`easy` is defined below and never
-- referenced by any hl.animation call), and springs ignore the speed field, so it
-- would break the windows/windowsIn duration pairing documented further down.

-- INFLATE. Slow off the mark, because surface tension resists at the start, then a
-- fast expansion that carries ~18% past full size and snaps back. Stiff on
-- purpose: the control points sit early (x = 0.20 / 0.45), so almost all the
-- travel happens in the first third and the settle is over quickly. Raise the 1.18 for a fatter overshoot; past ~1.6 the swell stops
-- reading as stiff and starts reading as wobbly.
hl.curve("bubbleInflate", { type = "bezier", points = { { 0.20, 1.18 }, { 0.45, 1.0 } } })

-- DEFLATE. The mirror: y dips NEGATIVE early, so the window swells slightly before
-- it collapses. That anticipation is what sells a pop — a bubble distends just
-- before the film gives way. The dip is kept shallow (-0.18) and the second control
-- point is pulled back to x = 0.60, which makes the final collapse near-vertical:
-- a small tell, then gone.
hl.curve("bubbleDeflate", { type = "bezier", points = { { 0.45, -0.18 }, { 0.60, 0.0 } } })

-- The alpha half of the pop. Held near zero progress (= still opaque) for most of
-- the run, then off a cliff at the end. A bubble does not fade out; it is there and
-- then it is not, and the film stays visible right up to the burst. Pairing this
-- with bubbleDeflate is what makes the close read as "popped" instead of "shrank".
hl.curve("bubblePop", { type = "bezier", points = { { 0.6, 0.0 }, { 0.85, 0.15 } } })

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
-- MUST NOT be slower than windowsIn below. `windows` is the reflow of existing
-- windows; if it is slower than the pop-in, a newly launched window finishes
-- appearing while its neighbours are still sliding, and they visibly overlap.
-- It is held EQUAL to windowsIn here, which is the simplest way to satisfy that.
--
-- Deliberately NOT given a bubble curve. `windows` fires on every tiling reflow —
-- resize, move, workspace shuffle — and a desktop where each of those overshoots
-- and springs back is exhausting within a minute. Only the birth and death of a
-- window get the bubble; the ordinary rearranging stays calm.
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "easeOutQuint" })

-- BLOWN UP. `popin 5%` starts the window as a bead rather than at 80% of its final
-- size — at 80% there is nothing to inflate and the overshoot has no room to read.
-- Do not use 0%: the window starts with zero area, so hyprglass's bezelWidthPx
-- (edge_thickness x min dimension, see theme/glass.lua) is 0 on the first frame and
-- cornerSdf/0 is NaN, which flickers the rim.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "bubbleInflate", style = "popin 5%" })

-- POPPED. Faster than the inflate on purpose. Blowing a bubble is slow and bursting
-- one is not, and an unhurried close makes the desktop feel laggy.
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.8, bezier = "bubbleDeflate", style = "popin 5%" })

-- fadeIn front-loads the alpha: a bubble is a visible film from the instant it
-- exists, so the shape does the animating and opacity is out of the way early.
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "easeOutQuint" })

-- fadeOut is pinned to the SAME duration as windowsOut. Shorter and the window is
-- invisible while it is still collapsing; longer and a transparent ghost outlives
-- the shape. Either one breaks the pop.
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.8, bezier = "bubblePop" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- ═══ OPT-IN TRANSLUCENCY ══════════════════════════════════════════════
-- The escape hatch for apps that cannot make themselves translucent, and so would
-- otherwise get no glass at all now that the global opacity is 1.0.
--
-- ONLY list apps whose window is ALL CHROME. Hyprland's opacity is surface-wide, so
-- listing anything that displays video, photos, documents or maps re-creates exactly
-- the dimmed-content problem this file just got rid of — for that app instead of for
-- everything. A browser is never a candidate; make its chrome transparent from
-- inside the browser, the way dotfiles/zen/ does.
--
-- Keys are Hyprland REGEXes (`hyprctl clients` prints the class), values are alpha:
--
--   ["^org\\.gnome\\.Nautilus$"] = 0.88,
--
-- `override` on both entries stops the app's own alpha multiplying in on top, and
-- keeps focus from changing opacity — the focus cue here is the glass rim, not alpha.
--
-- MEASURE THE CLASS, DO NOT COPY IT FROM A COMMIT. The Noctalia entry below arrived
-- here from rules/windows.lua on 2026-08-03 with a class that no longer existed:
-- it matched `^dev\.noctalia\.Noctalia\.Settings$`, but `hyprctl clients` reports
-- `dev.noctalia.Noctalia` for that window. Noctalia dropped the `.Settings` suffix
-- at some point and the rule went silently dead — a window rule that matches nothing
-- produces no error, so the only symptom was an opaque Settings window with no glass.
local translucent = {
	-- The Noctalia Settings window — the only real WINDOW Noctalia has. Everything
	-- else it draws (bar, panels, notifications, OSD) is a layer surface and is
	-- glassed by namespace in theme/glass.lua instead.
	--
	-- Safe under the all-chrome rule, with one caveat: the Wallpaper tab shows image
	-- thumbnails, and Hyprland's opacity is surface-wide, so those thumbnails dim
	-- with the rest of the window. Settings controls are the other 95% of the
	-- window, so the trade is worth it here. Raise the alpha if the previews bother
	-- you; there is no way to exempt them.
	["^dev\\.noctalia\\.Noctalia$"] = 0.8,
}

for class, opacity in pairs(translucent) do
	hl.window_rule({
		name = "translucent-" .. class,
		match = { class = class },
		opacity = opacity .. " override " .. opacity .. " override",
	})
end
