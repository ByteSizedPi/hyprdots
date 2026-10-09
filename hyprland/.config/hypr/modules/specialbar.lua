-- Special workspaces (SUPER+S, SUPER+Y, SUPER+B) look like their own screen:
--   1. an opaque background: the normal workspace behind does not show through.
--   2. the whole monitor: the Noctalia bar hides while one is showing.
--
-- Loaded from hyprland.lua AFTER the theme, because every theme sets
-- decoration.dim_special in theme/appearance.lua (mostly 0), which would
-- overwrite part 1.
--
-- Part 1: dim_special is the opacity of a black layer that Hyprland draws between
-- the normal workspace and a special workspace on top of it. 1 = solid black, so
-- the gaps and the unfilled parts of the groupbar show black instead of the
-- windows behind (2026-10-07; every theme had 0, fully see-through).
hl.config({
	decoration = {
		dim_special = 1,
	},
})

-- Part 2:
--
-- Why not a window rule: Noctalia draws the bar on the `top` layer, and Hyprland
-- draws tiled windows BELOW that layer. A window that grows into the bar's area
-- gets the bar drawn over it. Real fullscreen does draw above the bar, but it
-- also drops the group tab bar, the border and the gaps (tested 2026-10-07).
--
-- So instead: `noctalia msg bar-hide default <monitor>` hides the bar AND
-- releases its reserved space (measured: HDMI-A-1 reserved went 38 -> 0, and the
-- SUPER+S group moved up to the screen edge with its normal 4 px gap).
-- `bar-show` reverses it. Both are idempotent, unlike bar-toggle, so a missed or
-- doubled event cannot leave the bar in the wrong state.
--
-- `shown` remembers the last state sent per monitor, so the IPC runs only on a
-- real change. Several events trigger a sync, because I could not verify which
-- event fires when a special workspace is hidden.

local shown = {}

local function sync()
	for _, m in ipairs(hl.get_monitors()) do
		local special = m.active_special_workspace ~= nil
		if shown[m.name] ~= special then
			shown[m.name] = special
			local cmd = special and "bar-hide" or "bar-show"
			hl.exec_cmd("noctalia msg " .. cmd .. " default " .. m.name)
		end
	end
end

for _, ev in ipairs({ "workspace.special_active", "workspace.active", "monitor.focused", "config.reloaded" }) do
	hl.on(ev, sync)
end
