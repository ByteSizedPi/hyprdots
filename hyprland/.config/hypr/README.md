# ~/.config/hypr — layout

`hyprland.lua` is a table of contents; everything else lives in a subdirectory.
The important thing to know is **who writes what**, because three different
authors put files in here.

```
hyprland.lua        entrypoint — require list, nothing else
.luarc.json         LSP stubs (/usr/share/hypr/stubs)

lib/                shared helpers, no side effects on require
  terminal.lua      resolves $TERMINAL once

modules/            hand-written config, one concern per file
  environment.lua   hl.env()
  monitors.lua      monitor rules (read its header before touching)
  input.lua         keyboard, touchpad, gestures
  behaviour.lua     what the compositor DOES — layout, misc, debug
  keybinds.lua      all binds
  autostart.lua     noctalia daemon
  scratchpads.lua   special:zellij and special:jjserver
  plugins.lua       hyprpm loading model (read before touching plugins)

rules/              theme-independent rules
  windows.lua       window rules

theme/              ⚙ ALL GENERATED — see below
  init.lua          (hand-written) requires the fragments in the right order
  appearance.lua    gaps, rounding, opacity, shadow, blur, animations
  layers.lua        noctalia layer rules — native blur, or ceded to hyprglass
  glass.lua         hyprglass config, or an explicit disable stub
  jjserver.lua      border colour for the jjserver scratchpad

noctalia.lua        ⚙ Noctalia builtin template — palette + apply_theme()
hyprtoolkit.conf    ⚙ Noctalia community template
```

## Generated files — don't hand-edit for keeps

| file | written by | tracked in git? |
|---|---|---|
| `theme/appearance.lua` | `scripts/desktop-theme/apply.sh` | no — input is `themes/<name>/hypr/appearance.lua` |
| `theme/layers.lua` | `scripts/desktop-theme/apply.sh` | no — input is `themes/<name>/hypr/layers.lua` |
| `theme/glass.lua` | `scripts/desktop-theme/apply.sh` | no — input is `themes/<name>/hypr/glass.lua` |
| `theme/jjserver.lua` | `scripts/server-theme/deploy.sh` | **yes** — regenerated rarely, and committing it records the pinned server palette |
| `noctalia.lua` | Noctalia | no |
| `hyprtoolkit.conf` | Noctalia | no |

Editing `theme/appearance.lua` directly is the *intended* way to design a look —
just bank it afterwards with `scripts/desktop-theme/save.sh <name>`, or the next
`apply.sh` overwrites it.

**`noctalia.lua` and `hyprtoolkit.conf` cannot be moved into `theme/`.** They come
from Noctalia *builtin* templates whose output paths are hardcoded. Relocating
them would mean re-authoring both as `theme.templates.user.*` entries and owning
the template content forever — not worth it. That's why the repo root of this
directory looks slightly untidy: what's left at the top level is the entrypoint
plus Noctalia's drop zone.

## Plugins

Plugins are loaded by **hyprpm**, not by this config — `hl.plugin.load()` is broken
on 0.56.0 (it reports success and does nothing). `modules/plugins.lua` has the full
model and the reasoning; read it before adding a plugin. Which plugins are *enabled*
lives outside this repo, in `/var/cache/hyprpm/$USER/`.

Per-plugin **appearance** config is theme-owned (`theme/glass.lua`), because whether
hyprglass runs is a property of the look, not the machine.
