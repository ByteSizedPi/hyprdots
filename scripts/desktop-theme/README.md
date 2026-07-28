# scripts/desktop-theme — this machine's live look

**Execution context: LOCAL.** These mutate the running session on *this* box —
Noctalia's live `settings.toml` and Hyprland's generated `ui-theme.lua`. Nothing
here touches a remote host (that's `../server-theme/`).

**Full guide with usage examples: [../../docs/theming.md](../../docs/theming.md).**

```bash
./save.sh <name> [--force]   # snapshot the live look -> themes/<name>/
./apply.sh [name]            # themes/<name>/ -> live  (default: themes/active)
./reset.sh [--yes]           # clear the theme surface -> Noctalia defaults
```

Run them from anywhere — paths resolve relative to the script, not your cwd.

| file | role |
| --- | --- |
| `save.sh` / `apply.sh` / `reset.sh` | entry points |
| `common.sh` | sourced by all three: paths, validate, atomic install, reload |
| `keys.conf` | **which Noctalia settings count as "theme"** — globs, `!` excludes |
| `settings-toml.py` | `extract` / `strip` / `merge` on `settings.toml` (stdlib only) |

## Why this writes to `settings.toml` and not `config.toml`

Noctalia's `~/.local/state/noctalia/settings.toml` **outranks** the stowed
`~/.config/noctalia/config.toml` per key — `config.toml` only fills keys the state
file omits. So a theme has to be merged into `settings.toml`, preserving the
non-theme keys (monitors, widget coordinates, idle, keybinds, calendar). Wallpaper
paths are theme keys — the palette is derived from the picture.
That split is what `keys.conf` defines.

See docs/problems.md → "noctalia config.toml precedence" for the measurements.

## Safety

`apply.sh` and `reset.sh` both validate the candidate config in a throwaway state
dir (`noctalia config validate`) and abort on failure, back up to
`settings.toml.bak`, then install atomically and reload. `apply.sh` also refuses a
theme file containing keys outside the theme surface.
