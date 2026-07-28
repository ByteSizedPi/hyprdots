# theme: liquidglass

> **hyprglass is currently OFF** (2026-07-28) — the on/off behaviour wasn't working
> the way we wanted, so the plugin is disabled at the hyprpm level and this theme
> falls back to Hyprland's own blur. Everything below still describes the intended
> glass look; `hypr/glass.lua` is parked and ignored while `manifest.conf` says off.
>
> **To turn it back on:**
> ```bash
> hyprpm enable hyprglass && hyprpm reload -n && hyprctl reload
> git checkout <commit-before-this> -- themes/liquidglass/hypr/layers.lua
> sed -i 's/^hyprglass = off$/hyprglass = on/' themes/liquidglass/manifest.conf
> scripts/desktop-theme/apply.sh liquidglass
> ```
> The `layers.lua` restore matters: without it the shell surfaces get Hyprland's
> blur *and* glass, which is the double-blur this theme was built to avoid.
> `git log -- themes/liquidglass/hypr/layers.lua` will find the commit.

Created 2026-07-28. Was the only theme that turned hyprglass on.

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
