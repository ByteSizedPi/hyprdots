# theme: liquidglass

Created 2026-07-28. The only theme that turns hyprglass on.

**`hypr/layers.lua` must stay at 1 rule.** It keeps only `noctalia-screen-corner`;
the other four namespaces are claimed by `hypr/glass.lua`. `save.sh` captures the
live layers file, so saving this theme while a non-glass theme's rules are installed
pulls in the full 5-rule `_base` set and glass goes muddy — the two blur passes it
exists to avoid. Count the rules if the look degrades.

- **Feel:** frosted glass — translucent windows over a blurred, refracted
  background, with the Noctalia bar/panels/notifications glassed too. Wide gaps
  and a 14px radius so the glass edges are actually visible.
- **Palette:** inherited from paper_bw's starting point; retune once the look settles.

## What makes this theme different

| | other themes | liquidglass |
| --- | --- | --- |
| `manifest.conf` | `hyprglass = off` | `hyprglass = on` |
| window opacity | `1.0` | `0.92 / 0.84` — **required**, glass draws *behind* the window |
| `hypr/layers.lua` | not shipped (inherits `_base`) | shipped, and shorter |
| `shell.shadow.alpha` | `0.8` | `0.2` — see below |

## Two things that will bite if you change them

**Window opacity must stay below 1.** hyprglass draws the glass slab behind the
window surface. At opacity 1.0 the window covers it and you see nothing at all —
this is the usual "glass isn't working" cause, and it looks identical to the plugin
being broken.

**Shadow alpha and `mask_threshold` are coupled.** Glass masks on layer alpha, and
layer shadows count as visible content. With Noctalia's default `shell.shadow.alpha
= 0.8` and panel content also at ~0.8 there's no cutoff that keeps the panel and
drops its shadow, so the shadow gets glassed into a grey halo. This theme sets
shadow alpha to 0.2 and `mask_threshold` to 0.3. Change one, re-check the other.

## Tuning

Edit the installed copy, reload to see it, bank it when you like it:

```bash
$EDITOR ~/.config/hypr/theme/glass.lua
hyprctl reload
scripts/desktop-theme/save.sh liquidglass --force
```

Live poke without a reload (`hyprctl keyword` doesn't work under the Lua parser):

```bash
hyprctl repl 'hl.plugin.hyprglass.config({ blur_strength = 2.5 })'
```

Built-in presets to inherit from: `high_contrast`, `subtle`, `clear`, `glass`.
