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

---

## Tailscale — `--accept-routes` must stay OFF on this laptop

```
sudo tailscale set --accept-routes=false
```

Verify with `tailscale debug prefs | grep RouteAll` — must be `false`.

**Why:** This laptop is the ethernet gateway for the Proxmox box: it *is*
`10.42.0.1` and NATs `10.42.0.0/24` out over WiFi. Another tailnet node
advertises that same subnet as a route. With `--accept-routes` on, Tailscale
installs `10.42.0.0/24 dev tailscale0` into **routing table 52**, which policy
rule 5270 consults *before* the `main` table (rule 32766). Return traffic for
the NAT therefore leaves via `tailscale0` instead of `enp0s31f6`, and the
Proxmox box loses all internet access while still being pingable on the LAN —
a confusing split failure that also made AdGuard answer local rewrites while
timing out on every upstream query.

This cost a long debugging session on 2026-07-31. **Do not turn it back on**
while this machine is acting as the gateway. If a tailnet route is genuinely
needed, use `--accept-routes` with an exclusion for `10.42.0.0/24`, or move the
gateway role off the laptop.

---

## `/etc/systemd/resolved.conf` — REVERTED, kept as a record

Stock Fedora file; the `[Resolve]` section has no uncommented keys. A backup of
the modified version is at `/etc/systemd/resolved.conf.bak-<date>`.

**What was changed and undone (2026-08-01):** a global `DNS=10.42.0.192` line
was added to point the laptop at the LAN AdGuard instance.

**Why it was reverted:**
1. It was inert. `resolvectl status` showed the default-route link
   (`wlp0s20f3`) using its DHCP-provided `1.1.1.1`; link-level DNS wins over
   the global setting, so no query ever reached AdGuard.
2. It points at a host that is powered down overnight, so had it taken effect
   it would have broken name resolution every night.
3. Policy: this laptop is a workstation. Homelab services get configured on the
   server, not by editing `/etc` here.

**To reapply** (only if AdGuard should genuinely be the laptop's resolver — set
it per-link, not globally, and ensure a fallback):
```
sudo resolvectl dns wlp0s20f3 10.42.0.192 1.1.1.1
```

---

## Komodo — nothing installed at system level on this laptop

Recorded so the absence is deliberate rather than assumed. The Komodo sandbox
that ran here during development (Core, Mongo, Periphery, plus a test Prowlarr)
was **containers only** — no systemd units, no `/etc/komodo`, no host packages.
All of it was removed on 2026-08-01: containers, the `komodo_keys` /
`komodo_mongo-data` / `komodo_mongo-config` volumes, the images, and the
root-owned `/mnt/docker-data` tree.

**Policy going forward:** Komodo runs on `app-prod`, not here. Container
testing on this laptop is fine, but nothing homelab-related should write to
`/etc`, install systemd units, or create root-owned directories outside
`/home`. The `~/server` git repo is just source — it changes nothing on this
machine.

---

## Desktop font — `~/.config/kdeglobals` (Qt/KDE) + three font packages

The monospace font is set on four layers. Three are in the repo; the Qt one is
not, and neither are the font packages.

**In the repo (no action needed on a fresh machine):**

| layer | file |
|---|---|
| kitty | `kitty/.config/kitty/kitty.conf` |
| noctalia bar + shell | `themes/paper_bw/noctalia.toml` (applied into state `settings.toml`) |
| GTK 3 / GTK 4 | `gtk/.config/gtk-{3,4}.0/settings.ini` — **the `gtk` stow package**, added 2026-08-04 |

**Out of tree — reapply by hand:**

```
sudo dnf install zedmono-nerd-fonts commitmono-nerd-fonts victormono-nerd-fonts
```

`commitmono` and `victormono` were the two rejected candidates; keep them or
drop them, nothing references them. `zedmono-nerd-fonts` is the one in use.

Then the Qt/KDE half, in `~/.config/kdeglobals` under `[General]` and
`[WM]`:

```ini
fixed=ZedMono Nerd Font Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0
font=ZedMono Nerd Font Propo,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0
menuFont=ZedMono Nerd Font Propo,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0
smallestReadableFont=ZedMono Nerd Font Propo,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0
toolBarFont=ZedMono Nerd Font Propo,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0
activeFont=ZedMono Nerd Font Propo,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0
```

Or just run `scripts/desktop-font.sh zedmono`, which writes all four layers.

**Why `kdeglobals` is not a stow package.** KConfig saves by writing a temp file
and renaming it over the target. A rename replaces a symlink with a regular
file, so the first time anything in Plasma's settings is touched, a stowed
`kdeglobals` would silently stop being managed — the exact failure
`scripts/stow-audit.sh` exists to catch.

**Watch the GTK files for the same thing.** `~/.config/gtk-{3,4}.0/settings.ini`
carry `gtk-modules=colorreload-gtk-module:window-decorations-gtk-module`, which
means kde-gtk-config wrote them. They were stable from 2026-06-26 to
2026-08-04 despite Plasma running daily, so stowing them is a reasonable bet —
but if a Plasma appearance change ever detaches them, `stow-audit.sh` will say
so, and the answer is to move them here alongside `kdeglobals`.
