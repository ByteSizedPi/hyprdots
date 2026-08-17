# jj/kbd-backlight

A Noctalia bar widget + control-center tile for the keyboard backlight LED. On
this Dell Precision 3590 the LED is `dell::kbd_backlight`, driven by the
`dell-laptop` module, with three levels: `0` off, `1` half, `2` full.

## Entries

| Entry | Id | What it does |
|-------|----|--------------|
| Service | `jj/kbd-backlight:state` | Polls sysfs, publishes the level, answers IPC |
| Bar widget | `jj/kbd-backlight:widget` | Click toggles, right click cycles, scroll steps |
| Control-center tile | `jj/kbd-backlight:shortcut` | One press toggles |

The service is the only entry that reads sysfs. The widget and the tile read the
level it publishes through `noctalia.state`, so the two surfaces cannot disagree.

## Why it polls

The level changes from three directions: this plugin, the Fn key (the embedded
controller writes the level itself), and any other caller of `brightnessctl`.
Only the first one could raise an event, so `/sys/class/leds/<device>/brightness`
is the one place that always tells the truth. The service re-reads it every
`poll_seconds` (2 by default) with `noctalia.readFileAsync`, because
`dell-laptop` answers that read over SMBIOS and it can block for milliseconds.

## Why it shells out to brightnessctl

`/sys/class/leds/dell::kbd_backlight/brightness` is owned by root and is not
group writable. `brightnessctl` is not setuid and there is no udev rule for it,
so the write goes through `systemd-logind`, which grants it to the session on the
**active VT**.

This machine runs Hyprland and Plasma on two VTs at once. A click in the
background session therefore fails with a polkit error instead of doing nothing
quietly. The plugin reports that failure as an error notification.

## Install

The plugin is discovered through the `path` source declared in
`noctalia/.config/noctalia/config.toml`, so on a stowed machine it just appears.
Enable it once:

```bash
noctalia msg plugins enable jj/kbd-backlight
```

Then place the surfaces you want:

- **Bar widget** — Settings → Bar → Add widget → Keyboard Backlight, or by hand
  with `type = "jj/kbd-backlight:widget"`.
- **Control-center tile** — Settings → Control Center, or by hand by adding
  `{ type = "jj/kbd-backlight:shortcut" }` to `shortcuts` in
  `~/.local/state/noctalia/settings.toml`.

Neither is required. The service runs whenever the plugin is enabled, so the
keybinds below work with no widget placed at all.

## Keybinds

```conf
# ~/.config/hypr/... — the service is a singleton, so the target is `all`
bind = SUPER, F10, exec, noctalia msg plugin jj/kbd-backlight:state all cycle
```

Accepted events: `toggle`, `cycle`, `on`, `off`, and `set` with a level as the
payload (`… all set 2`).

The Dell Fn key for the keyboard light is handled inside the embedded controller.
Check with `wev` whether it reaches the compositor as `XF86KbdBrightnessUp`
before binding that keysym; a chord such as `SUPER, F10` always works.

## Settings

| Key | Scope | Default | Meaning |
|-----|-------|---------|---------|
| `device` | plugin | `dell::kbd_backlight` | Name under `/sys/class/leds` |
| `default_level` | plugin | `1` | Level a toggle turns on to before any level is remembered |
| `poll_seconds` | plugin | `2` | Sysfs re-read interval |
| `show_level` | widget | `true` | Draw `level/max` next to the glyph |

A toggle turns the light on to the **last level that was lit**, not to
`default_level`, once the service has seen one. That level is kept in
`~/.local/state/noctalia/plugins/data/jj/kbd-backlight/last-on` so it survives a
restart.

## Behaviour worth knowing

The firmware turns the LED off by itself after 10 seconds without typing:

```console
$ cat /sys/class/leds/dell::kbd_backlight/stop_timeout
10s
$ cat /sys/class/leds/dell::kbd_backlight/start_triggers
+keyboard +touchpad
```

The sysfs `brightness` value does **not** drop when that happens, so the widget
keeps showing the level you chose. Typing lights the keyboard again.

## Requires

`brightnessctl`, and a `dell-laptop`-style LED under `/sys/class/leds`. Where the
device is missing, the widget hides itself and the tile is disabled rather than
offering a control that cannot work.
