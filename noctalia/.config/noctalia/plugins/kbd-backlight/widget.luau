--!nonstrict
-- Bar widget: click toggles the keyboard backlight, scroll steps it.
--
-- No update() here. The service already polls sysfs and publishes the level, so
-- this entry only redraws when that value changes.

local control = require("./lib/control.luau")

local showLevel = noctalia.getConfig("show_level")

local function render()
	if not control.available() then
		-- The LED is a laptop part. On a machine without it, hide the widget
		-- instead of drawing a control that cannot do anything.
		barWidget.setVisible(false)
		return
	end

	barWidget.setVisible(true)
	barWidget.setGlyph(control.isOn() and "keyboard" or "keyboard-off")

	if showLevel and control.maxLevel() > 1 then
		barWidget.setText(`{control.level()}/{control.maxLevel()}`)
	else
		barWidget.setText("")
	end

	barWidget.setTooltip(`{control.summary()}\nClick to toggle, right click to cycle, scroll to step`)
end

noctalia.state.watch("level", render)
noctalia.state.watch("max", render)
noctalia.state.watch("available", render)

-- The service may already have published a level before this widget loaded, and
-- watch() only fires on later changes.
render()

function onClick()
	control.toggle()
end

function onRightClick()
	control.cycle()
end

-- Scroll up raises the level. steps is negative for up, and one detent per notch,
-- so a level is taken per notch rather than per accumulated step count.
function onScroll(axis, steps)
	if axis ~= "vertical" then
		return
	end
	control.step(steps > 0 and -1 or 1)
end
