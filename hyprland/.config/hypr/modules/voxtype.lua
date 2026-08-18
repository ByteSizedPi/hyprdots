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
-- ~/.config/voxtype/config.toml sets `[hotkey] enabled = false`, so this bind is
-- the only way to start a recording.
local PTT = "SUPER + D"

-- Press: start recording, then enter the submap so F12 can cancel.
hl.bind(PTT, function()
	hl.dispatch(hl.dsp.exec_cmd("voxtype record start"))
	hl.dispatch(hl.dsp.submap("voxtype_recording"))
end, { description = "voxtype: push-to-talk (hold)" })

-- Recording submap: active while voxtype records.
--
-- The release bind MUST be defined in here. Entering a submap deactivates the
-- default submap's binds, so a release bind left outside would never fire and
-- the recording would run until [audio] max_duration_secs (60s).
--
-- F12 cancels instead of transcribing. The generated .conf binds F12 twice
-- (exec, then submap reset); hl.bind takes one dispatcher per key, so one Lua
-- function does both.
hl.define_submap("voxtype_recording", function()
	hl.bind(PTT, function()
		hl.dispatch(hl.dsp.exec_cmd("voxtype record stop"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { release = true, description = "voxtype: stop and transcribe" })

	hl.bind("F12", function()
		hl.dispatch(hl.dsp.exec_cmd("voxtype record cancel"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "voxtype: cancel recording" })
end)

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
