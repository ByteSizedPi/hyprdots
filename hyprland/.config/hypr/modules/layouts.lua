-- Layouts. The global layout is scrolling (general.layout in modules/behaviour.lua).
-- Windows sit side by side on a horizontal strip, each column half the screen
-- wide by default. A new window adds a column on the right, and the strip scrolls
-- to keep the focused column in view. Workspace rules below override the layout
-- for one workspace each (Hyprland 0.54+).

local mainMod = "SUPER"

-- A layout message that the active layout does not know makes Hyprland show an
-- error ("no such layoutmsg for scrolling", reproduced 2026-10-09 with
-- cyclenext on a scrolling workspace). on(layout, msg) sends msg only when the
-- active workspace uses that layout. Otherwise the key does nothing.
-- A shown special workspace counts first, because hl.get_active_workspace()
-- still returns the normal workspace under it. tiled_layout is the field name,
-- checked live on 2026-10-09 (`layout` and `tiledLayout` are nil).
local function on(layout, msg)
	return function()
		local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
		if ws and ws.tiled_layout == layout then
			hl.dispatch(hl.dsp.layout(msg))
		end
	end
end

-- Scrolling binds.
-- Cycle the focused column width through scrolling.explicit_column_widths
-- (default 0.333, 0.5, 0.667, 1.0).
hl.bind(mainMod .. " + R", on("scrolling", "colresize +conf"))
hl.bind(mainMod .. " + SHIFT + R", on("scrolling", "colresize -conf"))
-- Swap the focused column with its neighbour.
hl.bind(mainMod .. " + CTRL + h", on("scrolling", "swapcol l"))
hl.bind(mainMod .. " + CTRL + l", on("scrolling", "swapcol r"))

-- Monocle binds: cycle the windows on a monocle workspace (SUPER+S zellij).
-- Hyprland wiki, Monocle Layout, "Quirks": hl.dsp.window.cycle_next() does not
-- work with monocle, so these use the layout messages.
hl.bind(mainMod .. " + Tab", on("monocle", "cyclenext"))
hl.bind(mainMod .. " + SHIFT + Tab", on("monocle", "cycleprev"))
