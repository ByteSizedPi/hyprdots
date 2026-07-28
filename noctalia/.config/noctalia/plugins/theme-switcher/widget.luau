--!nonstrict
-- Bar widget: shows the active theme, click to open the switcher panel.
--
-- The name comes from ~/dotfiles/themes/active, which every save.sh/apply.sh run
-- rewrites — so it's the one file that always tells the truth about what's applied,
-- and reading it is cheaper than asking any of the things a theme touches.

local repo = noctalia.expandPath(noctalia.getConfig("repo") or "~/dotfiles")
local activeFile = repo .. "/themes/active"

local function currentTheme()
	local contents = noctalia.readFile(activeFile)
	if not contents then
		return nil
	end
	local name = contents:gsub("%s+", "")
	if name == "" then
		return nil
	end
	return name
end

local function render()
	local name = currentTheme()
	barWidget.setGlyph("palette")
	if name then
		barWidget.setText(name)
		barWidget.setTooltip(`Theme: {name}\nClick to switch, save or update`)
	else
		-- reset.sh empties themes/active on purpose: no named theme is applied.
		barWidget.setText("—")
		barWidget.setTooltip("No theme applied (blank slate)\nClick to pick one")
	end
end

-- Polled rather than watched: themes/active is changed by shell scripts outside
-- this plugin, so there's no event to subscribe to. It's a single tiny read.
function update()
	noctalia.setUpdateInterval(5000)
	render()
end

function onClick()
	noctalia.runAsync("noctalia msg panel-toggle jj/theme-switcher:panel")
end

-- The panel fires this after an apply/save so the bar updates immediately instead
-- of waiting out the poll interval.
function onIpc(event, _payload)
	if event == "refresh" then
		render()
	end
end
