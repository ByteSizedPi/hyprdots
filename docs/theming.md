# Theming — saving, switching, and defining looks

How to capture the current system-wide look as a named theme, switch between
themes, and design a new one from a blank slate.

Built 2026-07-27. Scripts: `scripts/desktop-theme/{save,apply,reset}.sh`. Storage:
`themes/`. Quick reference: [../themes/README.md](../themes/README.md).

---

## The idea

One command banks the look you're running; one clears it so you can design
a fresh one; one puts a saved look back. Everything Noctalia templates —
Hyprland borders, kitty, zellij, nvim, gtk, btop, qt, zen — follows along,
because those are all **generated** from the palette rather than stored.

```bash
./scripts/desktop-theme/save.sh comicmono    # bank what you have
./scripts/desktop-theme/reset.sh             # blank slate
                                             # ...design...
./scripts/desktop-theme/save.sh softglass    # bank the result
./scripts/desktop-theme/apply.sh comicmono   # switch back
```

## Mental model

### Noctalia's config layers

Measured, not assumed (see problems.md → "noctalia config.toml precedence"):

| layer | wins? |
| --- | --- |
| `~/.local/state/noctalia/settings.toml` — GUI-managed, **not** stowed | **yes, per key** |
| `~/.config/noctalia/config.toml` — stowed | only for keys settings.toml omits |
| built-in defaults | last |

`config.toml` is a fallback layer *underneath* the live settings. That's why a
theme **cannot** live there — the GUI would mask it the moment you touched any
setting. Themes are merged **into `settings.toml`**, with non-theme keys preserved.

`config.toml`'s remaining job is the **fresh-machine seed** (currently: enable
idle screen-off, which is off by default upstream).

### A theme is two files

| file | holds |
| --- | --- |
| `themes/<name>/noctalia.toml` | bar geometry/radii/opacity/fonts, notification + OSD, panel transparency, screen corners, shadows, animation speed, palette, per-widget colors, launcher layout |
| `themes/<name>/hypr-theme.lua` | `gaps_in/out`, `border_size`, `rounding`, `rounding_power`, window opacities, `shadow`, `blur`, animation curves |

Everything else is regenerated: `hypr/noctalia.lua`, `hypr/hyprtoolkit.conf`,
`kitty/themes/noctalia.conf`, `zellij/themes/noctalia.kdl`,
`nvim/lua/noctalia-theme.lua`, gtk3/4 `noctalia.css`. All gitignored, all rewritten
by Noctalia on every theme change. **Never snapshot them.**

### What a theme deliberately does *not* carry

Monitor names, wallpaper paths, desktop/lockscreen widget coordinates, idle,
keybinds, calendar accounts, plugins, and `theme.templates.*`. These are machine
config and must survive a theme switch. Stripping `theme.templates.*` in particular
would stop all template generation.

## Layout

```
themes/
  active                     one line: the theme currently applied
  _base/hypr-theme.lua       neutral Hyprland look, used by reset.sh
  comicmono/
    noctalia.toml            58 keys, flat dotted-key TOML, sorted
    hypr-theme.lua           72 lines
    NOTES.md                 what the look is going for
  README.md

scripts/desktop-theme/       LOCAL — this machine's live look
  save.sh                    snapshot live -> themes/<name>/
  apply.sh                   themes/<name>/ -> live
  reset.sh                   clear the theme surface
  common.sh                  shared paths + validate/install/reload helpers
  keys.conf                  WHICH keys count as "theme" (globs, editable)
  settings-toml.py           extract / strip / merge on settings.toml

scripts/server-theme/        REMOTE — push a fixed palette to jjserver over ssh
  deploy.sh                  render + scp + poke the live remote session
  render.py                  substitute a palette into a Noctalia template
```

The two script groups are separate because they run in different places:
`desktop-theme/` mutates **this** machine's live session; `server-theme/` renders a
pinned palette and ships it to a **remote** host. They share the Noctalia templates
in `noctalia/.config/noctalia/templates/` but nothing else.

`themes/` is **not** a stow package — nothing in it is symlinked into `$HOME`.
The scripts install from it.

---

## Usage

### Switch theme

```console
$ ls themes/
active  _base  comicmono  README.md

$ cat themes/active
comicmono

$ ./scripts/desktop-theme/apply.sh comicmono
Applied theme 'comicmono'
  settings.toml  theme surface replaced (previous kept at settings.toml.bak)
  ui-theme.lua   from themes/comicmono
```

With no argument it re-applies `themes/active` — which is what you want after a
fresh `stow` on a new machine:

```bash
./scripts/desktop-theme/apply.sh
```

**Close Noctalia's Settings window first.** The running shell can flush its
in-memory state over the write.

### Save the current look

```console
$ ./scripts/desktop-theme/save.sh comicmono
Saved theme 'comicmono' -> themes/comicmono/
  noctalia.toml    58 theme keys
  hypr-theme.lua   72 lines
  themes/active    comicmono
Commit it: git -C "/home/jj/dotfiles" add themes/comicmono && git -C "/home/jj/dotfiles" commit
```

Overwriting an existing theme needs `--force` — saving is easy to fire by accident:

```console
$ ./scripts/desktop-theme/save.sh comicmono
error: theme 'comicmono' already exists — pass --force to overwrite

$ ./scripts/desktop-theme/save.sh comicmono --force
Saved theme 'comicmono' -> themes/comicmono/
```

`NOTES.md` is created once and never overwritten — fill it in, it survives
`--force`.

### Design a new theme from a blank slate

```console
$ ./scripts/desktop-theme/save.sh comicmono --force      # 1. bank current, don't skip
Saved theme 'comicmono' -> themes/comicmono/

$ ./scripts/desktop-theme/reset.sh                       # 2. clear
This clears 58 theme keys from /home/jj/.local/state/noctalia/settings.toml
and resets ~/.config/hypr/ui-theme.lua to the neutral base.
Active theme is 'comicmono' — make sure it's saved (themes/comicmono/) first.
Continue? [y/N] y
Theme surface cleared — you're on Noctalia defaults.
  previous settings kept at /home/jj/.local/state/noctalia/settings.toml.bak
  restore with: scripts/desktop-theme/apply.sh comicmono
Tweak, then: scripts/desktop-theme/save.sh <newname>
```

Now you're on stock Noctalia + neutral Hyprland, with monitors, wallpapers, widget
positions, idle, keybinds and calendar all intact. **Step 3, tweak in two places:**

- **Noctalia** → the Settings GUI. Bar opacity, border style and width, corner
  radii, thickness, fonts and weights, capsule groups, notification/OSD opacity and
  position, screen corners, shadows, animation speed, panel transparency, per-widget
  colors, launcher layout. This is most of the look.
- **Hyprland** → edit `~/.config/hypr/ui-theme.lua` directly. Saves apply
  immediately; Hyprland auto-reloads on config file change.

**Colors** come from the palette, not from either file — Settings → Theme. Note
`theme.source = "wallpaper"` derives colors from the current wallpaper, so the look
will drift as the wallpaper changes. Pin `theme.builtin` or
`theme.community_palette` if you want the theme to own its colors.

```console
$ ./scripts/desktop-theme/save.sh softglass              # 4. bank it
Saved theme 'softglass' -> themes/softglass/
```

Skip the confirmation with `--yes` (scripting only):

```bash
./scripts/desktop-theme/reset.sh --yes
```

### Fork a variant of an existing theme

Faster than a blank slate when you want "the same but glassier":

```bash
cp -r themes/comicmono themes/softglass
$EDITOR themes/softglass/noctalia.toml
$EDITOR themes/softglass/hypr-theme.lua
./scripts/desktop-theme/apply.sh softglass
```

`noctalia.toml` is flat and sorted, so diffing two themes reads as exactly what
differs — no nesting to mentally reconcile:

```console
$ diff themes/comicmono/noctalia.toml themes/softglass/noctalia.toml
1c1
< bar.default.background_opacity = 0.8
---
> bar.default.background_opacity = 0.45
30c30
< shell.panel.transparency_mode = "soft"
---
> shell.panel.transparency_mode = "high"
```

Format is flat dotted keys, one setting per line; arrays of tables stay inline:

```toml
bar.default.background_opacity = 0.8
bar.default.border = "primary"
bar.default.border_width = 2.0
bar.default.capsule_group = [ { fill = "surface_variant", id = "g1", members = [ "tray", "screenshot" ], opacity = 1.0, padding = 6.0 } ]
bar.default.font_family = "CaskaydiaCove Nerd Font Propo"
bar.default.font_weight = 700
```

Both forms are verified against `noctalia config validate` and round-trip exactly
(536 keys, 0 drift).

### Change which settings count as "theme"

`scripts/desktop-theme/keys.conf` — globs over dotted key paths, `!` excludes, exclusions
win:

```
bar.*
!bar.*.monitors                 # per-machine monitor assignment

theme.*
!theme.templates.*              # template WIRING, not look

shell.launcher.app_grid
shell.launcher.categories
```

Add a key, then re-save so existing themes pick it up:

```bash
$EDITOR scripts/desktop-theme/keys.conf
./scripts/desktop-theme/save.sh comicmono --force
```

To find the exact dotted name of a setting:

```bash
noctalia config export full | less        # every setting, including defaults
python3 scripts/desktop-theme/settings-toml.py extract ~/.local/state/noctalia/settings.toml \
        scripts/desktop-theme/keys.conf          # what's currently classified as theme
python3 scripts/desktop-theme/settings-toml.py strip   ~/.local/state/noctalia/settings.toml \
        scripts/desktop-theme/keys.conf          # what's classified as machine config
```

### Bootstrap a new machine

```bash
git clone <repo> ~/dotfiles && cd ~/dotfiles
stow hyprland noctalia kitty zellij nvim alacritty btop yazi zen environment systemd
./scripts/desktop-theme/apply.sh comicmono
```

`config.toml` seeds the non-theme behaviour, `apply.sh` installs the look, and
Noctalia regenerates every downstream theme file on first run.

---

## Hyprland: why appearance is a separate file

`hypr/ui.lua` holds **behaviour** — layout, `dwindle`/`master`, `misc`, `debug`,
`resize_on_border` — and ends with:

```lua
require("ui-theme")
```

`hypr/ui-theme.lua` holds **appearance** and is generated: installed by
`apply.sh` from `themes/<name>/hypr-theme.lua`, and gitignored exactly like
`noctalia.lua`.

Swapping whole `ui.lua` files per theme would let an old theme silently revert the
dwindle-crash workaround and the `misc`/`debug` settings. The split makes that
structurally impossible.

`apply.sh` **copies** rather than symlinks: Hyprland's file watch follows the
path it parsed, so a symlinked fragment doesn't reliably trigger auto-reload.

Border **colors** are not here — they come from `noctalia.lua`, which Noctalia
regenerates per palette.

---

## Safety

Every `apply` and `reset`:

1. builds the candidate `settings.toml` in a temp file,
2. validates it in a throwaway state dir with `noctalia config validate`, and
   **aborts** if it fails, so a bad merge can't leave the shell unparseable,
3. copies the current file to `settings.toml.bak`,
4. installs atomically (`mv`), then reloads Noctalia and Hyprland.

`apply.sh` also refuses a theme file that reaches outside the theme surface:

```console
$ ./scripts/desktop-theme/apply.sh _tmptest
settings-toml: theme file sets non-theme keys, refusing:
  keybinds.cancel
  wallpaper.directory
(add them to keys.conf, or remove them from the theme)
```

Undo one step:

```bash
cp ~/.local/state/noctalia/settings.toml.bak ~/.local/state/noctalia/settings.toml
noctalia msg config-reload
```

Or just re-apply a known-good theme:

```bash
./scripts/desktop-theme/apply.sh comicmono
```

---

## Troubleshooting

| symptom | cause / fix |
| --- | --- |
| A setting you changed has no effect | It may be a legacy key name. `noctalia config validate` — an `unknown setting` warning means that key is **doing nothing**. See problems.md → "Launcher settings silently inert". |
| Theme change didn't stick | Settings GUI was open and flushed over the write. Close it, re-apply. |
| Colors change on their own | `theme.source = "wallpaper"` — palette derives from the wallpaper. Pin a builtin/community palette. |
| Hyprland look unchanged after apply | `hyprctl reload`; check `hyprctl configerrors`. Confirm `ui.lua` still ends with `require("ui-theme")`. |
| Noctalia unresponsive after apply | Not the theme — check `~/.cache/noctalia/noctalia.log` and DNS. See problems.md → "noctalia idle stranded". |
| `save.sh` captured too much/too little | Edit `scripts/desktop-theme/keys.conf`, re-save with `--force`. |
| Want to inspect without applying | `python3 scripts/desktop-theme/settings-toml.py merge <settings> <keys.conf> <theme.toml>` prints the result to stdout. |

### Guard-rail messages (all exit 1)

```console
$ ./scripts/desktop-theme/save.sh 'Bad Name'
error: theme name must be lowercase alnum/dash/underscore: 'Bad Name'

$ ./scripts/desktop-theme/apply.sh nope
error: no such theme: /home/jj/dotfiles/themes/nope
```

### Dry runs

The only fully read-only way to preview an apply is `settings-toml.py merge`, which
prints the resulting `settings.toml` to stdout and touches nothing:

```bash
python3 scripts/desktop-theme/settings-toml.py merge \
  ~/.local/state/noctalia/settings.toml scripts/desktop-theme/keys.conf \
  themes/softglass/noctalia.toml | less
```

`NOCTALIA_STATE_HOME` redirects where Noctalia's settings are read/written;
`XDG_CONFIG_HOME` redirects the Hyprland fragment. Setting both keeps an apply off
your live config:

```bash
XDG_CONFIG_HOME=/tmp/dry/config NOCTALIA_STATE_HOME=/tmp/dry/state \
  ./scripts/desktop-theme/apply.sh comicmono
```

**But `themes/active` is still written in the repo regardless** — it's repo state,
not system state, so no env var redirects it. Verified: with both vars set, the live
`settings.toml` and `~/.config/hypr/ui-theme.lua` are untouched, but `themes/active`
is updated. Restore it by hand (`echo comicmono > themes/active`) or with
`git checkout themes/active` if a dry run leaves it wrong.

---

## Reference

**Noctalia CLI worth knowing**

```bash
noctalia config export merged     # effective config (user-set keys only)
noctalia config export full       # effective config incl. every default
noctalia config validate          # syntax + unknown keys + bad values
noctalia msg config-reload        # re-read config, no restart
noctalia msg color-scheme-set <source> <name>
```

**Environment**

| var | effect |
| --- | --- |
| `NOCTALIA_CONFIG_HOME` | overrides `~/.config` for Noctalia |
| `NOCTALIA_STATE_HOME` | overrides `~/.local/state` for Noctalia |
| `XDG_CONFIG_HOME` | respected by the theme scripts for the Hyprland fragment |

**Security:** `~/.local/state/noctalia/state.toml` holds live Google OAuth access
and refresh tokens. It is not part of any theme — never commit, sync, or paste it.

**`settings-toml.py` commands**

| command | output |
| --- | --- |
| `extract <settings> <keys>` | theme keys only |
| `strip <settings> <keys>` | everything that is not a theme key |
| `merge <settings> <keys> <theme>` | strip + theme spliced in (refuses stray keys) |

Stdlib only (`tomllib`, Python 3.11+) — nothing to install on a new machine.
