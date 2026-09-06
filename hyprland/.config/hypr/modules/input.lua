hl.config({
	input = {
		kb_layout  = "us",
		kb_variant = "",
		kb_model   = "",
		kb_options = "compose:ralt",
		kb_rules   = "",
		numlock_by_default = true,

		follow_mouse = 1,
		sensitivity  = 0,

		touchpad = {
			natural_scroll = true,
		},
	},
})

-- Gestures. ORDER MATTERS: Hyprland keeps the FIRST gesture registered for a
-- given finger count + direction and refuses later ones ("Previous HORIZONTAL
-- shadows new HORIZONTAL"). Declare the specific (modded) gesture before the
-- general one.

-- SUPER + 3-finger horizontal swipe: swap the two monitors' workspaces.
--
-- `swap_monitors` is the Lua name for the `swapactiveworkspaces` dispatcher.
-- It takes a TABLE with named keys, not two positional strings:
--   hl.dsp.workspace.swap_monitors({ monitor1 = ..., monitor2 = ... })
-- "current" is the focused monitor, "+1" is the next one by monitor id. With
-- exactly two monitors "+1" is always the other one.
--
-- The callback key is `finish`, so one swipe makes one swap. `start` would
-- swap before any horizontal motion is measured, and `update` would toggle
-- back and forth for the whole swipe. The accepted keys are `start`, `update`
-- and `finish` only -- the compositor error message also lists `end`, but
-- `["end"]` is rejected (measured on 0.56.2).
--
-- The swap is symmetric, so a left swipe and a right swipe do the same thing.
-- `direction = "horizontal"` covers both.
hl.gesture({
	fingers   = 3,
	direction = "horizontal",
	mods      = "SUPER",
	action    = {
		finish = function()
			if #hl.get_monitors() < 2 then
				return
			end
			hl.dispatch(hl.dsp.workspace.swap_monitors({
				monitor1 = "current",
				monitor2 = "+1",
			}))
		end,
	},
})

-- Plain 3-finger horizontal swipe: move between workspaces.
hl.gesture({
	fingers   = 3,
	direction = "horizontal",
	action    = "workspace",
})

-- 3-finger swipe DOWN: dismiss whichever special workspace is showing.
--
-- The gesture does not name a scratchpad, so one swipe closes zellij, jjserver,
-- youtube or beeper — whichever is up. `hl.get_active_special_workspace()` returns
-- the special workspace on the focused monitor, or nil when none is showing, so a
-- swipe with nothing up is a no-op rather than an error.
--
-- Only one special workspace shows per monitor, which is what makes a single
-- unnamed gesture enough. See modules/scratchpads.lua for the scratchpads and
-- their SUPER key equivalents.
--
-- `toggle_special` wants the bare name, so strip the "special:" prefix that
-- `ws.name` carries. gsub returns TWO values (the string and a replacement count),
-- hence the extra parentheses -- passing it through unwrapped hands
-- toggle_special a second argument.
--
-- `finish` for the same reason as the swap gesture above: one swipe, one action.
-- `update` would toggle the workspace on and off for the whole length of the swipe.
hl.gesture({
	fingers   = 3,
	direction = "down",
	action    = {
		finish = function()
			local ws = hl.get_active_special_workspace()
			if not ws then
				return
			end
			hl.dispatch(hl.dsp.workspace.toggle_special((ws.name:gsub("^special:", ""))))
		end,
	},
})
