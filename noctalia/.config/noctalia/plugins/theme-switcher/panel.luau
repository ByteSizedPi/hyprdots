--!nonstrict
-- Theme switcher panel: apply a saved theme, update the current one, or bank the
-- live look as a new one.
--
-- This is a front-end for scripts/desktop-theme/{apply,save}.sh — deliberately not
-- a reimplementation. Those scripts validate the merged settings.toml in a sandbox
-- before installing it and keep a .bak; duplicating any of that here would mean two
-- things to keep in step. The panel only ever shells out.

local repo = noctalia.expandPath(noctalia.getConfig("repo") or "~/dotfiles")
local themesDir = repo .. "/themes"
local scripts = repo .. "/scripts/desktop-theme"
local confirmApply = noctalia.getConfig("confirm_apply")

local status = nil -- transient message shown under the list
local busy = false -- a script is running; gate the buttons
local pendingApply = nil -- theme awaiting confirmation
local newName = "" -- "save as" field contents

local function currentTheme()
	local contents = noctalia.readFile(themesDir .. "/active")
	if not contents then
		return nil
	end
	local name = contents:gsub("%s+", "")
	return name ~= "" and name or nil
end

-- A theme is a directory with a noctalia.toml. That check also filters out
-- `active` (a file), `README.md`, and `_base` (a fragment source, not a theme).
local function listThemes()
	local out = {}
	local entries = noctalia.listDir(themesDir)
	if not entries then
		return out
	end
	for _, entry in ipairs(entries) do
		local name = entry:match("([^/]+)$") or entry
		if name:sub(1, 1) ~= "_" and noctalia.fileExists(`{themesDir}/{name}/noctalia.toml`) then
			table.insert(out, name)
		end
	end
	table.sort(out)
	return out
end

local render -- forward declaration; the callbacks below re-render

-- Theme names are validated by save.sh as ^[a-z0-9][a-z0-9_-]*$, so they're shell
-- safe by construction — but quote anyway rather than rely on that holding.
local function shellQuote(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function run(cmd, okMessage)
	if busy then
		return
	end
	busy = true
	status = "working…"
	render()

	noctalia.runAsync(cmd, function(result)
		busy = false
		if result.timedOut then
			status = "timed out"
			noctalia.notifyError("Theme Switcher", "Command timed out")
		elseif result.exitCode == 0 then
			status = okMessage
			-- Nudge the bar widget rather than leaving it on its 5s poll.
			noctalia.runAsync("noctalia msg plugin jj/theme-switcher:widget all refresh")
		else
			-- The scripts fail loudly and usefully ("error: ..."), so surface that
			-- verbatim instead of inventing a message.
			local why = result.stderr ~= "" and result.stderr or result.stdout
			status = (why:match("^[^\n]*") or "failed")
			noctalia.notifyError("Theme Switcher", why ~= "" and why or "Command failed")
		end
		render()
	end, 60000)
end

local function applyTheme(name)
	pendingApply = nil
	run(`{shellQuote(scripts .. "/apply.sh")} {shellQuote(name)}`, `applied {name}`)
end

local function updateTheme(name)
	run(`{shellQuote(scripts .. "/save.sh")} {shellQuote(name)} --force`, `updated {name}`)
end

local function saveAs(name)
	if name == "" then
		status = "give it a name first"
		render()
		return
	end
	if not name:match("^[a-z0-9][a-z0-9_-]*$") then
		-- Mirror save.sh's own rule so the error arrives before the round trip.
		status = "lowercase letters, digits, - and _ only"
		render()
		return
	end
	run(`{shellQuote(scripts .. "/save.sh")} {shellQuote(name)}`, `saved {name}`)
end

local function themeRow(name, isCurrent)
	local label = ui.label({
		text = name,
		flexGrow = 1,
		color = isCurrent and "primary" or "on_surface",
		fontWeight = isCurrent and "bold" or "regular",
	})

	local buttons = {}
	if isCurrent then
		-- The whole point of the "curated set" workflow: tweak the live desktop,
		-- then fold those tweaks back into the theme you're already on.
		table.insert(
			buttons,
			ui.button({
				text = "Update",
				enabled = not busy,
				onClick = function()
					updateTheme(name)
				end,
			})
		)
	elseif pendingApply == name then
		table.insert(
			buttons,
			ui.button({
				text = "Sure?",
				enabled = not busy,
				onClick = function()
					applyTheme(name)
				end,
			})
		)
	else
		table.insert(
			buttons,
			ui.button({
				text = "Apply",
				enabled = not busy,
				onClick = function()
					if confirmApply then
						-- Applying replaces the wallpaper and the whole theme
						-- surface, so it's worth one extra click.
						pendingApply = name
						render()
					else
						applyTheme(name)
					end
				end,
			})
		)
	end

	return ui.row({ align = "center", gap = 8 }, { label, table.unpack(buttons) })
end

render = function()
	local themes = listThemes()
	local current = currentTheme()

	local rows = {}
	if #themes == 0 then
		table.insert(rows, ui.label({ text = `No themes found in {themesDir}`, color = "error" }))
	else
		for _, name in ipairs(themes) do
			table.insert(rows, themeRow(name, name == current))
		end
	end

	local body = {
		ui.row({ align = "center", justify = "space_between", gap = 8 }, {
			ui.label({ text = "Themes", fontSize = 16, fontWeight = "bold", flexGrow = 1 }),
			ui.button({ glyph = "close", onClick = function()
				panel.close()
			end }),
		}),

		ui.label({
			text = current and `Current: {current}` or "No theme applied",
			color = "on_surface_variant",
		}),

		ui.scroll({ flexGrow = 1, gap = 8, align = "stretch" }, rows),

		ui.separator({}),

		ui.label({ text = "Save the live look as a new theme", color = "on_surface_variant" }),
		ui.row({ gap = 8, align = "center" }, {
			ui.input({
				value = newName,
				placeholder = "new-theme-name",
				flexGrow = 1,
				onChange = function(value)
					newName = value
				end,
				onSubmit = function(value)
					saveAs(value)
				end,
			}),
			ui.button({
				text = "Save",
				enabled = not busy,
				onClick = function()
					saveAs(newName)
				end,
			}),
		}),
	}

	if status then
		table.insert(body, ui.label({ text = status, color = busy and "on_surface_variant" or "primary" }))
	end

	panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, body))
end

function onOpen(_context)
	-- Re-read from disk every open: apply.sh may well have been run from a shell
	-- since this panel was last closed.
	status = nil
	pendingApply = nil
	busy = false
	render()
end
