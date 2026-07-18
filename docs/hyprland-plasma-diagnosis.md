# Hyprland + Plasma diagnosis knowledge base

Single source of truth for the recurring Hyprland/Plasma issues on this machine, so
diagnosis doesn't start from scratch each time. Companion to `SYSTEM.md` (the actual
system changes) and `bugreport-hyprland-dwindle.md` (the upstream crash report).

Last updated: 2026-06-25.

---

## Hardware / platform (relevant to all of this)

```
Machine:  laptop (BOE eDP-1 internal panel, 1920x1080@60)
OS:       Fedora Linux 44 (KDE Plasma Desktop Edition)
Kernel:   7.0.12-201.fc44.x86_64
GPU:      HYBRID —
            card1 = Intel Arc Graphics (Meteor Lake-P), driver i915, PCI 0000:00:02.0  ← drives the display (eDP-1)
            card0 = NVIDIA RTX 500 Ada Laptop,          driver nvidia, PCI 0000:01:00.0 ← dGPU
Compositor: Hyprland 0.55.4 (COPR lionheartp/Hyprland), Lua config, launched via uwsm
DM:       plasma-login-manager (pkg plasma-login-manager 6.7.0; binary /usr/bin/plasmalogin)
            greeter compositor = kwin_wayland
Shell/UI: noctalia (bar, wallpaper, notifications, lockscreen, etc.)
```

### DRM debugfs node map (need `sudo` to read)
- `/sys/kernel/debug/dri/128` = **i915 (the display)** — this is where the framebuffers/planes live.
- `/sys/kernel/debug/dri/129` = nvidia.
- `/sys/kernel/debug/dri/0`, `/1` = render/legacy symlinks. Minor numbers can shift across boots — confirm with `ls /sys/class/drm/card*/device/uevent`.

---

## ISSUE 1 — Plasma greeter "ghost" overlay (the painful recurring one)

### Symptom
A faint image of the Plasma login screen stays composited over the Hyprland desktop
after login. **Happens on every boot** (confirmed: appears on a clean reboot with no
prior Hyprland crash — so it is NOT caused by Issue 2). Invisible to all userspace
checks: no greeter process, no DRM client, nothing in `hyprctl clients`/`layers`.

### Root cause (confirmed)
plasma-login-manager's `kwin_wayland` greeter, when it hands off to Hyprland, leaves
its framebuffer bound to a **hardware overlay plane** (observed: `plane 5A` on `pipe A`,
format AR24/ARGB). Hyprland's atomic commits only ever set the planes **it** owns
(primary `1A` + cursor), so it never disables the orphaned overlay. The GPU keeps
scanning out the dead greeter buffer, blended on top of the desktop.

### How to detect (the only reliable way — kernel DRM layer)
```sh
# orphaned greeter framebuffer still allocated:
sudo grep -A1 'kwin_wayland' /sys/kernel/debug/dri/128/framebuffer
# ...and still bound to an active plane on a pipe:
sudo grep -A2 'plane 5A' /sys/kernel/debug/dri/128/state    # crtc=pipe A + fb=<id> == still scanning out
# CLEARED state shows: crtc=(null) and fb=0, and no kwin_wayland framebuffers.
```

### What does NOT clear it (all tested live, all fail — do not waste time retrying)
Hyprland only commits planes it owns, so nothing inside the compositor disables the orphan:
- `hyprctl dispatch 'hl.dsp.dpms({ action = "disable"/"enable" })'` — no effect on the plane.
- `hyprctl reload` — no effect on the plane.
- `hl.monitor({ output = "eDP-1", disabled = true })` then re-enable — no effect on the
  plane, **and it black-screens the display** (the `disabled` flag sticks; only a full
  `hyprctl reload` re-reading monitors.lua brings it back — `disabled=false` via eval does NOT).
- `chvt` to an **empty** VT — no effect (an empty VT triggers no modeset; fbcon here is a
  "(S) dummy device").
- logind `SwitchTo` to an **empty** VT — no effect (same reason).

### What DOES clear it (confirmed)
An **external full modeset**. Switching to a VT that has an **active console (a getty)**
forces the i915 fbdev modeset that resets ALL planes; then switching back, Hyprland
re-establishes on a clean CRTC. Empty VTs do not work — there must be a live getty there.
```sh
# manual one-shot fix (cur = Hyprland's VT):
sudo systemctl start getty@tty8 && sudo chvt 8 && sleep 1 && sudo chvt <cur>
```

### Underlying defect
This is an **upstream aquamarine + Intel i915 bug**: aquamarine (Hyprland's KMS backend)
does not reset/disable the plane state it inherits from the previous KMS client on startup.
Same class as aquamarine issue #307 (i915 display-state mishandling). No Hyprland config or
env var fixes it (`AQ_NO_ATOMIC` is a degradation for other symptoms, not this).

### Fix (implemented 2026-06-25): replace the compositor-based greeter
Switched the display manager from **plasma-login-manager** (whose `kwin_wayland` greeter
leaks the plane) to **greetd + tuigreet**. tuigreet runs on the console TTY with **no
Wayland compositor**, so there is no overlay plane to leak — the root cause is gone, not
worked around. See SYSTEM.md ("Display manager: greetd + tuigreet") for the full setup.

### Rejected / superseded approaches (don't redo)
- **VT-switch workaround** (scratch `getty@tty8` + sudoers + autostart `clear-greeter-ghost.sh`
  doing `chvt` to a live-getty VT and back): worked but hacky (login flicker, sudo, scratch
  getty). **Removed** when greetd+tuigreet replaced it. The clearing mechanism it relied on:
  only switching to a VT with an *active* console forces the i915 modeset that resets planes;
  empty VTs do nothing.
- **gtkgreet / ReGreet** (graphical greeters): run inside their own compositor (`cage`), i.e.
  another KMS handoff that could reintroduce the same ghost. Avoided for that reason; tuigreet
  (no compositor) is the safe choice. ReGreet also isn't packaged in Fedora 44.

---

## ISSUE 2 — Hyprland SIGSEGV on shutdown (dwindle + special workspace)

Separate from the ghost (ghost happens without any crash). Full writeup in
`bugreport-hyprland-dwindle.md`. Summary:

- **Crash:** on exit, `main` → `CCompositor::cleanup()` → a special-workspace window
  unmaps → `setSpecialWorkspace` → `CDwindleAlgorithm::calculateWorkspace` →
  `ITarget::setPositionGlobal` on freed state → SIGSEGV. Use-after-free during teardown.
- **Trigger:** windows present in special workspaces (`special:zellij`, `special:jjserver`)
  at exit. noctalia logout uses `hyprctl dispatch exit`, so logout hits it.
- **Downstream:** xdph then segfaults in its atexit destructor; the failed exit is why
  the greeter comes back (and re-leaks the plane — see Issue 1).
- **Mitigation applied:** switched layout from `dwindle` to `master` in `ui.lua` (crash is
  entirely inside `CDwindleAlgorithm`). Do NOT add `Restart=on-failure` to
  `wayland-wm@hyprland.desktop.service` — it breaks logout (see SYSTEM.md).
- **Upstream:** same bug as #15096 (0.55.2) and #13778 (0.54.2), both closed *not planned*
  for lack of a reliable repro. Ours is 100% reproducible. 0.55.4 is the latest release.

---

## Hyprland Lua-config gotchas (0.55+; hyprlang deprecated in favour of Lua)

This is a **Lua-config** Hyprland. Classic hyprlang syntax/commands often fail:

- `hyprctl keyword ...` → **fails**: "keyword can't work with non-legacy parsers. Use eval."
- Runtime config changes: use `hyprctl eval '<lua>'`, e.g.
  `hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = false, mode = "preferred", position = "0x0", scale = 1 })'`
- Dispatchers go through `hl.dispatch(...)`. Confirmed forms (verified live on 0.55.4):
  - dpms: `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` / `{ action = "enable" }`
  - plain string dispatchers fail; the Lua API wants `hl.dsp.*` objects (e.g. `hl.dsp.window.close()`).
- `hl.monitor` fields: `output` (NOT `name`), `disabled` (NOT `enabled`), `mode`, `position`, `scale`.
- Config files use `hl.config{...}`, `hl.monitor{...}`, `hl.bind(...)`, `hl.dsp.*`.

### Instance-signature gotcha (bit us repeatedly)
Each new shell does NOT inherit the live `HYPRLAND_INSTANCE_SIGNATURE` — the Claude/CLI
session was launched under an **older** Hyprland instance, so the inherited value is STALE
and `hyprctl` talks to a dead socket. Also there are often multiple stale socket dirs in
`/run/user/1000/hypr/`. Always detect the LIVE one:
```sh
LIVE=$(for d in /run/user/1000/hypr/*/; do s=$(basename "$d"); \
  HYPRLAND_INSTANCE_SIGNATURE="$s" hyprctl version >/dev/null 2>&1 && echo "$s"; done | head -1)
export HYPRLAND_INSTANCE_SIGNATURE="$LIVE"
```

---

## Quick diagnosis cheat-sheet

```sh
# live Hyprland signature (see above), then:
hyprctl monitors            # dpmsStatus, disabled, mode, focused
hyprctl clients ; hyprctl layers

# greeter ghost — kernel DRM layer (sudo):
sudo grep -A1 kwin_wayland /sys/kernel/debug/dri/128/framebuffer
sudo grep -A2 'plane 5A'   /sys/kernel/debug/dri/128/state

# VTs / sessions:
cat /sys/class/tty/tty0/active                 # active VT
loginctl list-sessions ; loginctl session-status <id>
for t in 1 2 3 4 5 6 8; do echo -n "tty$t: "; sudo fuser /dev/tty$t 2>/dev/null; echo; done

# crashes:
coredumpctl list --since today
coredumpctl info <pid|/usr/bin/Hyprland>
systemctl --user list-units --state=failed
```
