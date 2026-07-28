# System-level changes

Changes made outside of the dotfiles stow tree. These require manual re-application on a fresh install.

> Start at **`CLAUDE.md`** (repo root) and **`docs/`** for the full system
> overview and problem log. Deep-dive diagnosis of the recurring Hyprland/Plasma
> issues (greeter ghost, dwindle crash, hybrid GPU, Lua-config gotchas) lives in
> **`docs/hyprland-plasma-diagnosis.md`**.

---

## `/etc/systemd/logind.conf.d/kill-sessions.conf`

```ini
[Login]
KillUserProcesses=yes
```

**Why:** Without this, logind abandons session scopes instead of killing them when a Hyprland session exits or crashes. This leaves `ksecretd` (started by `pam_kwallet5`) orphaned in a "closing" state, accumulating stale sessions and Hyprland sockets under `/run/user/1000/hypr/`.

**To reapply:**
```
sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/kill-sessions.conf <<'EOF'
[Login]
KillUserProcesses=yes
EOF
sudo systemctl reload systemd-logind
```

---

## User systemd overrides — managed via `dotfiles/systemd` stow package

These are version-controlled in `dotfiles/systemd/` and applied with `stow --no-folding systemd` from the dotfiles root. **Must use `--no-folding`** — standard stow creates directory symlinks which systemd does not follow for drop-in discovery.

Drop-ins in repo (symlinked to `~/.config/systemd/user/`):
- `drkonqi-coredump-launcher@.service.d/rate-limit.conf` — rate-limits KDE crash reporter to prevent runaway instances
- `app-org.kde.xwaylandvideobridge@autostart.service.d/kde-only.conf` — prevents xwaylandvideobridge autostarting under Hyprland
- `plasma-xdg-desktop-portal-kde.service.d/not-hyprland.conf` — prevents KDE portal conflicting with xdg-desktop-portal-hyprland
- `xdg-desktop-portal-hyprland.service.d/hyprland-only.conf` — prevents Hyprland portal starting in KDE sessions (mirror of the above; `portals.conf` `default=hyprland;kde;gtk` was activating it for all sessions)

> **Do NOT add `Restart=on-failure` to `wayland-wm@hyprland.desktop.service`.** It was tried and reverted. The Hyprland 0.55.4 SIGSEGVs are *shutdown* crashes (stack: `main` → `CCompositor::cleanup()` → `wl_display_destroy_clients`), triggered when special-workspace windows (zellij/jjserver) unmap during teardown. noctalia logout runs `hyprctl dispatch exit`, so logout itself hits this crash path and exits non-zero. With `Restart=on-failure`, systemd would relaunch Hyprland on logout instead of letting `OnFailure=wayland-session-shutdown.target` end the session — i.e. it breaks logout. The crash is benign for running sessions (it only fires while Hyprland is already exiting); logout still completes via the OnFailure path. Real fix is an upstream Hyprland patch (none available in the lionheartp COPR as of 0.55.4).

### `akonadi_control.service` → `/dev/null` (mask — not in stow, stow can't handle absolute symlinks)

**Why:** Disables Akonadi (KDE's PIM data broker). Not used outside of KDE apps.

**To reapply:**
```
ln -s /dev/null ~/.config/systemd/user/akonadi_control.service
```

---

## Display manager: greetd + tuigreet (replaces plasma-login-manager) — fixes the greeter ghost

**Root cause of the ghost** (full detail in `hyprland-plasma-diagnosis.md` Issue 1): the
Plasma login manager's `kwin_wayland` greeter leaves its framebuffer on a hardware overlay
plane when handing off to Hyprland; Hyprland/aquamarine on this Intel i915 never disables
the inherited plane, so the dead greeter image stays composited over the desktop. This is
an upstream aquamarine+i915 plane-state bug — no Hyprland command clears it.

**Proper fix: stop running a compositor-based greeter at all.** `tuigreet` runs directly
on the console TTY (no Wayland compositor → no overlay plane to leak). plasma-login-manager
is disabled (not removed — re-enableable for fallback). An earlier VT-switch workaround
(scratch `getty@tty8` + sudoers + an autostart script) was **removed** when this replaced it.

### Packages
```
sudo dnf install -y greetd tuigreet
```

### `/etc/greetd/config.toml`
```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --remember --remember-user-session --asterisks --time --time-format '%a %d %b   %H:%M' --greeting 'Welcome back, Johan' --sessions /usr/share/wayland-sessions --window-padding 2 --container-padding 2 --prompt-padding 1 --power-shutdown 'systemctl poweroff' --power-reboot 'systemctl reboot' --theme 'border=blue;title=lightblue;greet=lightcyan;prompt=lightmagenta;time=lightblue;action=blue;button=magenta;text=white;input=lightcyan'"
user = "greetd"
```
`--remember` pre-fills the last user; `--remember-user-session` remembers the last DE per
user. Session picker lists everything in `/usr/share/wayland-sessions` (Hyprland, Hyprland
uwsm-managed, Plasma) — pick "Hyprland (uwsm-managed)" to keep the uwsm setup.

### Supporting setup
```
# cache dir for --remember* (must be owned by the greeter user)
sudo mkdir -p /var/cache/tuigreet && sudo chown greetd:greetd /var/cache/tuigreet && sudo chmod 0755 /var/cache/tuigreet
# greeter user needs vt/input access
sudo usermod -aG video,input greetd
# switch the display manager
sudo systemctl disable plasmalogin
sudo systemctl enable greetd
# recovery console (so a greetd failure can't lock you out — Ctrl+Alt+F2)
sudo systemctl enable getty@tty2
```

### Recovery if greetd fails to start on boot
Switch to tty2 (Ctrl+Alt+F2), log in, then revert:
`sudo systemctl disable greetd && sudo systemctl enable plasmalogin && sudo reboot`
(plasmalogin is still installed; the ghost returns but you get a graphical login back.)

---

## `/etc/libinput/local-overrides.quirks`

```
# Local libinput quirk override.
#
# Reason: the ACPI Lid Switch (PNP0C0D) on this laptop spuriously reports
# CLOSED whenever libinput re-adds the device — which happens on every VT
# switch / seat re-activation. Hyprland (via aquamarine) reacts by disabling
# the internal eDP-1 panel, so switching to the Hyprland TTY left the laptop
# screen powered off ("dead"). Marking the lid switch write_open tells libinput
# the switch is unreliable and to force the open state, preventing the bogus
# eDP blanking.
#
# Device: Bus=0019(host) Vendor=0000 Product=0005 Name="Lid Switch"
#         Phys=PNP0C0D/button/input0

[NWU Lid Switch Unreliable]
MatchName=Lid Switch
MatchBus=host
MatchVendor=0x0000
MatchProduct=0x0005
AttrLidSwitchReliability=write_open
```

**Why:** Switching to the Hyprland TTY repeatedly left the internal laptop
panel (eDP-1) powered off. The compositor was healthy and the modeset
succeeded (`Restoring crtc 149 … 1920x1080@60`), but the Lid Switch
(`PNP0C0D`) was re-added by libinput on every VT switch and read as *closed*
despite ACPI reporting `open`, so aquamarine disabled eDP-1 right after
enabling it (`drm: Disabling output eDP-1`). `write_open` marks the switch
unreliable so libinput forces the open state.

**To reapply:**
```
sudo install -D -m 0644 <this-file> /etc/libinput/local-overrides.quirks
```
Takes effect when the lid switch device is next added (next VT switch or
reboot); no rebuild needed. If `write_open` proves insufficient, the stronger
option is a udev rule setting `LIBINPUT_IGNORE_DEVICE=1` on the Lid Switch.

---

## `/usr/share/noctalia/assets/templates/hyprland/hyprland.lua` — inactive border color

Package file from `noctalia-git` (matugen-style template noctalia renders into
`~/.config/hypr/noctalia.lua`, symlinked from this repo's `hyprland` stow
package). Not part of the stow tree, so a package update will overwrite it
back to stock.

**Change:** line 13, `inactive_border` set to `primary` instead of `surface`:
```lua
general = {
    col = {
        active_border = primary,
        inactive_border = primary,
    },
},
```

**Why:** Cosmetic preference — inactive window borders should use the accent
(`primary`) color instead of the neutral `surface` color.

**To reapply** (e.g. after a `noctalia-git` package update resets the file):
```
sudo sed -i 's/inactive_border = surface,/inactive_border = primary,/' \
  /usr/share/noctalia/assets/templates/hyprland/hyprland.lua
```
Then re-render the templates for the current palette:
```
noctalia msg templates-apply
```

---

## hyprpm build toolchain — `cmake`, `gcc-c++`, `hyprland-devel`

`hyprpm` compiles plugins from source against your exact Hyprland version, so it
needs a full C++ toolchain plus Hyprland's own build dependencies. A stock
install has neither, and `hyprpm update` fails with:
```
✖ Missing dependency: cmake
✖ Missing dependency: g++
✖ Could not update. Dependencies not satisfied. Hyprpm requires:
  cmake, cpio, pkg-config, git, g++, gcc
```
(`cpio`, `pkg-config`, `git` and `gcc` were already present.)

**Change (2026-07-27, dnf transaction 81):**
```
sudo dnf install -y cmake gcc-c++ hyprland-devel
```
93 packages, ~392 MiB installed. `hyprland-devel` comes from the **same COPR as
the running Hyprland** (`copr:lionheartp:Hyprland`, 0.56.0-1.fc44) — version
must match, so pin it to whatever `hyprland` itself is at.

Note `hyprpm` does *not* actually consume `hyprland-devel`'s headers: it clones
hyprwm/Hyprland at the running commit and builds its own header set. The reason
to install it anyway is that it drags in the whole `-devel` dependency closure
that build needs (`wayland-devel`, `aquamarine-devel`, `hyprutils-devel`,
`hyprlang-devel`, `hyprgraphics-devel`, `tomlplusplus-devel`, `glaze-devel`, …).
It is a shorter, version-pinned stand-in for `dnf builddep hyprland`.

**To undo:** `sudo dnf history undo 81`

### hyprpm state store lives in `/var/cache/hyprpm/$USER/`, not `~/.local/share`

This Fedora/COPR build patches the state path. Worth knowing because every
upstream doc and issue thread says `~/.local/share/hyprpm`:
```
/var/cache/hyprpm/jj/
├── headersRoot/          # Hyprland headers hyprpm built for itself
├── state.toml            # hash = <hl-commit>_aq_<ver>_hu_<ver>_...
└── HyprGlass/
    ├── hyprglass.so
    └── state.toml
```
Root-owned, outside the stow tree, and **not** backed up by this repo — after a
reinstall, plugins must be re-added with `hyprpm add`. The `hash` in `state.toml`
pins the Hyprland commit plus aquamarine/hyprutils/hyprgraphics/hyprcursor/
hyprlang ABI versions, which is why a Hyprland update requires
`hyprpm update` before plugins will load again.

### Plugins added

- **HyprGlass** (`https://github.com/hyprnux/hyprglass`) — "liquid glass" visual
  effects: frosted blur, edge refraction, chromatic aberration, specular
  highlights. Configured in Lua via `hl.plugin.hyprglass`, so it belongs behind
  an `if hl.plugin.hyprglass then` guard in the `hyprland` stow package.
  **Added but deliberately left disabled** — see `docs/problems.md` for this
  machine's history of Hyprland crashes on a hybrid GPU; a heavy per-window
  shader plugin is a plausible new instability source, so enable it knowingly:
  ```
  hyprpm enable hyprglass
  hyprpm disable hyprglass    # if things get unstable
  ```
