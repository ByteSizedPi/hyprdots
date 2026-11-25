# Omarchy MacBook (branch `omarchy`)

This branch configures a **MacBook Air M2 (Asahi, aarch64) running Omarchy 4.5**,
not the Fedora/Noctalia desktop on `master`. Omarchy owns the desktop (Hyprland
defaults, bar/shell, launcher, theming pipeline, power); this branch layers the
home look and personal tools on top **through Omarchy's own extension points**,
so `omarchy update` never has to fight it. Never edit `/usr/share/omarchy/`.

## Stow packages used here

```bash
cd ~/dotfiles
stow --no-folding zsh zellij hypr-omarchy espanso systemd-omarchy
stow omarchy          # WITH folding — see "theme must be a directory link"
```

| Package | What | Notes |
|---|---|---|
| `zsh` | `.zshrc`, `~/.config/zsh/omarchy.zsh`, `bira-status` theme | `.zshrc` is host-safe: it sources `omarchy.zsh` only if present, and picks dnf vs `omarchy pkg` aliases per distro |
| `zellij` | config + layouts + static themes | `theme "omarchy"`; see Zellij theming |
| `omarchy` | `themes/catppuccin-frappe/`, `themed/zellij.kdl.tpl`, `hooks/theme-set.d/zellij-reload` | |
| `hypr-omarchy` | `~/.config/hypr/{hyprland,looknfeel,scratchpads}.lua` | Gaps, animations, motion/layer blur; scratchpads; espanso helper-window rule. `hyprland.lua` is Omarchy's user entry file plus `require("hypr.scratchpads")` |
| `espanso` | config + `match/base.yml` (shared with master) | `match/private.yml` is gitignored — copy it from home by hand |
| `systemd-omarchy` | `espanso.service.d/graphical-session.conf` | Ties the packaged unit to `graphical-session.target` (uwsm sets `WAYLAND_DISPLAY` before it) instead of home's wait-loop unit |

**Not stowed here:** `home` (would replace Omarchy's `.bashrc`), `hyprland`,
`noctalia`, `niri`, `kitty`, `alacritty`, `gtk`, `systemd` (KDE/Plasma drop-ins).

### Theme must be a directory link (tried & fixed 2026-11-25)

`omarchy theme set` stages a user theme with `cp -r ~/.config/omarchy/themes/<name>/*`.
With `--no-folding` every file in the theme was a *relative* symlink, `cp -r`
copied the links as links into `~/.local/state/omarchy/current/theme/`, they
dangled there, and the theme silently fell back (grey inactive border, no
wallpaper). Stowing `omarchy` **with** folding makes
`~/.config/omarchy/themes/catppuccin-frappe` one directory symlink; the glob then
expands to real files and they copy correctly. Omarchy's "theme came from a git
repo" check is `[[ ! -L $src && -d $src/.git ]]`, so the symlinked dir is still
treated as the user's own theme (no file restrictions).

## Look: home Catppuccin/Noctalia → Omarchy

| Home (master) | Here |
|---|---|
| Noctalia community palette "Catppuccin Frappe Mauve" | Theme **Catppuccin Frappe** (`omarchy/.../themes/catppuccin-frappe/colors.toml`), accent = mauve |
| `modules/borders.lua`: primary border on every window | `hyprland_active_border` / `hyprland_inactive_border` in `colors.toml` |
| `themes/catppuccin/wallpaper-prism.svg` | Same SVG, rendered to `backgrounds/1-prism.png` (`rsvg-convert -w 3840 -h 2160`) |
| `themes/catppuccin/hypr/appearance.lua`, `modules/effects.lua` | `hypr-omarchy/.config/hypr/looknfeel.lua` (theme-independent here, unlike home) |
| `themes/catppuccin/hypr/layers.lua` (blur shell surfaces) | Layer rules for `omarchy-bar`, `omarchy-notifications`, `omarchy-osd` in `looknfeel.lua` |
| Noctalia bar opacity 0.8, colour primary | Theme section overrides `shell.bar.toml`, `shell.notifications.toml` (replace one `[section]` of the generated `shell.toml`) |
| kitty `background_opacity 1` | `omarchy hyprland window transparency opaque` |
| CaskaydiaCove Nerd Font | `ttf-cascadia-code-nerd` + `omarchy font set "CaskaydiaCove Nerd Font Mono"` |

Not matched (Omarchy's bar has no knobs; would need `omarchy plugin clone omarchy.bar`,
which forfeits bar updates): bar border, floating margins, notification
position (top-centre at home), Noctalia widget set.

## Scratchpads (special workspaces)

`hypr-omarchy/.config/hypr/scratchpads.lua`, ported from master's
`modules/{scratchpads,specialbar,urgent}.lua` + the special gestures in `input.lua`.
Keys were picked against `hyprctl binds` so no Omarchy default is overridden:

| Home | Here | Why |
|---|---|---|
| SUPER+S zellij | **SUPER+Z** | SUPER+S / SUPER+ALT+S are Omarchy's own scratchpad (kept) |
| SUPER+Y YouTube Music (Zen profile) | SUPER+Y, Omarchy web app (`omarchy-launch-webapp`) | Zen not installed; class `chrome-music.youtube.com__-Default` |
| SUPER+B Beeper | not set up | x86_64 AppImage; SUPER+B is free if an arm64 build turns up |
| SUPER+Tab monocle cycle | ALT+Tab (Omarchy's `cycle_next`) | SUPER+Tab is Omarchy's next workspace |

zellij runs in **foot** (`--app-id=zellij-local`), monocle layout, session `main`.
Gestures: SUPER+3-finger up toggles zellij, SUPER+3-finger down dismisses it,
3-finger down dismisses any special workspace. `dim_special = 0` + special blur
(size 10, passes 3, xray) — global, so it also sets the bar's blur. Urgent windows
in a hidden scratchpad raise a notification naming the key.

## Zellij theming

`~/.config/omarchy/themed/zellij.kdl.tpl` (ported from
`noctalia/templates/zellij-theme.kdl`) is rendered by Omarchy on every theme
change into `~/.local/state/omarchy/current/theme/zellij.kdl`.
`~/.config/zellij/themes/omarchy.kdl` is a hand-made symlink to that output
(**not tracked** — recreate on a fresh install). The `theme-set` hook bumps
`// omarchy-theme-applied:` in `config.kdl` in place so running sessions reload;
this dirties `zellij/.config/zellij/config.kdl` in git on each theme change.

## Changes outside the stow tree

Reapply by hand on a fresh install.

| Change | How |
|---|---|
| `/etc/keyd/default.conf`: `capslock = overload(meta, esc)` only (no `rightcontrol = f13`: no right Ctrl, no voxtype; dictation is Superwhisper) | `pacman -S keyd`, write file, `systemctl enable --now keyd` |
| espanso 2.2.1 (AUR `espanso-wayland`, arch=x86_64 only) | `yay -G espanso-wayland`, install deps (`rust wxwidgets-gtk3 wxwidgets-common wl-clipboard`), `makepkg -A --nocheck`, `pacman -U`; install script sets `cap_dac_override+p`. Then `systemctl --user add-wants graphical-session.target espanso.service`. First run shows a welcome window. |
| Packages | `pacman -S keyd zsh pkgfile zellij stow ttf-cascadia-code-nerd`; `pkgfile -u`; `systemctl enable --now pkgfile-update.timer` |
| Login shell zsh | `chsh -s /usr/bin/zsh` |
| oh-my-zsh + custom plugins (git clones, not tracked) | `git clone --depth 1` ohmyzsh → `~/.oh-my-zsh`; `zsh-users/zsh-autosuggestions` and `zdharma-continuum/fast-syntax-highlighting` → `~/.oh-my-zsh/custom/plugins/` |
| Omarchy state | `omarchy theme set "Catppuccin Frappe"`, `omarchy hyprland window transparency opaque`, `omarchy font set "CaskaydiaCove Nerd Font Mono"` |
| `~/.config/omarchy/shell.json` clock `format: "HH:mm - ddd dd MMM"` | Not stowed: `omarchy bar …` commands rewrite this file |

Caps Lock trade-off: Omarchy's compose key is Shift+Caps, which keyd now owns.
