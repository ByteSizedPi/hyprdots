--!nonstrict
-- Shared read/write helpers for the keyboard backlight LED.
--
-- The widget and the shortcut both need "what is the level" and "set the level".
-- They are separate VMs, so the code lives here and each entry requires its own
-- instance. The module holds no state: the level lives in noctalia.state, which
-- the service owns.

local M = {}

M.device = noctalia.getConfig("device") or "dell::kbd_backlight"

-- Level 0 is off. The maximum is device specific (2 on dell::kbd_backlight, so
-- the levels are off / half / full).
function M.level(): number
	return noctalia.state.get("level") or 0
end

function M.maxLevel(): number
	return noctalia.state.get("max") or 1
end

-- False until the service has read /sys/class/leds/<device>/max_brightness, and
-- for good if that read failed. Surfaces hide themselves rather than offer a
-- control that cannot work.
function M.available(): boolean
	return noctalia.state.get("available") == true
end

function M.isOn(): boolean
	return M.level() > 0
end

-- The level a toggle turns the light on to: the last level the service saw lit,
-- falling back to the default_level setting on a first run.
function M.onLevel(): number
	local remembered = noctalia.state.get("last_on")
	local fallback = noctalia.getConfig("default_level") or 1
	return math.clamp(remembered or fallback, 1, M.maxLevel())
end

-- Writing the LED needs root, so this goes through brightnessctl, which asks
-- systemd-logind. logind only grants that to the session on the active VT. On
-- this machine Hyprland and Plasma run on two VTs at once, so a click on the
-- background session fails with a polkit error rather than doing nothing.
function M.apply(target: number)
	if not M.available() then
		return
	end
	local level = math.clamp(math.floor(target), 0, M.maxLevel())

	-- Publish first. brightnessctl returns before logind has finished the write,
	-- so reading sysfs back here would race; the service poll confirms the real
	-- value within poll_seconds and overwrites this guess if it was wrong.
	noctalia.state.set("level", level)

	noctalia.runAsync({
		"brightnessctl",
		"--quiet",
		"--class",
		"leds",
		"--device",
		M.device,
		"set",
		tostring(level),
	}, function(result)
		if result.exitCode ~= 0 then
			local why = result.stderr ~= "" and result.stderr or result.stdout
			noctalia.notifyError("Keyboard Backlight", why ~= "" and why or "brightnessctl failed")
		end
	end)
end

function M.toggle()
	if M.isOn() then
		M.apply(0)
	else
		M.apply(M.onLevel())
	end
end

-- Step without wrapping: for scroll, where the ends of the range should stop.
function M.step(delta: number)
	M.apply(M.level() + delta)
end

-- Step with wrapping: for right click, where every level must be reachable from
-- repeated presses of one button.
function M.cycle()
	local next = M.level() + 1
	if next > M.maxLevel() then
		next = 0
	end
	M.apply(next)
end

function M.summary(): string
	if not M.available() then
		return `Keyboard backlight: {M.device} not found`
	end
	local level = M.level()
	if level == 0 then
		return "Keyboard backlight: off"
	end
	if M.maxLevel() > 1 then
		return `Keyboard backlight: level {level} of {M.maxLevel()}`
	end
	return "Keyboard backlight: on"
end

return M
