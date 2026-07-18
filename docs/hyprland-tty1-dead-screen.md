# Hyprland tty1 "dead screen" — debugging log (2026-06-25)

Session where the Hyprland session on **tty1** showed nothing on the laptop
panel (eDP-1) — "screen totally off, not even black" — while a Plasma session
ran on **tty2**. Hyprland itself never died. We did **not** fully solve it;
user restarted. This logs what was ruled out, what was tried, and the leading
unresolved hypothesis so we start ahead next time.

## Environment
- Hyprland **0.55.4** (aquamarine backend), **Lua config** (`hyprland.lua` +
  `monitors.lua` etc.). `hyprctl dispatch` is lua-wrapped; use
  `hyprctl eval 'hl.dispatch(hl.dsp.<x>(...))'`.
- **Two graphical sessions at once**: Plasma on tty2 (active), Hyprland on tty1.
- Shell: **noctalia** (`/usr/bin/noctalia`) — bar + wallpaper + idle + lock.
- Monitors: eDP-1 (BOE, internal) + HDMI-A-1 (AOC, external, was plugged).

## Symptom
Switching to tty1 (Ctrl+Alt+F1) → laptop panel powered off. Numlock LED tracked
tty1's config (so Hyprland was alive and processing the VT switch). DPMS keys
did nothing. Briefly saw something "like a lockscreen-crashed screen."

## RULED OUT (with evidence)
- **Not a hung compositor** — Hyprland main thread idle in `ep_poll`, IPC fully
  responsive (`hyprctl version/monitors/reload` all work).
- **Not a real session lock** — 15k+ log lines, **zero** ext-session-lock
  events; `hyprctl` lock state = `none`. The `solitaryBlockedBy: session lock`
  string in `hyprctl monitors` is a **static label**, not live lock state.
  (Chased this hard twice; it's a red herring.)
- **Not backlight** — `intel_backlight` = 192000/192000 (max).
- **Not DPMS state in Hyprland's view** — `dpmsStatus: 0` (on) most of the time.
- **Not an empty/wallpaper-less workspace** — confirmed windows exist (Zen on
  ws2; two kitty/zellij in special workspaces `zellij`/`jjserver`). Switching
  workspaces via `hl.dispatch(hl.dsp.focus({workspace=N}))` worked.
- **Not the HDMI cable** — user unplugged it; kernel showed `disconnected`;
  problem persisted on eDP alone.

## TRIED — DID **NOT** fix the dead screen
- `hyprctl reload`, `force_renderer_reload`, `dpms off/on` cycles (via
  `hl.dsp.dpms("on")` / `hl.dsp.force_renderer_reload()`), explicit
  `hl.monitor({output="BOE 0x0B8E",...})` re-modeset — all return `ok`,
  Hyprland state looks correct, **panel stays dead**.
- **libinput lid quirk** (see below) + a live "eDP holder" watcher — screen
  still "dead dead" per user.
- Killing the (crash-looping) noctalia — cleared the broken "lockscreen" visual
  and leaked surfaces, but did **not** bring the panel back.

## WORKED / partial
- **Killing noctalia** removed the fake "lockscreen crashed" UI + 60+ leaked
  `pid:-1` layer surfaces. noctalia was genuinely crash-looping.
- **Caffeine** (`noctalia msg caffeine-enable`) stops its idle actions.
- Reading tty1's *real* monitor state requires tty1 to be **foreground** (only
  then does Hyprland hold DRM master). Backgrounded, all modeset/dpms IPC is a
  no-op. Pattern used: a background script that waits for
  `/sys/class/tty/tty0/active == tty1`, then fires + captures the log delta.

## Root-cause candidates
1. **noctalia idle + crashes (the ORIGINAL trigger).** Idle config (in
   `~/.local/state/noctalia/settings.toml`) had all enabled:
   `lock`@600s, `screen-off`@660s, `lock-and-suspend`@900s. tty1 went idle →
   noctalia locked + screen-offed → noctalia crashed → nothing left to turn the
   screen back on. **Action item: tame this before relaunching noctalia.**
2. **Lid switch disabling eDP.** Log shows, on every VT switch:
   `New device Lid Switch` → `Restoring crtc 149 … 1920x1080@60` →
   `drm: Disabling output eDP-1`. ACPI said lid **open**. Applied a libinput
   `write_open` quirk (logged in SYSTEM.md). **Inconclusive** — see contradiction.
3. **★ LEADING UNRESOLVED — seat/DRM-master flapping.** Log has **228×
   `Session inactive`** and repeated `[libseat] Enabling seat`. Running **two
   graphical sessions** (Plasma tty2 + Hyprland tty1) may be fighting over the
   seat / DRM master, so tty1's display never stabilizes. Also earlier:
   `atomic drm request: failed to commit: Invalid argument (EINVAL)` (line
   ~10838, during the HDMI-0x0 period).

## THE KEY CONTRADICTION (start here next time)
At the end, the eDP "holder" logged **0 re-enables** over ~6 min: Hyprland
reported eDP **`disabled: false` + `dpmsStatus: 0` (on)** the whole time, the
modeset succeeded in the log — **yet the panel was physically dead.**
→ The dead screen is **NOT** explained by Hyprland's enable/dpms state. The
failure is **below** Hyprland's reported state: actual DRM scanout / atomic
commit not reaching the panel. Combined with #3, suspect **seat/DRM-master
contention from the dual Plasma+Hyprland sessions** rather than lid/dpms/lock.

## Recommended next steps
- **Reproduce with only ONE graphical session** (no Plasma on tty2) to test the
  seat-contention hypothesis. If tty1 Hyprland is fine alone → it's seat/DRM
  master fighting.
- Capture `dmesg`/`drm` (needs root) during a VT switch — look for atomic
  commit **EINVAL** on eDP-only, and i915 errors. We couldn't read dmesg
  (restricted) this session.
- Check whether `atomic drm request: failed to commit` recurs on **eDP-only**
  (it was seen during HDMI-0x0; unknown if it persists alone).
- Tame noctalia idle (lengthen/disable `lock`/`screen-off`/`lock-and-suspend`)
  and investigate why noctalia crash-loops on this box.
- If lid quirk proves it's NOT the lid (likely, given the contradiction),
  consider reverting it; the stronger lid option (udev `LIBINPUT_IGNORE_DEVICE`)
  is noted in SYSTEM.md but probably not the real fix.

## Useful commands / facts for next time
- HIS this session: `a0136d8c04687bb36eb8a28eb9d1ff92aea99704_1782399729_1394719522`
  (changes per launch; find via `ls /run/user/1000/hypr/`).
- Hyprland log: `/run/user/1000/hypr/<HIS>/hyprland.log`.
- `hyprctl eval` does **not** print return values (only `ok`/errors). Enumerate
  lua tables by forcing them into an `error(...)` string.
- Dispatcher tree top level: `exec_cmd event pass cursor exec_raw send_key_state
  exit focus submap group send_shortcut layout dpms no_op force_idle workspace
  window global force_renderer_reload`.
