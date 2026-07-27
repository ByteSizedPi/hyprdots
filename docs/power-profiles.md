# Power profiles — follow the AC adapter

Plug the laptop in → **performance**. Unplug it → **power-saver**.
Anything you pick by hand in between is left alone until the next plug/unplug.

Nothing here lives outside the repo, so there is **no `SYSTEM.md` entry** for it
and no `sudo` was needed to install it.

## Files

| what | where |
|---|---|
| the watcher | `scripts/power/auto-profile.sh` (repo, not stowed — the unit calls it by absolute path) |
| the unit | `systemd/.config/systemd/user/power-profile-auto.service` (stow package `systemd`) |

Install on a fresh machine:

```sh
cd ~/dotfiles && stow systemd
systemctl --user daemon-reload
systemctl --user enable --now power-profile-auto.service
```

## Why not a udev rule

**There is no such thing as a per-user udev rule.** udev runs as root under PID 1
and reads rules only from `/usr/lib/udev/rules.d`, `/etc/udev/rules.d` and
`/run/udev/rules.d`. A real rule therefore means `sudo`, a file outside the stow
tree, and a `SYSTEM.md` entry — plus the awkward part, that a root-context
`RUN+=` has no clean way to reach into the right user's session to change a
per-user-visible setting.

**UPower is already the userspace consumer of exactly those events.** It watches
the `power_supply` udev subsystem and republishes AC state on the system bus as
the `OnBattery` property of `org.freedesktop.UPower`. Watching UPower is the
same event, one hop downstream, from a normal user process.

The other half is permission to *set* the profile. polkit's
`org.freedesktop.UPower.PowerProfiles.switch-profile` action is
`allow_active=yes` / `allow_inactive=no`, and — verified on this machine — the
`systemd --user` manager session (`loginctl` session 3, `Class=manager`,
`Seat=`) reports `Active=yes`, so a user unit is allowed to switch profiles with
no prompt and no polkit rule of our own:

```sh
systemd-run --user --wait --pipe busctl --system set-property \
  org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles \
  org.freedesktop.UPower.PowerProfiles ActiveProfile s power-saver   # → success
```

If that ever stops working (a polkit or systemd change flipping the manager
session to inactive), the fallback is a `/etc/polkit-1/rules.d/` rule granting
uid 1000 that action — and *that* would need a `SYSTEM.md` entry.

## This machine's profile stack: tuned, not power-profiles-daemon

Fedora 44 ships **tuned + tuned-ppd**, not `power-profiles-daemon`.
`power-profiles-daemon.service` is inactive; `tuned` and `tuned-ppd` are active.
`tuned-ppd` provides the *same* `org.freedesktop.UPower.PowerProfiles` D-Bus
API, which is what the script talks to, so this is driver-agnostic.

`powerprofilesctl` is **not installed** — hence `busctl` in the script rather
than the more obvious CLI.

The PPD → tuned mapping is `/etc/tuned/ppd.conf` (distro default, unmodified):

| PPD profile | tuned profile (AC) | tuned profile (battery) |
|---|---|---|
| `power-saver` | `powersave` | `powersave` |
| `balanced` | `balanced` | `balanced-battery` |
| `performance` | `throughput-performance` | `throughput-performance` |

Note `battery_detection=true` in that file: it does **not** switch the PPD
profile for you — it only changes which *tuned* profile a given PPD profile maps
to while on battery (that's the `[battery]` section, which only remaps
`balanced`). That's why this service is needed at all.

## How the watcher behaves

- **On start** (login, and every `Restart=`): reads AC state and applies the
  matching profile. This is the "whenever it couldn't observe the transition"
  path — boot, login, or a missed event.
- **On transition**: `gdbus monitor` on `/org/freedesktop/UPower`; every line
  mentioning `OnBattery` triggers a fresh read of the real state, and it acts
  only when the state actually flipped. A single plug event emits several
  signals, so the last-seen-state comparison is what keeps it to one switch.
- **In between**: nothing. There is no polling and no periodic re-apply, which
  is deliberate — a re-apply loop would clobber a manual choice.

Unit is `WantedBy=default.target`, *not* `graphical-session.target`: it only
talks to the system bus, and this machine runs two graphical sessions at once,
so hanging it off the graphical session would start one instance per compositor.

## Changing the targets

Profiles come from `POWER_PROFILE_AC` / `POWER_PROFILE_BATTERY` (defaults
`performance` / `power-saver`). To use `balanced` on battery instead:

```sh
systemctl --user edit power-profile-auto.service
```

```ini
[Service]
Environment=POWER_PROFILE_BATTERY=balanced
```

A drop-in created that way lands in `~/.config/systemd/user/` outside the stow
tree — if you keep it, move it into `systemd/.config/systemd/user/power-profile-auto.service.d/`
in the repo and re-`stow`.

## Checking / debugging

```sh
scripts/power/auto-profile.sh status     # AC state, current profile, what it would set
scripts/power/auto-profile.sh once       # re-sync now
journalctl --user -u power-profile-auto.service -f
tuned-adm active                         # what tuned actually landed on
```

## Verified 2026-07-27

- user unit can switch profiles with no polkit prompt (test above)
- manual change to `balanced` while plugged in survived — watcher did not revert it
- `once` corrected `balanced` → `performance`
- service restart while set to `power-saver` re-synced to `performance`
- **not yet tested on real hardware transition** — needs a physical unplug; watch
  the journal for `on battery: performance -> power-saver`.
