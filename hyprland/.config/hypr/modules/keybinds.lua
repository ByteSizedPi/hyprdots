local mainMod = "SUPER"
local terminal = require("lib.terminal")
local fileManager = "dolphin"

-- Terminal / apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
-- hl.bind(mainMod .. " + Q",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.layout("togglesplit"))

-- Noctalia shell UI
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"))
hl.bind(mainMod .. " + ALT + Escape", hl.dsp.exec_cmd("noctalia msg session lock"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind(mainMod .. " + Comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
-- hl.bind("ALT + Tab", hl.dsp.exec_cmd("noctalia msg window-switcher"))

-- Window focus (arrows and vim hjkl)
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))

-- Window move (Shift latches — carry window in the same direction)
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))

-- Monitor-scoped workspace navigation (Super+Alt tier: same monitor, adjacent
-- workspace). ws_step() copies the 3-finger swipe (modules/input.lua):
--   * It steps to the next workspace ID on the focused monitor. It does not wrap.
--   * Past the last workspace it creates a new one (first free ID above the
--     current one), the same as gestures:workspace_swipe_create_new.
--   * It does not create a new workspace from an empty one, so repeated presses
--     do not stack empty workspaces.
-- carry = true moves the focused window with you (Shift latches). A carry from a
-- workspace whose only window is the focused one does nothing at the right end,
-- because the result would be the same window alone on a new workspace.
-- Replaced 2026-11-09: the old binds used "m-1"/"m+1", which wrap around and
-- never create a workspace.
local function ws_step(dir, carry)
	return function()
		local mon = hl.get_active_monitor()
		local cur = mon and mon.active_workspace
		if not (cur and cur.id) then
			return
		end

		local used, target = {}, nil
		for _, ws in ipairs(hl.get_workspaces()) do
			if ws.id and ws.id > 0 and not ws.special then
				used[ws.id] = true
				if ws.monitor and ws.monitor.name == mon.name then
					local d = (ws.id - cur.id) * dir
					if d > 0 and (not target or d < (target - cur.id) * dir) then
						target = ws.id
					end
				end
			end
		end

		if not target then
			if dir < 0 then
				return
			end
			local win = carry and hl.get_active_window()
			if carry and not win then
				return
			end
			if cur.is_empty or (carry and #hl.get_workspace_windows(cur.id) <= 1) then
				return
			end
			target = cur.id + 1
			while used[target] do
				target = target + 1
			end
		end

		if carry then
			hl.dispatch(hl.dsp.window.move({ workspace = target }))
		else
			hl.dispatch(hl.dsp.focus({ workspace = target }))
		end
	end
end

hl.bind(mainMod .. " + ALT + h", ws_step(-1, false))
hl.bind(mainMod .. " + ALT + l", ws_step(1, false))

-- Carry window to adjacent workspace on same monitor (Shift latches)
hl.bind(mainMod .. " + ALT + SHIFT + h", ws_step(-1, true))
hl.bind(mainMod .. " + ALT + SHIFT + l", ws_step(1, true))

-- Workspace switch / move window
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("zellij"))
-- SUPER+A: unbound since 2026-10-07. Reach jjserver with ssh from SUPER+S.
hl.bind(mainMod .. " + Y", hl.dsp.workspace.toggle_special("youtube"))
hl.bind(mainMod .. " + B", hl.dsp.workspace.toggle_special("beeper"))

-- Window groups (tabs). SUPER+G makes the focused window a group, or ungroups it.
-- No bind switches group tabs since 2026-10-09: SUPER+Tab / SUPER+SHIFT+Tab moved
-- to monocle window cycling (modules/layouts.lua).
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots (via Noctalia)
-- Print draws a selection box. SHIFT + Print grabs the focused monitor whole.
hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))

-- Volume (via Noctalia OSD)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })

-- Brightness (via Noctalia OSD)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true })

-- Dictation: SUPER + D push-to-talk is in modules/voxtype.lua, not here. Its
-- release half has to be defined inside the voxtype_recording submap, so both
-- halves live with the submap.

-- Media (via Noctalia)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
