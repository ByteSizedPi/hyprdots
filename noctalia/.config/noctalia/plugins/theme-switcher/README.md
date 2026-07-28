# jj/theme-switcher

A Noctalia bar widget + panel for the themes in `~/dotfiles/themes`. Shows the
active theme, switches between them, updates the current one, and banks the live
look as a new one — without dropping to a shell.

## What it is (and isn't)

A **front end for `scripts/desktop-theme/{apply,save}.sh`**. It never touches
`settings.toml`, the Hyprland fragments or the app overlays itself — it shells out.
That's deliberate: those scripts validate a candidate `settings.toml` in a sandbox
before installing it and keep a `.bak`. Reimplementing any of that in Luau would
mean two things to keep in step, and the panel would be the one that silently
drifted.

Consequence: anything the scripts can't do, this can't either.

## Install

The plugin is discovered through a `path` source declared in
`noctalia/.config/noctalia/config.toml`, so on a stowed machine it just appears.
It still has to be enabled once:

```bash
noctalia msg plugins enable jj/theme-switcher
```

Then add the widget: **Settings → Bar → Add widget → Theme Switcher**, or by hand
with `type = "jj/theme-switcher:widget"`.

Open the panel without the widget:

```bash
noctalia msg panel-toggle jj/theme-switcher:panel
```

## Settings

| key | default | what it does |
| --- | --- | --- |
| `repo` | `~/dotfiles` | where `themes/` and `scripts/desktop-theme/` live |
| `confirm_apply` | `true` | Apply asks once before running — applying replaces the whole theme surface **including the wallpaper**, so it's not a click you want to fire by accident |

## How it decides what a theme is

A directory under `themes/` containing `noctalia.toml`. That filters out `active`
(a file), `README.md`, and `_base` (fragment sources, not a theme).

The current theme is read from `themes/active`, which every `apply.sh` and `save.sh`
run rewrites — the one file that always reflects what's applied. The widget polls it
every 5s because the scripts can be run from a shell too, and there's no event to
subscribe to. The panel pokes the widget over IPC after its own actions so the bar
updates immediately rather than waiting out the poll.

## Notes

- `plugin_api = 9` — the floor for passing closures as `onClick` handlers.
- Errors from the scripts are surfaced verbatim (first line in the panel, full text
  in a notification) rather than replaced with a generic message. The scripts already
  fail with useful text; inventing our own would lose it.
- The plugin system is still marked beta in v5. If a Noctalia update breaks this,
  `noctalia plugins lint noctalia/.config/noctalia/plugins/theme-switcher` is the
  first thing to run.
