-- Voxtype dictation — push-to-talk keybind plus the two submaps that
-- `voxtype setup compositor hyprland` writes to conf.d/voxtype-submap.conf.
--
-- The .conf is dead weight here: a Lua config has NO source/include function
-- (the `hl` table has none — enumerate it with `hyprctl eval` if you doubt it),
-- so the "hyprland.conf does not source conf.d" warning cannot be satisfied and
-- must be ignored. This file is the replacement.
--
-- Why the trigger bind lives here and not in keybinds.lua: the RELEASE half has
-- to be defined inside the submap callback below. See the submap comment.

-- Hold this to dictate. voxtype does not grab a key itself —
-- voxtype/.config/voxtype/config.toml sets `[hotkey] enabled = false`, so this
-- bind is the only way to start a recording.
--
-- F13 is the physical Right Ctrl key. keyd remaps it in /etc/keyd/default.conf
-- (`rightcontrol = f13`, recorded in SYSTEM.md). No keyboard has a real F13 and
-- no application binds it, so grabbing it globally costs nothing.
--
-- IT MUST BE A BARE KEY. Measured on SUPER + D: the release bind fires only if D
-- is released BEFORE super. Release super first and it never fires, the recording
-- runs to the 60s limit, and the next press looks like a toggle. That is the
-- "SUPER+D works like a toggle" bug. A key with no modifier has no such order.
-- The physical Right Ctrl key. keyd rewrites it to F13 in /etc/keyd/default.conf
-- (`rightcontrol = f13`, recorded in SYSTEM.md), and this binds F13 by KEYCODE:
-- keyd emits Linux keycode 183, Hyprland takes xkb keycodes, which are Linux + 8.
--
-- IT MUST BE A BARE KEY. Measured on SUPER + D: the release bind fires only if D
-- is released BEFORE super. Release super first and it never fires, the recording
-- runs to the 60s limit, and the next press looks like a toggle. That was the
-- "SUPER+D works like a toggle" bug.
--
-- DO NOT "FIX" THIS BY NAME. `hl.bind("F13", ...)` is not equivalent: the US xkb
-- layout assigns no keysym above F12. And do not trust `hyprctl binds -j` here —
-- it reports a keycode bind as `key: ""`, `keycode: 0`, which looks dead and is
-- not. This exact misreading already caused one regression. Verify by dictating,
-- not by reading the bind table.
local PTT = "code:191"

hl.bind(PTT, hl.dsp.exec_cmd("voxtype record start"), {
	description = "voxtype: push-to-talk (hold)",
})

hl.bind(PTT, hl.dsp.exec_cmd("voxtype record stop"), {
	release = true,
	description = "voxtype: stop and transcribe",
})

hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("voxtype record cancel"), {
	description = "voxtype: cancel recording, discard audio",
})

-- Suppress submap: swallows the bare modifier keysyms while voxtype types the
-- transcription, so a held modifier cannot combine with the typed letters and
-- fire a keybind.
--
-- NOTHING ENTERS THIS SUBMAP. It is entered by voxtype's pre_output_command /
-- post_output_command hooks, and both are commented out in
-- ~/.config/voxtype/config.toml. voxtype's own comment says the workaround is
-- only needed when /dev/input is unreadable; it is readable here (user is in
-- the `input` group), so [output] wait_for_modifier_release handles the SUPER
-- still held down from the push-to-talk bind. Kept as the fallback for when
-- that stops being true. If you do enable the hooks, note that the documented
-- `hyprctl dispatch submap <name>` FAILS on a Lua config — they have to be:
--     pre_output_command  = "hyprctl eval 'hl.dispatch(hl.dsp.submap(\"voxtype_suppress\"))'"
--     post_output_command = "hyprctl eval 'hl.dispatch(hl.dsp.submap(\"reset\"))'"
--
-- Do NOT bind Escape in here. Binding Escape makes wtype drop its first
-- character (https://github.com/hyprwm/Hyprland/issues/3165).
--
-- The .conf uses `exec, true` per modifier. hl.dsp.no_op() is the same
-- consuming do-nothing bind without forking a process per keypress.
hl.define_submap("voxtype_suppress", function()
	for _, key in ipairs({
		"SUPER_L",
		"SUPER_R",
		"Control_L",
		"Control_R",
		"Alt_L",
		"Alt_R",
		"Shift_L",
		"Shift_R",
	}) do
		hl.bind(key, hl.dsp.no_op())
	end

	-- Emergency escape if voxtype crashes mid-output.
	hl.bind("F12", hl.dsp.submap("reset"), { description = "voxtype: escape suppress submap" })
end)
