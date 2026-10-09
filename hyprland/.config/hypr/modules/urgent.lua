-- TRIAL 2026-10-08: notify when a window in a HIDDEN special workspace asks for
-- attention (Hyprland Lua events, window.urgent).
--
-- An app marks its window urgent when it wants attention: Beeper on a new
-- message, a terminal on a bell. Hyprland only shows that on the window itself,
-- and a scratchpad (SUPER+S / Y / B) is hidden most of the time, so the signal
-- was never seen. This hook sends a desktop notification (shown by Noctalia)
-- that names the app and the key that opens it.
--
-- Windows on normal workspaces are ignored: there the urgent hint already shows.
-- Only one notification per window until it is focused again, so a chatty app
-- cannot flood the screen.

local keys = { zellij = "SUPER+S", youtube = "SUPER+Y", beeper = "SUPER+B" }
local notified = {}

local function shell_quote(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

hl.on("window.urgent", function(w)
	-- The event passes the window. Fall back to the query API if it does not.
	if not (w and w.address) then
		w = hl.get_urgent_window()
	end
	if not (w and w.workspace and w.workspace.name) then
		return
	end
	local ws = w.workspace.name
	if not ws:match("^special:") or notified[w.address] then
		return
	end
	-- Showing is fine: the special workspace may be visible on its monitor.
	for _, m in ipairs(hl.get_monitors()) do
		if m.active_special_workspace and m.active_special_workspace.name == ws then
			return
		end
	end
	notified[w.address] = true
	local name = ws:gsub("^special:", "")
	local body = (w.title or "") .. (keys[name] and ("  —  " .. keys[name]) or "")
	hl.exec_cmd("notify-send -a Hyprland " .. shell_quote(w.class .. " wants attention") .. " " .. shell_quote(body))
end)

hl.on("window.active", function(w)
	if w and w.address then
		notified[w.address] = nil
	end
end)
