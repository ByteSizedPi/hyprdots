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
  A theme is two inputs: `noctalia.toml` (merged into `settings.toml`, since that
  outranks `config.toml`) and `hypr-theme.lua`. Full guide: [theming.md](theming.md).
- **`hypr/ui.lua` = behaviour; `hypr/ui-theme.lua` = appearance** (generated,
  gitignored, `require`d from `ui.lua`). Split so a theme swap can't revert the
  dwindle-crash workaround or `misc`/`debug`.
- Everything Noctalia templates (`noctalia.lua`, `hyprtoolkit.conf`, kitty/zellij/
  nvim/gtk themes) is **regenerated output** — gitignored, never snapshotted.

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

## Stow packages
`alacritty, btop, environment, home, hyprland, kanshi, kitty, noctalia, nvim,
systemd, yazi, zellij, zen` — each `stow <pkg>` symlinks into `$HOME`.
Not packages (never `stow` these): `docs`, `scripts`, `themes`.

## Out-of-tree changes
Tracked in [../SYSTEM.md](../SYSTEM.md): `/etc/systemd/logind.conf.d/…`
(KillUserProcesses), greetd switchover, `/etc/libinput/local-overrides.quirks`
(lid switch quirk).
