# zen — Zen Browser transparency + Noctalia theming

Stow package for the Zen Browser profile. Provides a uniform, theme-tracking
window transparency that coexists with Noctalia's Zen theming and the
"Transparent Zen" mod.

## What's tracked

- `chrome/noctalia-transparency.css` — the actual work. Forces all chrome panes
  transparent, resets native widget `appearance` (the key that lets XUL widgets
  like the tab bar/sidebar honor a CSS background at all), and paints ONE global
  tint on the `:root` window container. Opacity is a single value: change every
  `80%` to taste. Uses `color-mix()` on Noctalia's `--base`, so it tracks themes.
- `user.js` — the prefs that make it possible: `legacyUserProfileCustomizations`
  (loads userChrome), `zen.widget.linux.transparency` + `allow_transparent_browser`
  (transparent window), and the Transparent Zen mod's tint pinned to `#00000000`
  (no-op; the mod just provides the transparency infrastructure).

## NOT tracked (intentionally)

- `chrome/userChrome.css` / `chrome/userContent.css` — Noctalia's `apply.sh`
  rewrites userChrome.css on every theme change, so it's left in the profile.
  It must contain this line for the transparency to load (already present):

      @import ".../chrome/noctalia-transparency.css";

## Caveats / re-deploy

- **Profile-specific path.** The profile dir name (`xen9lela.Default (release)`)
  is randomly generated. If the profile is recreated, rename the dir under
  `zen/.zen/` to match the new profile, then `stow -R zen`.
- Deploy: `cd ~/dotfiles && stow --target="$HOME" zen`
- The bookmarks pane and tab bar only became transparent once `appearance: none`
  was applied — don't remove that block.
