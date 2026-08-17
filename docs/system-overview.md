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
- **Version 0.56.0**, **aquamarine** backend.
- **Lua config** (not the classic `hyprland.conf`). Stow package:
  `hyprland/.config/hypr/`, laid out as `modules/` (hand-written, one concern per
  file), `rules/`, `lib/` and `theme/` (everything generated), with `hyprland.lua`
  as a bare require list. The directory has its own
  [README](../hyprland/.config/hypr/README.md) documenting which files are written
  by Noctalia and by the theme scripts — read it before moving anything.
- **Plugins are loaded by hyprpm**, not by the config: `hl.plugin.load()` reports
  success and does nothing on 0.56.0. Because hyprpm runs *after* the config is
  parsed, `modules/plugins.lua` triggers a `hyprctl reload config-only` once it
  finishes, or no plugin config would apply on a cold start. Enabled plugins live
  in `/var/cache/hyprpm/$USER/`, outside this repo.
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
- **Config precedence (measured 2026-07-27, NOT what this doc used to claim):**

  | layer | wins? |
  | --- | --- |
  | `~/.local/state/noctalia/settings.toml` (GUI-managed, **not** stowed) | **yes, per key** |
  | `~/.config/noctalia/config.toml` (stowed) | only for keys settings.toml omits |
  | built-in defaults | last |

  `config.toml` is a **fallback layer *underneath*** the live settings, not an
  override on top. To change the running system, edit `settings.toml` or use the
  GUI; `config.toml` is the **fresh-machine seed**. Verify with
  `noctalia config export merged`. Only `config.toml` and `user-templates.toml`
  are read from the config dir — extra `*.toml` files there are ignored.
- **Live settings (NOT stowed, GUI-managed):**
  `~/.local/state/noctalia/settings.toml` — idle behaviours, keybinds, wallpaper,
  lockscreen widgets, and the whole theme surface.
- **`~/.local/state/noctalia/state.toml` holds live Google OAuth access + refresh
  tokens.** Never commit, sync, or paste it.
- **Useful CLI:** `noctalia config export merged|full` (effective config as TOML),
  `noctalia config validate`, `noctalia msg config-reload`. `NOCTALIA_CONFIG_HOME`
  / `NOCTALIA_STATE_HOME` point it at a sandbox dir — the safe way to test config
  changes without touching the live session.
- **Stability caveat:** noctalia has been observed **crash-looping** on this box
  (leaking layer surfaces with `pid:-1`). A crash mid-lock can strand the session,
  so `lock` and `lock-and-suspend` idle stay **off**; only `screen-off` (660s) is
  enabled, which any input recovers. See problems.md.

## Theming
- **`themes/<name>/`** — swappable looks; `scripts/desktop-theme/{save,apply,reset}.sh`.
  A theme's inputs: `noctalia.toml` (merged into `settings.toml`, since that
  outranks `config.toml`), the `hypr/` fragments, and `manifest.conf`. The
  **wallpaper travels with the
  theme** — `theme.source = "wallpaper"`, so the picture is the palette; paths only,
  images stay in `~/Pictures/Wallpapers/`. Full guide: [theming.md](theming.md).
- **`hypr/modules/behaviour.lua` = behaviour; `hypr/theme/` = appearance**
  (generated, gitignored, `require`d last). Split so a theme swap can't revert the
  dwindle-crash workaround or `misc`/`debug`.
- **hyprglass is per-theme.** `manifest.conf` carries `hyprglass = on|off`;
  `apply.sh` always writes `theme/glass.lua`, using an explicit disable stub when
  off — `hyprctl reload` resets plugin options to defaults and hyprglass defaults
  to *enabled*, so silence would mean glass everywhere. Layer rules are theme-owned
  for the same reason: hyprglass does not deconflict with Hyprland's layer blur.
- Everything Noctalia templates (`noctalia.lua`, `hyprtoolkit.conf`, kitty/zellij/
  nvim/gtk themes) is **regenerated output** — gitignored, never snapshotted.
- **`jj/theme-switcher`** — a Noctalia plugin in this repo
  (`noctalia/.config/noctalia/plugins/theme-switcher/`) giving a bar widget + panel
  for switching/saving themes. Discovered via a `[[plugins.source]]` of kind `path`
  declared in `config.toml`; enable once with `noctalia msg plugins enable`. It
  shells out to `apply.sh`/`save.sh` rather than reimplementing them.
- **`jj/kbd-backlight`** — a second Noctalia plugin in this repo
  (`noctalia/.config/noctalia/plugins/kbd-backlight/`) giving a bar widget, a
  control-center tile and an IPC target for the `dell::kbd_backlight` LED (levels
  0/1/2). Same `path` source, same one-time enable. A service polls sysfs because
  the Fn key writes the level in firmware and raises no event; writes go through
  `brightnessctl`, so they only work from the session on the **active VT**.

## Plasma / KDE
- `plasmashell` + `startplasma-wayland` present; Plasma Wayland is the "other"
  session. KDE is also the base desktop edition. `pam_kwallet5`/`ksecretd`
  interactions with session teardown drove the logind `KillUserProcesses=yes`
  change (see SYSTEM.md).

## Other moving parts
- **keyd** — key remapping daemon; shows up as "keyd virtual keyboard/pointer"
  in libinput. Relevant when debugging input.
- **kanshi** — **no longer managed here** (dropped from the repo 2026-07-28). The
  config survives as a plain local file at `~/.config/kanshi/config`, untracked; the
  `kanshi.service` user unit is installed by the distro and stays disabled.
  Don't reintroduce it under Hyprland: kanshi/shikane drive outputs via
  wlr-output-management, and Hyprland has a long-standing bug
  (hyprwm/Hyprland#1274) where a disabled head vanishes from the protocol's output
  list, so those tools can never re-enable it until a physical replug —
  docked↔mobile switching breaks.
  `modules/monitors.lua` is the mechanism of record: declarative `hl.monitor()`
  rules registered at config-parse time, which Hyprland applies natively on connect
  and hotplug. No daemon, no state, no logging — if a monitor is wrong, the rule is
  wrong.
  **Always pin `scale` to a number, never `"auto"`** (see `problems.md`).
- **Terminals/tools:** kitty (+ zellij multiplexer; zellij sessions **persist**
  across compositor restarts — reattach after), alacritty, nvim, yazi, btop,
  zen browser.

## Session environment / PATH
`~/.config/environment.d/dotfiles-path.conf` (stow package `environment`) adds
`~/.local/bin` and `~/bin` to `PATH` **for the whole systemd --user session** —
read by the environment-d generator at login, so it reaches everything
long-lived processes spawn (Hyprland's `exec-once` chain, the zellij
*server*), not just interactive shells that source `~/.zshrc`. Needed because
those processes never source `.zshrc` themselves and otherwise only see
`PATH=/usr/local/bin:/usr/bin`. **Only takes effect on next login/reboot** —
already-running sessions (and their already-started zellij servers) keep
their old env. See problems.md → "zellij resurrection: command not found".

## Power profiles
Fedora 44 ships **tuned + tuned-ppd** (not `power-profiles-daemon`, which is
inactive; `powerprofilesctl` isn't installed). `tuned-ppd` exposes the standard
`org.freedesktop.UPower.PowerProfiles` D-Bus API with
`power-saver`/`balanced`/`performance`, mapped to tuned profiles by
`/etc/tuned/ppd.conf` (distro default).

`power-profile-auto.service` (user unit, stow package `systemd`) follows the AC
adapter: plugged in → `performance` + internal panel at 100%, on battery →
`power-saver` + 50%. Applied only on transition and once at startup, so manual
changes in between stick. It watches UPower's `OnBattery` on the system bus
rather than using a udev rule — **udev has no per-user rules**, and a user unit
is allowed to switch profiles (polkit treats the systemd `--user` manager
session as active) and to set the backlight (`brightnessctl` via logind; sysfs
is root-owned and this user isn't in `video`). Backlight scope is `intel_backlight`
= eDP-1 only; external monitors would need `ddcutil`. Nothing outside the repo;
no `SYSTEM.md` entry. See [power-profiles.md](power-profiles.md).

## Bluetooth

Two layers of rfkill matter here. The `dell-bluetooth` **platform** killswitch
(`dell_laptop` driver, ACPI/SMBIOS) sits *below* BlueZ and cuts power to the USB
radio; while it's soft-blocked no `hci0` device exists, so there is no
`/org/bluez/hci0` and **no desktop applet (noctalia included) can turn Bluetooth
on** — they only ever set `Powered` on an adapter object that has to already
exist. `bluetooth-unblock.service` (user unit, stow package `systemd`) clears
that block at login. Nothing outside the repo; no `SYSTEM.md` entry. See
[problems.md](problems.md) → "noctalia can't turn Bluetooth *on*".

## Stow packages
`alacritty, btop, environment, home, hyprland, kitty, noctalia, nvim,
systemd, zellij, zen` — each `stow <pkg>` symlinks into `$HOME`.
Not packages (never `stow` these): `docs`, `scripts`, `themes`.

**`scripts/stow-audit.sh` checks they're all actually linked.** A file that stops
being a symlink stops being managed *silently* — the repo copy still looks
authoritative and git stays clean while the live file drifts. Any tool that writes
atomically (temp file + rename) to a stowed path causes this; it has bitten
`kitty.conf`, `yazi/theme.toml` and `zen/user.js` here. Run it after adding a
package, or when a config change "doesn't take".

`yazi` was dropped as a package (2026-07-28): its only file, `theme.toml`, is
written by Noctalia's community template and holds nothing hand-written.

## Out-of-tree changes
Tracked in [../SYSTEM.md](../SYSTEM.md): `/etc/systemd/logind.conf.d/…`
(KillUserProcesses), greetd switchover, `/etc/libinput/local-overrides.quirks`
(lid switch quirk).
