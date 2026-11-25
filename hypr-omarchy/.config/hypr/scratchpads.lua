-- Special-workspace scratchpads — home parity (hyprdots master:
-- hyprland/.config/hypr/modules/{scratchpads,specialbar,urgent}.lua and the
-- special-workspace gestures in modules/input.lua), adapted to Omarchy.
--
-- Keys are chosen to NOT collide with Omarchy's defaults (checked against
-- `hyprctl binds` on 2026-11-25):
--
--   home        here          why
--   SUPER+S     SUPER+Z       Omarchy owns SUPER+S (its own scratchpad) and SUPER+ALT+S
--   SUPER+Y     SUPER+Y       free (SUPER+SHIFT+Y is Omarchy's YouTube web app)
--   SUPER+Tab   ALT+Tab       Omarchy's ALT+Tab is cycle_next, which is exactly the
--                             monocle cycle; SUPER+Tab is Omarchy's next workspace
--
-- Bound with o.bind so they show up in Omarchy's keybindings menu.
-- on_created_empty runs the command the first time a scratchpad is summoned;
-- after that the window persists across toggles.

-- zellij: monocle, one foot window attached to the persistent `main` session.
-- Hardcoded to foot (Omarchy's terminal) because --app-id is terminal-specific.
-- Closing the window only detaches the zellij client; the session keeps running.
hl.workspace_rule({
  workspace = "special:zellij",
  layout = "monocle",
  on_created_empty = "foot --app-id=zellij-local --title=local zellij attach main --create",
})
o.window("^zellij-local$", { workspace = "special:zellij silent" })
o.bind("SUPER + Z", "Toggle zellij scratchpad", hl.dsp.workspace.toggle_special("zellij"))

-- YouTube Music: an Omarchy web app (Chromium --app) instead of home's Zen
-- profile. Chromium names the window class after the URL.
hl.workspace_rule({
  workspace = "special:youtube",
  on_created_empty = "omarchy-launch-webapp https://music.youtube.com",
})
o.window("^chrome-music\\.youtube\\.com.*", { workspace = "special:youtube silent" })
o.bind("SUPER + Y", "Toggle YouTube Music scratchpad", hl.dsp.workspace.toggle_special("youtube"))

-- Beeper (home: SUPER+B, x86_64 AppImage) is not set up here. SUPER+B is free.

-- Look (home specialbar.lua): no black dim layer; blur what is behind instead.
-- size/passes/xray are global, so they also apply to the bar/notification blur.
hl.config({
  decoration = {
    dim_special = 0,
    blur = { special = true, size = 10, passes = 3, xray = true },
  },
})

-- Gestures (home input.lua). Omarchy defines none, so nothing is shadowed.
-- ORDER MATTERS: Hyprland keeps the first gesture per finger count + direction,
-- so the SUPER-modded ones go before the plain one.

-- SUPER + 3-finger swipe up: toggle the zellij scratchpad.
hl.gesture({ fingers = 3, direction = "up", mods = "SUPER", action = "special", workspace_name = "zellij" })

-- SUPER + 3-finger swipe down: dismiss zellij only (the built-in action toggles,
-- which would summon it when hidden).
hl.gesture({
  fingers = 3,
  direction = "down",
  mods = "SUPER",
  action = {
    finish = function()
      local ws = hl.get_active_special_workspace()
      if ws and ws.name == "special:zellij" then
        hl.dispatch(hl.dsp.workspace.toggle_special("zellij"))
      end
    end,
  },
})

-- 3-finger swipe down: dismiss whichever special workspace is showing
-- (zellij, youtube, or Omarchy's own scratchpad). gsub returns two values,
-- hence the extra parentheses.
hl.gesture({
  fingers = 3,
  direction = "down",
  action = {
    finish = function()
      local ws = hl.get_active_special_workspace()
      if ws then
        hl.dispatch(hl.dsp.workspace.toggle_special((ws.name:gsub("^special:", ""))))
      end
    end,
  },
})

-- Notify when a window in a HIDDEN scratchpad asks for attention (home urgent.lua).
local keys = { zellij = "SUPER+Z", youtube = "SUPER+Y", scratchpad = "SUPER+S" }
local notified = {}

local function shell_quote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

hl.on("window.urgent", function(w)
  if not (w and w.address) then
    w = hl.get_urgent_window()
  end
  if not (w and w.workspace and w.workspace.name) then
    return
  end
  local ws = w.workspace.name
  if not ws:match("^special:") or notified[w.address] then
    return
  end
  for _, m in ipairs(hl.get_monitors()) do
    if m.active_special_workspace and m.active_special_workspace.name == ws then
      return
    end
  end
  notified[w.address] = true
  local name = ws:gsub("^special:", "")
  local body = (w.title or "") .. (keys[name] and ("  —  " .. keys[name]) or "")
  hl.exec_cmd("notify-send -a Hyprland " .. shell_quote(w.class .. " wants attention") .. " " .. shell_quote(body))
end)

hl.on("window.active", function(w)
  if w and w.address then
    notified[w.address] = nil
  end
end)
