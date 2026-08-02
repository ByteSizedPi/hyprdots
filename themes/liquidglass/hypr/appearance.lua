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
		rounding = 20,
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

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
-- MUST match windowsIn/windowsOut below. `windows` is the reflow of existing
-- windows; if it is slower than the pop-in, a newly launched window finishes
-- appearing while its neighbours are still sliding, and they visibly overlap.
hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "quick", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "quick", style = "popin 80%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "quick" })
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
local translucent = {}

for class, opacity in pairs(translucent) do
	hl.window_rule({
		name = "translucent-" .. class,
		match = { class = class },
		opacity = opacity .. " override " .. opacity .. " override",
	})
end
