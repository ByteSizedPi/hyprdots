-- Layouts. The global layout is scrolling (general.layout in modules/behaviour.lua).
-- Windows sit side by side on a horizontal strip, each column half the screen
-- wide by default. A new window adds a column on the right, and the strip scrolls
-- to keep the focused column in view. Workspace rules below override the layout
-- for one workspace each (Hyprland 0.54+).

local mainMod = "SUPER"

-- Scrolling binds. On a workspace with another layout these do nothing.
-- Cycle the focused column width through scrolling.explicit_column_widths
-- (default 0.333, 0.5, 0.667, 1.0).
hl.bind(mainMod .. " + R", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.layout("colresize -conf"))
-- Swap the focused column with its neighbour.
hl.bind(mainMod .. " + CTRL + h", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.layout("swapcol r"))

-- Monocle binds: cycle the windows on a monocle workspace (SUPER+S zellij).
-- Hyprland wiki, Monocle Layout, "Quirks": hl.dsp.window.cycle_next() does not
-- work with monocle, so these use the layout messages. On a workspace with
-- another layout these do nothing.
hl.bind(mainMod .. " + Tab", hl.dsp.layout("cyclenext"))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.layout("cycleprev"))
