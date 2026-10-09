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

## `ytmusic` profile (YouTube Music web app)

A second, separate Zen profile at `~/.zen/ytmusic`. The `special:youtube`
workspace rule in `hyprland/.config/hypr/modules/scratchpads.lua` starts it with:

    zen-browser --profile ~/.zen/ytmusic --no-remote --name zen-ytmusic

`--name` sets the Wayland app_id to `zen-ytmusic`, so Hyprland can tell this
window from the main Zen window (class `zen`). The profile is NOT in
`profiles.ini`.

Tracked: `user.js` (compact mode, start page, no welcome pages, auto-enable
sideloaded add-ons) and `chrome/userChrome.css` + `userContent.css` (import the
same Noctalia CSS and `noctalia-transparency.css` as the main profile).

**Stow with `--no-folding`.** Without it, stow makes `~/.zen/ytmusic` one
symlink into this repo, and Zen then writes the whole profile into the repo:

    cd ~/dotfiles && stow --no-folding --target="$HOME" zen

**Not tracked, set up by hand (2026-10-07).** Do every step with the ytmusic
window closed:

1. Copy the add-ons from the main profile into `~/.zen/ytmusic/extensions/`:
   Zen Internet `{91aa3897-2634-4a8a-9092-279db23a7689}.xpi`,
   `uBlock0@raymondhill.net.xpi`, Return YouTube Dislike
   `{762f9885-5a13-4abd-9c77-433dcd38b8fd}.xpi`, and the Catppuccin Macchiato
   Lavender theme `{15cb5e64-94bd-41aa-91cf-751bb1a84972}.xpi`.
2. Copy the Transparent Zen mod: `zen-themes.json` (profile root),
   `chrome/zen-themes.css` and `chrome/zen-themes/642854b5-88b4-4c40-b256-e035532109df/`.
   Its `mod.sameerasw.*` prefs are in the tracked `user.js`. Zen Internet makes
   the page transparent. The mod makes the browser area behind the page
   transparent.
3. Start the profile once, then stop it.
4. Zen Internet settings live in IndexedDB under the extension UUID. In
   `~/.zen/ytmusic/prefs.js`, replace the Zen Internet UUID in
   `extensions.webextensions.uuids` with the main profile UUID
   (`d1f13c50-8274-496e-83a1-2b199d98cd0f`). Then copy
   `storage/default/moz-extension+++<that uuid>^userContextId=4294967295` from
   the main profile.
5. **Delete `~/.cache/zen/ytmusic/startupCache`.** The startup cache keeps the
   old UUID in the generated background page. Zen Internet then loads
   `moz-extension://<old uuid>/background.js`, the load fails, the background
   script never runs, and no site gets any style. The only symptom is a
   console warning "Loading failed for the <script> with source
   moz-extension://<old uuid>/...". Found on 2026-10-07.
6. Start the profile. Enable the Catppuccin theme in about:addons. Setting
   `extensions.activeThemeID` in `user.js` did NOT activate it (tested
   2026-10-07).
7. Sign in to YouTube Music.

Changes to Zen Internet settings in the main profile do not reach this profile.
Repeat steps 4 and 5 to copy them again.

**Debugging this profile.** Start it by hand with a different `--name`, so the
window opens on the current workspace, plus WebDriver BiDi:

    zen-browser --profile ~/.zen/ytmusic --no-remote --name zen-ytmusic-test \
      --remote-debugging-port 9223 --remote-allow-system-access

A BiDi client (python `websockets`) can then run `script.evaluate` in the page,
or in the chrome window (`browsingContext.getTree` with `"moz:scope": "chrome"`)
to read `ExtensionParent.GlobalManager.getExtension(id).backgroundState` and
`Services.console.getMessageArray()`. Stop the instance afterwards, because the
port gives full browser control to any local process.
