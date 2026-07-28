--!nonstrict
-- Theme switcher panel: apply a saved theme, update the current one, clone or
-- rename any of them, or bank the live look as a new theme.
--
-- A front-end for scripts/desktop-theme/{apply,save,clone,rename}.sh — deliberately
-- not a reimplementation. Those scripts validate the merged settings.toml in a
-- sandbox before installing it, stage writes so a failure can't leave a half-written
-- theme, and keep a .bak. Duplicating any of that here would mean two things to keep
-- in step, and this would be the copy that silently drifted. The panel only shells out.

local repo = noctalia.expandPath(noctalia.getConfig("repo") or "~/dotfiles")
local themesDir = repo .. "/themes"
local scripts = repo .. "/scripts/desktop-theme"
local confirmApply = noctalia.getConfig("confirm_apply")

local status = nil -- transient message under the list
local busy = false -- a script is running; gate every button
local pending = nil -- { kind = "apply"|"clone"|"rename", theme = <name> }
local pendingName = "" -- text buffer for the clone/rename input
local newName = "" -- text buffer for "save as"

local function currentTheme()
	local contents = noctalia.readFile(themesDir .. "/active")
	if not contents then
		return nil
	end
	local name = contents:gsub("%s+", "")
	return name ~= "" and name or nil
end

-- A theme is a directory with a noctalia.toml. That also filters out `active` (a
-- file), README.md, and `_base` (fragment sources, not a theme).
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

local render -- forward declaration; callbacks below re-render

-- Names are validated by the scripts (lowercase alnum/dash/underscore), so they're
-- shell safe by construction — quote anyway rather than depend on that holding.
local function shellQuote(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function run(cmd, okMessage)
	if busy then
		return
	end
	busy = true
	pending = nil
	status = "working…"
	render()

	noctalia.runAsync(cmd, function(result)
		busy = false
		if result.timedOut then
			status = "timed out"
			noctalia.notifyError("Theme Switcher", "Command timed out")
		elseif result.exitCode == 0 then
			status = okMessage
			noctalia.runAsync("noctalia msg plugin jj/theme-switcher:widget all refresh")
		else
			-- The scripts fail with useful text ("error: ..."); surface it rather
			-- than inventing a message. First line inline, full text in the notify.
			local why = result.stderr ~= "" and result.stderr or result.stdout
			status = (why:match("^[^\n]*") or "failed")
			noctalia.notifyError("Theme Switcher", why ~= "" and why or "Command failed")
		end
		render()
	end, 60000)
end

local function script(name)
	return shellQuote(`{scripts}/{name}`)
end

local function applyTheme(name)
	run(`{script("apply.sh")} {shellQuote(name)}`, `applied {name}`)
end

local function updateTheme(name)
	run(`{script("save.sh")} {shellQuote(name)} --force`, `updated {name}`)
end

local function cloneTheme(src, dst)
	run(`{script("clone.sh")} {shellQuote(src)} {shellQuote(dst)}`, `cloned {src} → {dst}`)
end

local function renameTheme(old, new)
	run(`{script("rename.sh")} {shellQuote(old)} {shellQuote(new)}`, `renamed {old} → {new}`)
end

local function saveAs(name)
	if name == "" then
		status = "give it a name first"
		render()
		return
	end
	run(`{script("save.sh")} {shellQuote(name)}`, `saved {name}`)
end

-- ── small building blocks ────────────────────────────────────────────────────
-- Every action is an icon button at the same controlSize, so the button column
-- lines up across rows without needing explicit widths.
local function iconButton(glyph, tooltip, onClick, variant)
	return ui.button({
		glyph = glyph,
		tooltip = tooltip,
		variant = variant or "ghost",
		controlSize = "sm",
		enabled = not busy,
		onClick = onClick,
	})
end

local function heading(text)
	return ui.label({
		text = text,
		fontSize = 11,
		fontWeight = "medium",
		color = "on_surface_variant",
	})
end

-- Shared by clone and rename: the row turns into an input with confirm/cancel.
local function editRow(name, kind)
	local confirmLabel = kind == "clone" and "Create the copy" or "Rename"
	return ui.row({ key = `edit-{name}`, align = "center", gap = 6 }, {
		ui.input({
			key = `edit-input-{name}-{kind}`,
			value = pendingName,
			placeholder = kind == "clone" and `copy of {name}` or `rename {name} to…`,
			flexGrow = 1,
			onChange = function(value)
				pendingName = value
			end,
			onSubmit = function(value)
				if kind == "clone" then
					cloneTheme(name, value)
				else
					renameTheme(name, value)
				end
			end,
		}),
		iconButton("check", confirmLabel, function()
			if kind == "clone" then
				cloneTheme(name, pendingName)
			else
				renameTheme(name, pendingName)
			end
		end, "primary"),
		iconButton("x", "Cancel", function()
			pending = nil
			render()
		end),
	})
end

local function themeRow(name, isCurrent)
	if pending and pending.theme == name and pending.kind ~= "apply" then
		return editRow(name, pending.kind)
	end

	local awaitingApply = pending and pending.theme == name and pending.kind == "apply"

	local actions = {}
	if awaitingApply then
		-- Applying replaces the whole theme surface including the wallpaper, so
		-- it's worth one deliberate second click.
		table.insert(actions, iconButton("check", `Apply {name} — replaces the wallpaper too`, function()
			applyTheme(name)
		end, "primary"))
		table.insert(actions, iconButton("x", "Cancel", function()
			pending = nil
			render()
		end))
	elseif isCurrent then
		-- The curate loop: tweak the live desktop, fold it back into this theme.
		table.insert(actions, iconButton("refresh", `Update {name} from the live look`, function()
			updateTheme(name)
		end, "primary"))
	else
		table.insert(actions, iconButton("player-play", `Apply {name}`, function()
			if confirmApply then
				pending = { kind = "apply", theme = name }
				render()
			else
				applyTheme(name)
			end
		end))
	end

	if not awaitingApply then
		table.insert(actions, iconButton("copy", `Clone {name}`, function()
			pending = { kind = "clone", theme = name }
			pendingName = ""
			render()
		end))
		table.insert(actions, iconButton("pencil", `Rename {name}`, function()
			pending = { kind = "rename", theme = name }
			pendingName = ""
			render()
		end))
	end

	local children = {
		-- A filled dot marks the applied theme; an outline keeps the names aligned.
		ui.glyph({
			name = isCurrent and "point-filled" or "circle",
			color = isCurrent and "primary" or "on_surface_variant",
		}),
		-- Only the applied theme sets fontWeight; the others take the default.
		-- ("bold" and "medium" are the values used across the official plugins —
		-- don't invent a third.)
		isCurrent and ui.label({ text = name, flexGrow = 1, color = "primary", fontWeight = "bold" })
			or ui.label({ text = name, flexGrow = 1, color = "on_surface" }),
	}
	for _, action in ipairs(actions) do
		table.insert(children, action)
	end

	return ui.row({ key = `row-{name}`, align = "center", gap = 6 }, children)
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
			ui.label({ text = "Themes", fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
			iconButton("x", "Close", function()
				panel.close()
			end),
		}),
		ui.label({
			text = current and `Applied: {current}` or "No theme applied",
			fontSize = 12,
			color = "on_surface_variant",
		}),

		ui.separator({}),
		ui.scroll({ flexGrow = 1, gap = 4, align = "stretch" }, rows),
		ui.separator({}),

		heading("SAVE THE LIVE LOOK AS A NEW THEME"),
		ui.row({ gap = 6, align = "center" }, {
			ui.input({
				key = "save-as",
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
				variant = "primary",
				controlSize = "sm",
				enabled = not busy,
				onClick = function()
					saveAs(newName)
				end,
			}),
		}),
	}

	if status then
		table.insert(body, ui.label({
			text = status,
			fontSize = 12,
			color = busy and "on_surface_variant" or "primary",
		}))
	end

	panel.render(ui.column({ flexGrow = 1, gap = 10, align = "stretch" }, body))
end

function onOpen(_context)
	-- Re-read from disk on every open: apply.sh may well have been run from a shell
	-- since this panel was last closed.
	status = nil
	pending = nil
	pendingName = ""
	busy = false
	render()
end
