# System overview

What this machine is built from, how the pieces interact, and where their
config lives. Keep this current as the setup evolves.

## Base
- **OS:** Fedora Linux 44 (KDE Plasma Desktop Edition).
- **Machine:** Dell laptop (Dell Privacy Driver / Dell WMI hotkeys present),
  BOE internal panel (eDP-1, `0x0B8E`), often used with an AOC external monitor
  (HDMI-A-1, `24G2W1G3-`).
- **GPU: HYBRID.** Intel Arc (Meteor Lake-P, integrated) **+** NVIDIA RTX 500
  Ada (discrete). The internal panel runs off the Intel side (`/dev/dri/card1`,
  `intel_backlight`). Hybrid graphics + Wayland + DRM master is a recurring
  source of trouble — keep it in mind for any display issue.

## Two graphical sessions at once  ⚠️
The machine routinely runs **Plasma (Wayland)** and **Hyprland** *simultaneously*
on different VTs (e.g. Plasma on tty2, Hyprland on tty1). Only the foreground VT
holds **DRM master**; the backgrounded compositor cannot modeset/dpms until it's
foreground again. This dual-session arrangement is the leading suspect for
seat/DRM-master contention (see problems.md → "tty1 dead screen").

## Display manager
- **greetd** (enabled, active) is the login manager; `plasmalogin` is disabled
  but kept installed as fallback. `getty@tty2` is enabled as a recovery console.
  Details + reapply/rollback in [../SYSTEM.md](../SYSTEM.md).

## Compositor: Hyprland
- **Version 0.55.4**, **aquamarine** backend.
- **Lua config** (not the classic `hyprland.conf`). Entry: `hyprland.lua` →
  `require("monitors")`, `require("noctalia")`, plus `ui.lua`, `keybinds.lua`.
  Stow package: `hyprland/.config/hypr/`.
- **Lua-config gotchas for `hyprctl`:**
  - `hyprctl dispatch …` and `hyprctl keyword …` are rejected / lua-wrapped.
  - Use `hyprctl eval 'hl.dispatch(hl.dsp.<name>(...))'`. Dispatchers live under
    `hl.dsp` (e.g. `hl.dsp.focus({workspace=2})`, `hl.dsp.dpms("on")`,
    `hl.dsp.force_renderer_reload()`, `hl.dsp.exec_cmd("…")`).
  - Monitors are set with `hl.monitor({output=…, mode=…, position=…, scale=…})`
    (see `monitors.lua`), **not** `hyprctl keyword monitor`.
  - `hyprctl eval` prints `ok`/errors but **not** return values; enumerate a lua
    table by forcing its keys into an `error(...)` string.
  - Queries (`hyprctl monitors/clients/layers -j`, `reload`) work normally.
  - **Hyprland auto-reloads when a config file changes** — editing a `.lua` under
    `~/.config/hypr/` applies it immediately, no `hyprctl reload` needed. (Note
    `~/.config/hypr` is a *directory-level* stow symlink into the repo, so
    editing the file in `~/dotfiles/hyprland/…` is editing the live config.)
- **Log:** `/run/user/1000/hypr/<HIS>/hyprland.log` (HIS = instance signature,
  changes per launch; find via `ls /run/user/1000/hypr/`).

## Shell / desktop UI: noctalia
- `/usr/bin/noctalia` — a Quickshell-based shell providing **bar, wallpaper,
  notifications, OSD, idle management, and the lock screen** for Hyprland.
  Started as a daemon (`noctalia -d`); IPC via `noctalia msg <cmd>`
  (`caffeine-enable` inhibits idle; `dpms-on/off`; `session lock|suspend|…`).
- **Log: `~/.cache/noctalia/noctalia.log`** (+ rotated `.log.1`) — check this
  first when noctalia "crashes"; fatals and 100s-long main-loop stalls (DNS!)
  are recorded there. See problems.md → "noctalia idle stranded".
- **Config (stowed):** `~/.config/noctalia` → `noctalia/.config/noctalia/`.
  `config.toml` is a **user override merged over** the live settings.
- **Live settings (NOT stowed, GUI-managed):**
  `~/.local/state/noctalia/settings.toml` — holds idle behaviours, keybinds,
  wallpaper, lockscreen widgets, etc. Mirror any change here into the stowed
  `config.toml`.
- **Stability caveat:** noctalia has been observed **crash-looping** on this box
  (leaking layer surfaces with `pid:-1`). Its idle (lock/screen-off/
  lock-and-suspend) + a crash mid-sequence can strand the session — idle is
  currently disabled (see problems.md).

## Plasma / KDE
- `plasmashell` + `startplasma-wayland` present; Plasma Wayland is the "other"
  session. KDE is also the base desktop edition. `pam_kwallet5`/`ksecretd`
  interactions with session teardown drove the logind `KillUserProcesses=yes`
  change (see SYSTEM.md).

## Other moving parts
- **keyd** — key remapping daemon; shows up as "keyd virtual keyboard/pointer"
  in libinput. Relevant when debugging input.
- **kanshi** — stow package present but should stay **unused under Hyprland**:
  kanshi/shikane drive outputs via wlr-output-management, and Hyprland has a
  long-standing bug (hyprwm/Hyprland#1274) where a disabled head vanishes from
  the protocol's output list, so those tools can never re-enable it until a
  physical replug — docked↔mobile switching breaks. `monitors.lua` is the
  mechanism of record: four declarative `hl.monitor()` rules registered at
  config-parse time, which Hyprland applies natively on connect and hotplug.
  No daemon, no state, no logging — if a monitor is wrong, the rule is wrong.
  **Always pin `scale` to a number, never `"auto"`** (see `problems.md`).
- **Terminals/tools:** kitty (+ zellij multiplexer; zellij sessions **persist**
  across compositor restarts — reattach after), alacritty, nvim, yazi, btop,
  zen browser.

## Stow packages
`alacritty, btop, home, hyprland, kanshi, kitty, noctalia, nvim, scripts,
systemd, yazi, zellij, zen` — each `stow <pkg>` symlinks into `$HOME`.

## Out-of-tree changes
Tracked in [../SYSTEM.md](../SYSTEM.md): `/etc/systemd/logind.conf.d/…`
(KillUserProcesses), greetd switchover, `/etc/libinput/local-overrides.quirks`
(lid switch quirk).
