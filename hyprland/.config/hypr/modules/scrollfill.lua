-- Keep the scrolling strip filling the screen (added 2026-10-20).
--
-- Rule: unless a workspace is empty, tiled windows cover the full monitor width.
--
-- Hyprland 0.56.2 moves the scrolling view only on focus or scroll. A column
-- resize does not move it. Shrink the last column and its right edge moves left
-- while the view stays put, so the wallpaper shows until you pan. Tested on
-- workspace 2 on 2026-10-20: `move +200` shifts the windows 200 px right, and
-- `move -200` with a gap on the right does nothing.
--
-- settle() checks the focused monitor's workspace and applies two fixes:
--   1. Fill: the columns together are narrower than the screen, so
--      `fit expand` grows the focused window into the free space.
--   2. Gap: the strip is wider than the screen but stops short of an edge,
--      so `move +/-<px>` shifts the view to close the gap.
--
-- Hyprland has no resize event in Lua (see the hl.on list in docs/problems.md),
-- so a mouse resize (SUPER+right-drag, border drag) fires nothing. A 300 ms
-- repeating timer catches those. The timer only reads state and dispatches
-- only when it finds a gap.
--
-- hl.dispatch acts on the focused monitor, so the other monitor is corrected
-- when you focus it.

local M = {}

-- A window's `at`/`size` exclude the border, so an exact fit leaves
-- gaps_out + border_size (4 + 2 px here) at each edge. Anything up to TOL
-- beyond that counts as filled.
local TOL = 12

-- Last state we dispatched for, so a refused message is not sent every tick.
local last = nil

local function gaps()
	local g = hl.get_config("general.gaps_out")
	if type(g) == "table" then
		return g.left or 0, g.right or 0
	end
	return g or 0, g or 0
end

function M.settle()
	local m = hl.get_active_monitor()
	if not m then
		return
	end
	local ws = m.active_special_workspace or m.active_workspace
	if not ws or ws.tiled_layout ~= "scrolling" or ws.has_fullscreen then
		return
	end

	local left, right
	for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
		if not w.floating and not w.hidden and w.mapped then
			local x, wd = w.at.x, w.size.x
			left = (not left or x < left) and x or left
			right = (not right or x + wd > right) and x + wd or right
		end
	end
	if not left then
		return
	end

	local gl, gr = gaps()
	local border = hl.get_config("general.border_size") or 0
	local res = m.reserved
	local edge_l = m.x + res.left + gl + border
	local edge_r = m.x + m.width - res.right - gr - border

	local msg
	if (right - left) < (edge_r - edge_l) - TOL then
		msg = "fit expand"
	elseif right < edge_r - TOL then
		msg = string.format("move +%d", edge_r - right)
	elseif left > edge_l + TOL then
		msg = string.format("move -%d", left - edge_l)
	end

	if not msg then
		last = nil
		return
	end
	local key = ws.id .. ":" .. left .. ":" .. right .. ":" .. msg
	if key == last then
		return
	end
	last = key
	hl.dispatch(hl.dsp.layout(msg))
end

for _, ev in ipairs({ "window.open", "window.close", "window.active", "workspace.active" }) do
	hl.on(ev, function()
		-- Let the layout place the windows first.
		hl.timer(M.settle, { timeout = 50, type = "oneshot" })
	end)
end

hl.timer(M.settle, { timeout = 300, type = "repeat" })

return M
