--!nonstrict
-- Control center tile: one press toggles the keyboard backlight.
--
-- The tile is a plain on/off control. Levels between off and full are the bar
-- widget's job, because a tile has no scroll and no second gesture.

local control = require("./lib/control.luau")

local function render()
	local on = control.isOn()
	shortcut.setIcon("keyboard", "keyboard-off")
	shortcut.setActive(on)
	shortcut.setEnabled(control.available())

	if not control.available() then
		shortcut.setLabel("Keyboard")
	elseif on and control.maxLevel() > 1 then
		shortcut.setLabel(`Keyboard {control.level()}/{control.maxLevel()}`)
	else
		shortcut.setLabel(on and "Keyboard on" or "Keyboard off")
	end
end

noctalia.state.watch("level", render)
noctalia.state.watch("max", render)
noctalia.state.watch("available", render)

render()

function onClick()
	control.toggle()
end
