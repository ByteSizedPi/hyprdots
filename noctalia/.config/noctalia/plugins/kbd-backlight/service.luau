--!nonstrict
-- Publishes the keyboard backlight level for the widget and the shortcut.
--
-- Polling is not a shortcut here. The LED changes from three directions: this
-- plugin, the Fn key (the EC writes the level itself), and anything else that
-- calls brightnessctl. Only the first one could raise an event, so sysfs is the
-- one place that always tells the truth.

local control = require("./lib/control.luau")

local device = noctalia.getConfig("device") or "dell::kbd_backlight"
local base = `/sys/class/leds/{device}`
local pollMs = math.max(1, noctalia.getConfig("poll_seconds") or 2) * 1000

local maxLevel = nil
local lastOn = nil
local reading = false

local function toLevel(contents: string?): number?
	if contents == nil then
		return nil
	end
	local value = tonumber(noctalia.string.trim(contents))
	if value == nil then
		return nil
	end
	return math.floor(value)
end

-- last_on survives a restart so a toggle restores the level the user last chose,
-- not the default. pluginDataDir() is the directory Noctalia keeps across plugin
-- updates; pluginDir() is a runtime copy and would lose the file.
local function lastOnPath(): string?
	local dir = noctalia.pluginDataDir()
	if dir == nil then
		return nil
	end
	return `{dir}/last-on`
end

local function rememberLastOn(level: number)
	if level == lastOn then
		return
	end
	lastOn = level
	noctalia.state.set("last_on", level)
	local path = lastOnPath()
	if path ~= nil then
		noctalia.writeFile(path, tostring(level))
	end
end

local function publish(level: number)
	noctalia.state.set("level", level)
	if level > 0 then
		rememberLastOn(level)
	end
end

-- max_brightness is fixed for the life of the device, so it is read once, and
-- synchronously: the file is a constant the driver already holds.
local function probe()
	local contents = noctalia.readFile(`{base}/max_brightness`)
	maxLevel = toLevel(contents)
	if maxLevel == nil or maxLevel < 1 then
		noctalia.state.set("available", false)
		noctalia.log(`kbd-backlight: no usable LED at {base}`)
		return
	end
	if not noctalia.commandExists("brightnessctl") then
		noctalia.state.set("available", false)
		noctalia.notifyError("Keyboard Backlight", "brightnessctl is not installed")
		return
	end
	noctalia.state.set("max", maxLevel)
	noctalia.state.set("available", true)

	local path = lastOnPath()
	local saved = path ~= nil and toLevel(noctalia.readFile(path)) or nil
	if saved ~= nil and saved > 0 then
		lastOn = math.clamp(saved, 1, maxLevel)
		noctalia.state.set("last_on", lastOn)
	end
end

probe()

function update()
	noctalia.setUpdateInterval(pollMs)
	if maxLevel == nil or reading then
		return
	end
	-- brightness on dell-laptop is answered over SMBIOS, so the read can block for
	-- milliseconds. readFileAsync keeps that off the plugin worker.
	reading = true
	local queued = noctalia.readFileAsync(`{base}/brightness`, function(contents, _err)
		reading = false
		local level = toLevel(contents)
		if level ~= nil then
			publish(level)
		end
	end)
	if not queued then
		reading = false
	end
end

-- IPC lives on the service, not on the widget: a service is a singleton that runs
-- whenever the plugin is enabled, so a keybind works even with no widget on any
-- bar. Bind it in hyprland.conf:
--   bind = , XF86KbdBrightnessUp, exec, noctalia msg plugin jj/kbd-backlight:state all cycle
function onIpc(event, payload)
	if event == "toggle" then
		control.toggle()
	elseif event == "cycle" then
		control.cycle()
	elseif event == "on" then
		control.apply(control.onLevel())
	elseif event == "off" then
		control.apply(0)
	elseif event == "set" then
		local level = tonumber(payload)
		if level ~= nil then
			control.apply(level)
		else
			noctalia.log(`kbd-backlight: 'set' needs a numeric payload, got '{payload}'`)
		end
	else
		noctalia.log(`kbd-backlight: unknown ipc event '{event}'`)
	end
end

-- onConfigChanged() is deliberately not defined. Changing `device` invalidates
-- maxLevel and every cached value, and the host restarts a service that has no
-- handler, which re-runs probe() with the new setting.
