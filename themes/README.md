# themes/ — swappable system-wide looks

Each subdirectory is one complete look: Noctalia, Hyprland, and everything Noctalia
templates (kitty, zellij, nvim, gtk, btop, qt, zen).

**Full guide, with usage examples: [../docs/theming.md](../docs/theming.md).**

Not a stow package — nothing here is symlinked into `$HOME`. The scripts install
from it.

```bash
ls themes/                          # what exists
cat themes/active                   # what's applied
./scripts/desktop-theme/apply.sh <name>     # switch
./scripts/desktop-theme/save.sh <name>      # bank the current look (--force to overwrite)
./scripts/desktop-theme/reset.sh            # clear the theme surface -> blank slate
```

## Layout

```
active                  one line: the theme currently applied
_base/hypr/
  appearance.lua        neutral Hyprland look, used by reset.sh
  layers.lua            default layer rules (Hyprland blurs the shell itself)
<name>/
  noctalia.toml         theme keys (incl. wallpaper paths), flat dotted-key TOML, sorted
  manifest.conf         non-Noctalia keys — currently `hyprglass = on|off`
  hypr/
    appearance.lua      gaps, border_size, rounding, opacity, shadow, blur, anims
    layers.lua          optional; omit to inherit _base
    glass.lua           hyprglass config; required when manifest says `hyprglass = on`
  NOTES.md              what the look is going for
```

## The two things to know

1. **A theme is merged into `~/.local/state/noctalia/settings.toml`**, not into the
   stowed `config.toml` — state outranks config, per key. `config.toml` is only the
   fresh-machine seed. (Measured; see docs/problems.md → "noctalia config.toml
   precedence".)
2. **Generated files are never captured** — `hypr/noctalia.lua`,
   `hypr/hyprtoolkit.conf`, kitty/zellij/nvim/gtk themes. All gitignored, all
   rewritten from the palette on every theme change.

Which keys count as "theme" is defined in
[`../scripts/desktop-theme/keys.conf`](../scripts/desktop-theme/keys.conf).
