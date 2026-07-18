--[[
  monitors.lua — monitor layout.

  These are RULES, not commands. Called here at config-parse time, Hyprland
  stores them and applies the matching one whenever an output connects —
  at startup and on every hotplug. That timing is the whole point: see below.

  Layout is simply "laptop on the left, external on the right". Each monitor's
  spec is independent of which others are plugged in, so no profile matching,
  no hotplug handling, no state — Hyprland does all of it natively.

  *** Do NOT set scale to "auto" here. ***
  Auto-scale picks 1.5 for eDP-1, which (a) looks wrong and (b) makes the panel
  1280 logical px wide instead of 1920, so the external monitor at 1920x0
  leaves a 640px gap. Positions are in LOGICAL pixels: next_x = width / scale.

  History (2026-07-18): this file used to be a 361-line kanshi-style engine
  that applied monitor settings from a deferred timer, i.e. AFTER the backend
  had already enumerated outputs. Hyprland only honours `scale` when an output
  connects, so every one of those late calls was silently ignored and eDP-1
  stayed at auto-scale 1.5. The engine grew a detect-and-recover loop that
  disable/enable-cycled the output to force a reconnect — which worked, but
  visibly glitched the screen a second into each session. All of that was
  compensation for applying the rules too late. Declaring them here, at parse
  time, means the scale is simply right on first connect. Don't reintroduce
  runtime monitor logic unless a layout genuinely depends on what else is
  plugged in — and check `git log` for this file first.

  Add a monitor: copy a line. Find `output` values with `hyprctl monitors`
  ("desc:" matches any unique substring of the description).
  Modes: explicit "1920x1080@144" beats "preferred" — preferred picks 48Hz on
  eDP-1 and 60Hz on the AOC.
]]

-- Built-in laptop panel, top-left origin.
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

-- Home: AOC 24G2W1G3, to the right of the laptop. @144 — its EDID preferred
-- mode is only 60Hz.
hl.monitor({ output = "desc:AOC 24G2W1G3", mode = "1920x1080@144", position = "1920x0", scale = 1 })

-- Docked: Samsung LS27C31x, same slot to the right (never connected at the
-- same time as the AOC, so sharing the position is fine).
hl.monitor({
	output = "desc:Samsung Electric Company LS27C31x",
	mode = "1920x1080",
	position = "1920x0",
	scale = 1,
})

-- Catch-all for anything not named above: native resolution, placed to the
-- right, scale 1. Keep LAST. An unknown monitor comes up usable rather than
-- dark. (Hyprland's documented empty-output fallback rule.)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
