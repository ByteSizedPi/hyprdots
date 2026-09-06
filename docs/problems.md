# Problem log

Running record of issues on this machine. Each entry: **status**, symptom, what
was **tried (worked / didn't)**, root cause (if known), next steps. Start new
work from the **OPEN** items and don't repeat the "didn't work" lists.

Status key: 🟥 OPEN · 🟧 MITIGATED (worked around, root cause unsolved) · 🟩 SOLVED

---

## 🟩 `noctalia config validate` warns on 4 keys — they are legacy names, not dead keys

**Symptom (2026-09-05, after the move to noctalia 5.0.1):**

```
WARN  settings.toml:342:11: widget.cpu.display: unknown setting
WARN  settings.toml:343:14: widget.cpu.show_label: unknown setting
WARN  settings.toml:350:11: widget.ram.display: unknown setting
WARN  settings.toml:372:11: widget.widget_2.capsule: unknown setting
```

The same four keys sit in `themes/noctalia/noctalia.toml` and
`themes/catppuccin/noctalia.toml`, so every theme apply re-seeds them.

**The first three are renames, and 5.0.1 migrates them at load.** The rename
rules are compiled into `/usr/bin/noctalia`. `strings` on the binary finds
them:

```
show_icon is now show_glyph
show_label is now show_value
display is now visualization and show_value
show_glyph, show_value, and visualization cannot all be disabled
```

**Why the validator warns anyway.** It is a validator limitation, not dead
config. `[widget.cpu]` in `settings.toml` declares no `type`, so the validator
cannot resolve which widget schema to check against. Add the type and the same
keys pass:

```
$ printf '[widget.cpu]\ndisplay = "text"\n' > p.toml && noctalia config validate p.toml
WARN  p.toml: widget.cpu.display: unknown setting

$ printf '[widget.cpu]\ntype = "sysmon"\nstat = "cpu_usage"\ndisplay = "text"\n' > p.toml && noctalia config validate p.toml
✓ Config is valid
```

`noctalia config export full` shows the running shell resolving
`widget.cpu` to `type = "sysmon"`, `stat = "cpu_usage"` from built-in defaults.
The shell applies those defaults; the validator does not.

**The fourth warning has a different cause.** `widget.widget_2` is a plugin
widget (`type = "jj/theme-switcher:widget"`). Its `plugin.toml` declares two
settings, `repo` and `confirm_apply`, and no `capsule`. The validator checks
plugin-widget keys against that declared list, so a generic bar key like
`capsule` warns. `widget.clock.capsule` is a builtin and does not warn.

**Not fixed, on purpose.** Modernising the theme files would silence the
warnings, but the old key pair is self-contradictory and the new value cannot
be derived without deciding how the bar should look:

* `display = "text"` maps to `visualization = "none"` + `show_value = true`.
* `show_label = false` maps to `show_value = false`.

Both rules target `show_value` and disagree. Which one 5.0.1 applies first was
not measured. Decide the wanted appearance first, then write the new keys
directly rather than converting the old ones.

**Do not read the warning as "this setting does nothing."** The CPU and RAM
widgets render correctly on 5.0.1 with the legacy keys in place.

---

## 🟩 `sudo dnf upgrade` printed 238 "errors" — they are cosmetic rpm warnings

**Symptom (2026-09-04):** `sudo dnf upgrade` scrolled a long wall of lines that
look like failures:

```
WARNING [rpm] file /lib/modules/7.1.7-200.fc44.x86_64/kernel/drivers/... : remove failed: No such file or directory
```

**Not a problem.** Verified:

1. `sudo dnf history info 111` reports `Status : Ok` (329 packages, 10:15).
2. That transaction removed the 7.1.7 kernel: `kernel`, `kernel-core`,
   `kernel-devel`, `kernel-modules`, `kernel-modules-core`,
   `kernel-modules-extra`, and `kmod-nvidia-7.1.7-...`.
3. `/lib/modules/7.1.7-200.fc44.x86_64` does not exist.
4. `sudo grep -iE '\[(error|critical)\]|error:|WARNING|failed' /var/log/dnf5.log`
   returns 238 lines, all of the pattern above, and **zero** lines of any other
   kind.
5. `sudo dnf upgrade --assumeno` afterwards reported `Nothing to do.`

**Cause (inferred, not verified).** The kernel scriptlets delete the whole
`/lib/modules/<version>` tree first. rpm then tries to unlink the 238
subdirectories it owns and finds them already gone. The count scales with how
many module subdirectories the kernel package owns, so it looks alarming.

**How to check next time.** Do not read the scrollback. Run:

```
sudo dnf history info $(sudo dnf history list | sed -n 2p | awk '{print $1}')   # Status line
sudo grep -iE '\[(error|critical)\]|error:|failed' /var/log/dnf5.log \
  | grep -v 'remove failed: No such file or directory' | tail -40
```

An empty second command means the upgrade was clean.

**Unrelated finding at the time.** An `akmods` build of
`kmod-nvidia-7.1.12-200.fc44.x86_64` was still running and held the dnf lock
("Waiting for a lock on the system repository"). Wait for it rather than using
`--skip-file-locks`.

---

## 🟩 Monitor profiles never applied / eDP-1 stuck at scale 1.5

**Symptom:** the AOC came up at 60Hz on a 144Hz panel, and eDP-1 sat at scale
1.50. The log only ever said `[monitors] no profile matched the connected
monitors`. The profiles had never applied at all — Hyprland's built-in defaults
were doing all the work.

**Root cause.** `hl.monitor()` called at **config-parse time registers a
persistent rule**, and Hyprland applies rules at output connect and on hotplug,
natively ([wiki](https://wiki.hypr.land/Configuring/Basics/Monitors/),
[Lua API](https://alejandrominaya.github.io/hyprland-lua-docs/)). The old
361-line engine only ever called `hl.monitor()` from **deferred timers**, i.e.
always after enumeration — permanently missing the one moment when `scale` is
honoured. Auto-scale then won the initial connect and picked 1.5.

**Second realisation: there were no profiles.** Every monitor's spec was
identical in every profile that named it — no spec depended on what else was
plugged in. "Laptop only" is not a profile, it is what happens when nothing
else is connected. The `ws` and `exec` profile features were never used.

**Fix (2026-07-18) — the engine was deleted, not repaired.**
`hyprland/.config/hypr/modules/monitors.lua` is now a short list of declarative
`hl.monitor()` calls (eDP-1, AOC, Samsung, Hisense TV, catch-all `output = ""`
kept last). `monitor-profiles.lua` is deleted. **`scale = 1` explicitly, never
`"auto"`** — auto-scale choosing 1.5 was the entire original bug.

**✅ CONFIRMED on a cold login, 2026-07-18:** `eDP-1 scale=1.0 pos=0x0 @60` +
`HDMI-A-1 scale=1.0 pos=1920x0 @144`, correct at first connect, no cycling and
no visible glitch.

**Settled a side question:** noctalia had been dying on boot. The old engine's
recovery cycle destroyed eDP-1's output ~1s after `autostart.lua` launched it.
No cycle → no crash, so that was the cause, not a noctalia bug.

### Superseded — do not rebuild any of this
Roughly six iterations of machinery existed before the rewrite: a retry timer
loop, `verify_scale`, a disable/enable cycle to force a reconnect, `suppress_events`,
split-tick timing, and a per-output chain guard. **All of it was compensation
for applying rules too late, and all of it is gone.** `~/.local/state/hypr-monitors.log`
is obsolete and no longer written. Full history is in `git log` for
`modules/monitors.lua` if a genuinely conditional layout is ever needed.

Two real Hyprland behaviours were learned along the way and are still true, but
you should never need them now: forcing a scale change on a *live* output takes
a disable then a re-enable, and those two calls must land in **separate
event-loop turns** or Hyprland coalesces them into a no-op.

### Hyprland Lua config gotchas (learned here — save yourself the time)
- **`hyprctl reload` DOES re-execute the Lua config** (verified 2026-07-17:
  edited code took effect live). An earlier note claimed the opposite; it was
  wrong. Handlers do not appear to duplicate across reloads.
- **Monitor rule `scale` only applies at output (re)connect.** On a live output
  every path silently no-ops — `hl.monitor`, `wlr-randr`, and the monitor
  userdata is read-only. Declare scale at parse time and the problem does not
  arise. Mode, refresh and position apply live just fine.
- **Re-enabling a disabled monitor requires an explicit `disabled = false`** —
  a plain `hl.monitor{output=…, mode=…}` will NOT wake it.
- **Lua `print()` stops reaching hyprland.log almost immediately.** Only prints
  made *before* the early "Disabling stdout logs!" line land; everything from
  timer callbacks and event handlers is silently dropped. **A session with zero
  `[…]` log lines proves nothing.** If you need output from Lua, `io.open()` a
  file and write to it.
- **`hyprctl keyword` doesn't work** with the Lua parser ("keyword can't work
  with non-legacy parsers. Use eval."). Use `hyprctl eval '<lua>'`.
- **`hyprctl eval` discards return values** (prints only `ok`) and its `print()`
  does not reach the log.
- **`hl.get_monitors()` returns `HL.Monitor` userdata**, not plain tables —
  `pairs(m)` errors. Read fields directly (`m.name`, `m.description`).
- **Valid `hl.on` events** (full list, from an error message): `hyprland.start,
  config.reloaded, workspace.active, monitor.layout_changed, hyprland.shutdown,
  workspace.move_to_monitor, monitor.removed, monitor.added, keybinds.submap,
  layer.opened, window.open, window.open_early, window.urgent, monitor.focused,
  window.close, layer.closed, window.destroy, screenshare.state, workspace.removed,
  workspace.created, window.kill, window.active, window.pin, window.title,
  window.fullscreen, window.class, window.update_rules, window.move_to_workspace`
- **`hyprland.start` does NOT reliably fire** for monitors already present at
  enumeration, and `monitor.added` does not fire for them either. Anything that
  depends on either event will silently never run on a cold login.
- **`hl.timer` signature:** `hl.timer(fn, { timeout = <ms>, type = "oneshot"|"repeat" })`.
- **Monitor positions are LOGICAL pixels, so scale changes the math.** At
  auto-scale 1.5 eDP-1's logical width is **1280**, not 1920, so placing the
  neighbour at `1920x0` leaves a 640px gap and content overflows off-screen.
  Rule of thumb: `next_x = previous_width / previous_scale`.
- **`hyprctl monitors` does not reflect a scale change immediately.** Re-read
  after a second before concluding a call failed.
- **Explicit modes beat `"preferred"`.** `preferred` picks 48Hz on eDP-1 and
  60Hz on the AOC. Pin the refresh rate.

---

## 🟩 `hyprctl` fails inside zellij after a re-login (stale instance signature)

**Symptom:** in any zellij pane, `hyprctl` dies with
`HYPRLAND_INSTANCE_SIGNATURE was not set! (Is Hyprland running?)` — or worse,
silently talks to a dead socket. Fine in a fresh kitty window outside zellij.
Appears after every logout/login and has been surfacing for a long time.

**Cause (confirmed 2026-07-18):** the zellij *server* is persistent
(`session_serialization true` in `config.kdl`, deliberately — it's what
resurrects the `main` session across reboots, since Hyprland has no session
restore of its own). That server outlives the graphical session and keeps the
environment frozen from whenever it first started; every pane inherits it. So
after a re-login the signature names a **dead compositor**. Verified directly:
```
/proc/<zellij-server>/environ → HYPRLAND_INSTANCE_SIGNATURE=..._1784358228_...  (dead)
live instance                 → ..._1784358968_...
```
**Only that one var actually matters.** Also checked: `WAYLAND_DISPLAY`
(`wayland-1`) is recreated with the same name each session and
`DBUS_SESSION_BUS_ADDRESS` is the per-user bus, so both stay valid — GUI apps
launched from a pane work fine. `XDG_SESSION_ID` does go stale (2 vs 5) but
nothing here reads it.

**Fix:** `.zshrc` derives the signature instead of inheriting it — the live
instance is the dir under `$XDG_RUNTIME_DIR/hypr/` holding `hyprland.lock`
(dead instances leave the socket dir but no lock). Run at shell init (new panes)
*and* on `precmd` (panes already open across the logout, whose shell still holds
the stale value). Verified: stale inherited value gets overwritten and `hyprctl`
then works; hook registers; no errors when there's no Hyprland (ssh to
jjserver).

**Rejected approaches:** `systemctl --user import-environment` (updates the
systemd user manager — no effect on an already-running zellij server, wrong
layer); restarting the zellij server on login (fixes env, destroys the
persistence this is all for); wrapping `hyprctl` (too narrow — misses
hyprpicker and scripts). Zellij has no equivalent of tmux `update-environment`.

**Known limits:** can't fix an already-running long-lived process inside a pane
— you cannot rewrite another process's environment; shell-level is the ceiling.
And if two *Hyprland* instances ever ran at once, both would hold locks and the
newest wins, which may not be the current tty's.

## 🟥 Hyprland session died silently after ~4 min; re-login landed in Plasma unnoticed
**Symptom (2026-07-17):** "noctalia GUI gone, keybinds dead, eDP-1 scale looks
wrong, but Hyprland feels responsive" — **the session wasn't Hyprland at all.**
`startplasma-wayland`/`kwin_wayland`/`plasmashell` were running on tty1; there
was no Hyprland process. The zellij session survived the compositor swap and
kept the old Hyprland env (`XDG_CURRENT_DESKTOP=Hyprland`,
`WAYLAND_DISPLAY=wayland-1`), which makes the terminal *look* like Hyprland.

**Timeline (journal):**
- 07:00:16 — previous Hyprland session (session-2) SIGTERM'd by systemd;
  greeter comes up. Zen browser SIGSEGV'd when its compositor vanished, and
  `drkonqi-coredump-launcher` itself crash-looped (~30 SIGABRT coredumps in
  ~10s — KDE's crash handler crashing on the crash).
- 07:00:36 — logged into **Hyprland** (noctalia SecretAgent registered).
- 07:04:35 — Hyprland vanished **silently**: no coredump, no OOM-kill, its log
  ends mid cursor/input activity with no shutdown messages. Zen logged
  "Wayland compositor unavailable (hyprland)".
- 07:04:36–50 — greeter again; this login started **Plasma** on tty1
  (greeter default / mis-selection), which the user took to be Hyprland with
  noctalia crashed.

**Diagnosis cues for next time:** `pgrep Hyprland` / `loginctl list-sessions`
first; don't trust the terminal env inside zellij — it outlives compositors.
Plasma-session tells: no noctalia bar, Hyprland keybinds dead, KDE cursor/
font rendering ("scale issues") on eDP-1. Plasma's kscreen state was actually
sane (eDP-1 1920x1080@60 scale 1, AOC @144 at 1920,0).

**Addendum:** during that 07:00–07:04 Hyprland session, noctalia was frozen
07:00:43→07:02:38 by the DNS outage (see the idle entry's root-cause note) —
so "no bars, keybinds dead" was real in that session too, with a different
cause than the Plasma mix-up that followed.

**Open question — why did Hyprland exit?** No crash artifacts at 07:04:35.
Candidates: the known dual-session seat/DRM contention (see tty1 entry), a
Hyprland 0.55.4 bug, or an exit dispatch. **Next steps:** after the next
Hyprland death, immediately check `coredumpctl list`, the tail of
`/run/user/1000/hypr/<HIS>/hyprland.log`, and `journalctl -k` around the
timestamp; consider running Hyprland-only (no Plasma VT) to rule out
contention. Note noctalia was NOT the culprit today — it dies *with* the
session, it didn't kill it.

---

## 🟩 Special-workspace slide stutters on laptop panel when undocked
**Symptom:** undocked (external removed, `laptop` profile active), toggling a
special workspace (`SUPER+S` zellij / `SUPER+A` jjserver) makes the vertical
slide in/out stutter — "low-fps game" choppy. Only the **special** workspace;
normal workspace switches are fine. Smooth again the moment the dock/external is
reconnected.

**Root cause — hybrid-GPU throughput cliff (NOT refresh rate, NOT monitor
config):** this is an Intel Arc iGPU (`i915`, card1) + NVIDIA RTX 500 Ada dGPU
(`nvidia`, card0) laptop. The dock's DisplayPort outputs are wired to the dGPU,
so **docked → dGPU is `D0`/active** with lots of render headroom. **Undocked →**
nothing needs the dGPU, runtime PM (`D3 Enabled (fine-grained)`) puts it to
sleep, and all rendering falls to the **iGPU**. The special-workspace animation
is uniquely expensive — full-screen blur (`decoration:blur size=10 passes=3
special=true`, ui.lua:27-33) re-computed every frame over a *sliding* overlay
(`specialWorkspace* style="slidevert"`, ui.lua:64-66), with `misc:vfr=false`
(ui.lua:92) forcing full-rate render. Every other transition is a cheap `fade`,
so only the special workspace falls off the cliff on the weaker iGPU.

**Diagnosis path:** first (wrongly) blamed refresh rate — the panel exposes a
`1920x1080@47.99` mode and the fallback used `mode="preferred"`, which can pick
48Hz. Pinned the fallback to `1920x1080@60` (kept — good hygiene) but the
stutter persisted, which ruled refresh out. `misc:vrr=0` throughout, so not VRR.
The docked/undocked correlation + dGPU `D0`↔`D3` transition is the tell.

**Fix available but DECLINED (2026-07-15, cosmetic, user chose to leave it):**
set `decoration:blur:special = false` in ui.lua — removes exactly the expensive
per-frame re-blur of the sliding overlay, keeps blur on everything else. Cheaper
alternatives: lower blur `passes`/`size`, or change the special animation from
`slidevert` to `fade`. None applied — the quirk is undocked-only and purely
visual on one animation.

**Lesson:** don't use `mode="preferred"` for panels exposing a low-refresh mode
(pin the refresh — done). And on this hybrid-GPU box, heavy per-frame effects
(blur-on-slide) can stutter undocked once the dGPU sleeps; keep the priciest
animations off the special/overlay path if smoothness undocked ever matters.

---

## 🟥 tty1 Hyprland panel physically dead (while Plasma on tty2)
**Symptom:** switching to the Hyprland VT leaves the laptop panel powered off
("dead, not even black"). Hyprland is alive (numlock LED tracks its config; IPC
responsive).

**Deep dive:** [hyprland-tty1-dead-screen.md](hyprland-tty1-dead-screen.md).

**Tried — did NOT fix:** `hyprctl reload`, `force_renderer_reload`, `dpms off/on`
cycles, explicit `hl.monitor{}` re-modeset, killing noctalia, the libinput lid
quirk + a live eDP "holder". In every case Hyprland reported eDP
`disabled:false` + `dpmsStatus:0` (on) + a successful modeset, yet the panel
stayed dark.

**Key fact / contradiction:** the eDP holder logged **0 re-enables** over ~6 min
— Hyprland's state said "enabled + on" the whole time while the panel was dead.
So the failure is **below** Hyprland's reported state (actual DRM scanout not
reaching the panel).

**Leading hypothesis (untested):** **seat / DRM-master contention** from running
Plasma + Hyprland at once on a **hybrid Intel+NVIDIA GPU**. Evidence: 228×
`Session inactive` + repeated `[libseat] Enabling seat` in the log; earlier
`atomic drm request: failed to commit: Invalid argument (EINVAL)`.

**Ruled out:** session lock (zero ext-session-lock events; `solitaryBlockedBy:
session lock` is a static label), backlight (max), empty workspace/wallpaper.

**Next steps:** reproduce with **only one** graphical session (no Plasma) to
test the contention theory; capture root `dmesg`/i915 DRM errors during a VT
switch; check whether the atomic EINVAL recurs on eDP-only.

---

## 🟧 noctalia idle stranded the session
**Symptom:** after ~10–15 min idle the Hyprland session locked, then the screen
turned off, then became unrecoverable.

**Root cause (known):** noctalia idle behaviours all enabled —
`lock`@600s, `screen-off`@660s, `lock-and-suspend`@900s — and **noctalia
crash-loops** on this box. A crash mid-sequence leaves it locked + screen-off
with nothing left to recover it. (Compounded by the lid/seat display bug above.)

**Fix applied (2026-06-25):** all three idle behaviours set `enabled = false`,
in both the live `~/.local/state/noctalia/settings.toml` (effective now) and the
stowed `noctalia/.config/noctalia/config.toml` (tracked override).

**⚠️ That fix was PARTLY INERT — found 2026-07-27.** `config.toml` does **not**
override `settings.toml`; it's a fallback *underneath* it (see the precedence
problem below). `settings.toml` had `screen-off.enabled = true` the whole time, so
the `config.toml` block never suppressed it — **screen-off@660s was live**, not
disabled. `lock` and `lock-and-suspend` were genuinely off, but only because
`settings.toml` also said so.

**Current, deliberate state (2026-07-27):** `screen-off` **enabled** @660s;
`lock` and `lock-and-suspend` **off**. This is the wanted behaviour — the screen
blanks and any input recovers it, with no lock screen to get stranded behind. The
redundant `enabled = false` lines were removed from `config.toml`, which now seeds
only `screen-off` (noctalia's stock default is *all* idle off, so a fresh machine
would never blank without it).

**Root cause of the crashes found (2026-07-17):** noctalia keeps its own log —
**`~/.cache/noctalia/noctalia.log`** (+ rotated `.log.1`) — and it shows the
mechanism. When DNS is broken/unreachable, noctalia's HTTP client (telemetry
ping, community palettes/templates, weather, ECB rates) **blocks the main
poll loop for ~115 s** (`[WRN] [main] poll source 20HttpClientPollSource
dispatch took 115026.2ms`). A Wayland client that stops reading events that
long gets its connection killed by the compositor → noctalia dies with
`fatal: failed to flush Wayland display before poll: Broken pipe` (06:34:11)
or `fatal: failed to read Wayland events: display_error=104` (16 Jul 17:28).
During the freeze the shell is alive but fully unresponsive — no bar, no
menus, IPC keybinds dead — which is exactly what a "crash" looks like from
the outside. **This is an upstream noctalia bug** (network I/O must not run
on / block the Wayland-facing loop) — worth reporting with those log lines.
Meanwhile: if noctalia "crashes", check DNS first, and check its own log
before blaming Hyprland.

**Still open:** whether every historical crash-loop was this (the pid:-1
leaked-surface crash-looping may be a separate defect). → MITIGATED, not
solved.

**Only `lock` and `lock-and-suspend` are the risky ones** — those are what
stranded the session. `screen-off` is deliberately on and is recoverable by
any keypress. Verified live 2026-08-16 in `~/.local/state/noctalia/settings.toml`:
`lock.enabled = false`, `lock-and-suspend.enabled = false`,
`screen-off.enabled = true` @660s. Do not re-enable the two lock behaviours
until noctalia stops crash-looping. (An earlier note here said to keep
`screen_off` off as well; that contradicted the deliberate state above and was
wrong.)

**Worked, also useful:** `noctalia msg caffeine-enable` inhibits idle live;
killing noctalia clears its leaked lock/corner surfaces.

---

## 🟩 noctalia `config.toml` precedence is the reverse of what we assumed
**Symptom:** settings written to the stowed `noctalia/.config/noctalia/config.toml`
appeared to have no effect. Documented as an "override merged over" the live
settings; it isn't.

**Measured (2026-07-27)** with sandboxed `NOCTALIA_CONFIG_HOME` /
`NOCTALIA_STATE_HOME` + `noctalia config export merged`:

| `state/settings.toml` | `config/config.toml` | effective |
| --- | --- | --- |
| `2.0` | `9.0` | **2.0** |
| *(key absent)* | `9.0` | **9.0** |

So: **`settings.toml` wins per key; `config.toml` only fills keys it omits.**
`config.toml` is a fallback layer *underneath* the GUI-managed state — i.e. a
**fresh-machine seed**, not a live override. Any key the Settings UI has ever
written is permanently masked from `config.toml`.

**Consequences:** the 2026-06-25 idle fix above was partly inert. The old advice in
`CLAUDE.md`/`system-overview.md` to "mirror runtime changes into the stowed
`config.toml`" produces silently dead config — corrected in both.

**Also tested (don't re-try):**
- Extra `*.toml` files in `~/.config/noctalia/` are **not** merged — only
  `config.toml` and `user-templates.toml` are read. A drop-in `theme.toml` does
  nothing.
- Flat dotted keys (`bar.default.border_width = 2.0`) and inline-table arrays
  both validate and round-trip exactly (536 keys, 0 drift) — this is what the
  `themes/` tooling emits.

**Fix:** `themes/` + `scripts/desktop-theme/{save,apply,reset}.sh` write the theme surface
**into `settings.toml`**, preserving non-theme keys. See themes/README.md.

---

## 🟩 Launcher settings silently inert — legacy `shell.panel.launcher_*` names
**Symptom (found 2026-07-27):** `noctalia config validate` reported three
`unknown setting` warnings, and the launcher didn't match its configuration.

**Cause:** the keys were renamed upstream. `settings.toml` still carried the old
`shell.panel.launcher_*` names, which noctalia parses but ignores, so the real
`shell.launcher.*` keys sat at their defaults — the **opposite** of what was set:

| stale key (ignored) | set to | real key | was actually |
| --- | --- | --- | --- |
| `shell.panel.launcher_app_grid` | `true` | `shell.launcher.app_grid` | `false` |
| `shell.panel.launcher_categories` | `false` | `shell.launcher.categories` | `true` |
| `shell.panel.launcher_session_search` | `true` | *(removed from schema)* | n/a |

**Fix:** migrated to `shell.launcher.{app_grid,categories}` preserving the original
intent (grid on, categories off); dropped `launcher_session_search`. Validate is now
clean (0 warnings). Added `shell.launcher.*` appearance keys to
`scripts/desktop-theme/keys.conf` so they travel with a theme.

**Lesson:** `noctalia config validate` warnings are not cosmetic — an
`unknown setting` means that setting is doing nothing. Run it after any
config_version bump.

---

## 🟧 Lid switch disables internal panel on VT switch
**Symptom:** log shows, on each VT switch, `New device Lid Switch` →
`Restoring crtc … 1920x1080@60` → `drm: Disabling output eDP-1`, despite ACPI
reporting the lid **open**.

**Fix applied:** `/etc/libinput/local-overrides.quirks` marks the Lid Switch
`AttrLidSwitchReliability=write_open` (logged in [../SYSTEM.md](../SYSTEM.md)).

**Uncertain:** likely **not** the real cause of the dead screen — the holder
showed eDP staying `enabled` while still dark (see the OPEN item). May be a
secondary effect of the seat flapping. Keep the quirk (harmless); revisit. If
the lid ever needs fully ignoring, use a udev `LIBINPUT_IGNORE_DEVICE=1` rule.

---

## 🟩 xdg-desktop-portal-hyprland running in KDE sessions
**Symptom:** `xdg-desktop-portal-hyprland` starts at KDE login and stays
running alongside `xdg-desktop-portal-kde`. Caused spurious ScreenCast/
Screenshot portal conflicts; contributed to instability.

**Root cause:** `~/.config/xdg-desktop-portal/portals.conf` had
`default=hyprland;kde;gtk`, making the Hyprland portal the first choice for
all sessions including KDE. The existing `plasma-xdg-desktop-portal-kde.service.d/not-hyprland.conf`
drop-in prevented the reverse (KDE portal in Hyprland) but there was no
equivalent for the Hyprland portal in KDE.

**Fix applied (2026-06-26):** Added
`systemd/.config/systemd/user/xdg-desktop-portal-hyprland.service.d/hyprland-only.conf`
(stow-tracked) with `ExecCondition=sh -c '[ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]'`.
Mirrors the pattern already used for xwaylandvideobridge and the KDE portal.
Note: portals.conf `default=hyprland;kde;gtk` is left as-is — the ExecCondition
is the gate; portals.conf having hyprland listed is still needed so Hyprland
sessions actually activate the hyprland portal.

---

## 🟧 KDE logout hangs — plasma-shutdown stuck waiting for ksmserver
**Symptom:** clicking Log Out in KDE shows the confirmation dialog; after
confirming, nothing happens. `plasma-shutdown` process starts and remains stuck
in poll() indefinitely (confirmed >20 min).

**Root cause (suspected):** ksmserver opens a connection to PulseAudio/PipeWire
at logout time (observed via socket inspection) — likely to play the logout
notification sound — and never gets a response. ksmserver blocks; plasma-shutdown
blocks waiting for ksmserver. `ksmserver-logout-greeter` also crashed twice in
the previous session (SIGABRT, no crash files left), possibly the same hang
manifesting differently.

**Workaround:** `loginctl terminate-session $(loginctl | awk '/jj/{print $1}')`

**Not tried yet:** disable the KDE logout sound (System Settings → Notifications
→ Applications → System Notifications → Logout event → set to silent). This is
the most likely fix if the PulseAudio hypothesis is correct.

**Not Hyprland-related.** Happens in KDE-only sessions.

---

## 🟧 KDE plasmashell / kactivitymanagerd SIGBUS crashes
**Symptom:** plasmashell crashes with SIGBUS (signal 7) in
`KSycocaDictPrivate::offsetForKey` (KRunner WebshortcutRunner plugin reading
the KSycoca binary cache). kactivitymanagerd crashes with SIGBUS in
`walIndexTryHdr` (SQLite WAL index shared-memory access). Both recover
(restart) but cause visible shell disruption.

**Root cause:**
- *KSycoca SIGBUS:* the sycoca cache file was truncated/replaced by
  `kbuildsycoca6` while plasmashell had it mmap'd — classic race. Trigger was
  Kvantum Manager (theme change) running just before the crash (16:14:16 →
  crash 16:14:37). Rebuilt sycoca (2026-06-26): `rm ~/.cache/ksycoca6*; kbuildsycoca6`.
- *SQLite WAL SIGBUS:* the `-shm` WAL index file becomes corrupt/truncated
  after a cascade crash, and the next process instance gets SIGBUS reading it.
  The warning "Database can not be opened in WAL mode — whether your filesystem
  supports shared memory" is logged on every Plasma start; home is btrfs+zstd
  which can have mmap edge cases. kactivitymanagerd self-recovered after
  deleting/recreating its WAL files post-crash.

**If it recurs:** `rm ~/.cache/ksycoca6* && kbuildsycoca6` for the KSycoca
crash. For kactivitymanagerd: `systemctl --user stop org.kde.ActivityManager`
then delete `~/.local/share/kactivitymanagerd/resources/database*` and restart.

**Not Hyprland-related.** The cascade was triggered by a theme change, not
anything cross-compositor.

---

## 🟩 zellij resurrection: "Waiting to run: claude" → "Command not found"
**Symptom:** zellij persists sessions (`session_serialization true`) and after
a resurrection, a pane that was running `claude` shows `Waiting to run:
claude` (intended — same as any other app). Pressing Enter, though, prints
`Command not found: claude`, even though typing `claude` manually in that same
pane immediately afterward works fine.

**Root cause — confirmed by reading `/proc/<pid>/environ` of the running
zellij server:** `PATH=/usr/local/bin:/usr/bin`, no `~/.local/bin`. `claude`
lives at `~/.local/bin/claude`, which only ever gets onto `PATH` via line 2 of
`.zshrc` — i.e. only once a real interactive zsh starts and sources it. The
zellij **server** was never started by an interactive shell (it's spawned via
the Hyprland `exec-once`/kitty chain), so it kept whatever bare PATH it
inherited at launch, for its entire lifetime. When resurrection runs the
captured command on Enter, it execs the literal binary name directly using
the *server's* environment, not a fresh login shell — so anything living only
in `~/.local/bin` or `~/bin` fails, while anything in `/usr/local/bin` or
`/usr/bin` resolves fine. Pressing Esc (or typing manually afterward) gets you
a real interactive shell, `.zshrc` runs, `PATH` gains the prepend, and it
works — hence "worked when I typed it right after."

Compounds with an open upstream zellij bug where resurrected panes always
start suspended ("Waiting to run") regardless of config —
[zellij#4754](https://github.com/zellij-org/zellij/issues/4754), similar to
[#4413](https://github.com/zellij-org/zellij/issues/4413) and
[#4129](https://github.com/zellij-org/zellij/issues/4129). That part isn't
fixable locally; the command-not-found part is.

**Fix (2026-07-27):** added `~/.config/environment.d/dotfiles-path.conf` (stow
package `environment`, see system-overview.md → "Session environment / PATH")
prepending `~/.local/bin:~/bin` to `PATH` at the systemd --user session level,
so it reaches the zellij server (and anything else long-lived spawned in the
session) instead of only interactive shells. **Requires a fresh
login/reboot** to take effect — already-running zellij servers keep their old
env until restarted.

**Separately, still open (not fixed by the above):** resize-induced duplicate
prompt lines / scrollback corruption with the two-line `bira` prompt. Confirmed
upstream zellij bug, not kitty- or Alacritty-specific — reproduces with
Kitty + zsh/Powerlevel10k too, and the reporter confirmed the *same* resize
works fine in Kitty without zellij, isolating it to zellij's own VT/redraw
handling. [zellij#321](https://github.com/zellij-org/zellij/issues/321),
[#3675](https://github.com/zellij-org/zellij/issues/3675),
[#36](https://github.com/zellij-org/zellij/issues/36). No known workaround;
nothing to do here but wait on upstream.

---

## 🟧 noctalia can't turn Bluetooth *on* (only manage it once it's already up)
*Mechanism fully identified and fixed; the original trigger is bounded to one
overnight window but not retro-provable — hence MITIGATED, not SOLVED.*
**Symptom:** with Bluetooth off, noctalia's Bluetooth toggle does nothing — it
can't bring the radio up at all. Once it's up by some other means, noctalia
manages devices and toggles on/off normally. Asymmetric: it can power *down* but
never *instantiate*.

**Root cause — two layers of rfkill, and noctalia only reaches the upper one.**
```
dell-bluetooth   <- platform killswitch, dell_laptop driver (ACPI/SMBIOS)
      |             cuts POWER to the BT radio on the USB bus
      v
    hci0         <- per-adapter rfkill; only EXISTS when the radio has power
      |
      v
   BlueZ /org/bluez/hci0   <- the only thing noctalia talks to
```
While `dell-bluetooth` is soft-blocked the radio is unpowered, so no `hci0`
device is created, so **`/org/bluez/hci0` does not exist**. Verified: with the
block on, `rfkill list` shows no `hci0` entry, `bluetoothctl list` is empty, and
`busctl tree org.bluez` returns a bare `/org/bluez` with no children.

noctalia toggles Bluetooth the way bluedevil / gnome-bluetooth / waybar do — by
setting `Powered` on `org.bluez.Adapter1` at `/org/bluez/hci0`. With no adapter
object there is no property to set. Nothing in the desktop layer can fix this;
the platform killswitch is below BlueZ entirely.

**Not a permissions problem.** `/dev/rfkill` carries a logind uaccess ACL giving
`jj` `rw` while our session is active on seat0 — `rfkill block/unblock bluetooth`
round-trips fine *unprivileged*. noctalia could implement this; it just doesn't.

**Also corrupts boot.** `systemd-rfkill` restores the saved block mid-firmware-
download, so a blocked boot logs alarming Intel errors that are a *symptom*, not
a separate fault (`-19` = `ENODEV`, device yanked out from under the loader):
```
09:42:07 systemd-rfkill.service starting...        <- restores block=1
09:42:07 hci0: Found device firmware: intel/ibt-0180-0041.sfi
09:42:07 hci0: Failed to send firmware data (-19)
09:42:07 hci0: FW download error recovery failed (-19)
```
It persists across reboots via `/var/lib/systemd/rfkill/platform-dell-laptop:bluetooth`.

**noctalia cannot recover from this, proven via its own IPC.** With the platform
switch blocked:
```
$ noctalia msg bluetooth-status   -> off
$ noctalia msg bluetooth-enable   -> error: bluetooth adapter unavailable
```
noctalia 5.0.0 *does* ship rfkill-unblock code (`strings` shows `setPowered:
rfkill unblock failed ({}), trying BlueZ Powered anyway`, `setRfkillSoftBlocked`,
`applyRfkillState`) — but that code is **gated behind an adapter already
existing**. It bails at the `adapter unavailable` check before ever reaching the
unblock. Ordering bug; worth filing upstream. That gate is the whole reason a
recoverable rfkill state became a one-way trap from the UI.

**Ruled out as the cause (don't re-investigate these):**
- **noctalia's own disable.** `noctalia msg bluetooth-disable` only sets BlueZ
  `Powered=false`; verified both rfkill switches stay clear and `hci0` stays
  present. It does *not* touch the platform switch. Exonerated.
- **Plasma / bluedevil.** Not logged into Plasma for 10+ days, and BT was working
  Jul 20 — well after the last Plasma session. Exonerated.
- **Own config.** `grep -rn rfkill` across the whole repo returns only this unit;
  no Hyprland bind or script touches rfkill or airplane mode. Exonerated.
- **`systemctl start bluetooth`** is *not* what revives it, despite seeming to.
  `bluetooth.service` had been active 7h with zero adapters. bluetoothd starting
  cannot clear a platform killswitch.

**Timeline.** Last verified working: **2026-07-20 20:18**, wireplumber streaming
audio to paired device `88:C6:26:EE:5F:0B` over `/org/bluez/hci0`. Dead from boot
`-7` (**2026-07-21 08:16**) onward — 6 boots with no adapter at all. Journal only
goes back to Jul 11, and the Jul 20→21 shutdown has no system-phase records (its
journal ends at user-manager `exit.target`), so the original trigger is **not
retro-provable** — only bounded to that overnight window.

**Leading hypothesis for the origin (unproven).** Every shutdown that *does* have
records (boots -4, -3, -2, -1) shows the kernel emitting an rfkill state change
**~1s after `systemd-rfkill`'s watcher was already torn down**:
```
22:01:41 systemd-rfkill.socket: Deactivated successfully.
22:01:41 Closed systemd-rfkill.socket ... /dev/rfkill Watch.
22:01:42 sys-devices-virtual-misc-rfkill.device: Failed to enqueue SYSTEMD_WANTS
         job, ignoring: Transaction for systemd-rfkill.socket/start is destructive
```
So the `dell_laptop` driver asserts the killswitch as part of radio power-down on
every poweroff. Normally that lands too late to be persisted — but the teardown
and the event are ~1s apart, so a shutdown where the event wins the race would
have `systemd-rfkill` save `soft=1`, poisoning every subsequent boot. Not caught
in the act; would need a reboot with the state file watched to confirm.

**The "Dell wireless Fn key" angle.** `dell_rbtn` is loaded but has **no active
input device** (refcount 0). The device that carries an rfkill handler is
`Dell WMI hotkeys` — `/dev/input/event18`, `H: Handlers=kbd event18 rfkill`. So a
Dell WMI hotkey *can* toggle rfkill, making an accidental press a live candidate,
but there is no evidence one was pressed. To test: run `rfkill event` and press
the airplane/radio key. (`evtest` is not installed on this machine.)

**Fix (2026-07-27):** `bluetooth-unblock.service` in the `systemd` stow package —
`Type=oneshot` running `rfkill unblock bluetooth`, `WantedBy=default.target`.
Deliberately *not* `graphical-session.target` (same reasoning as
`power-profile-auto.service`: two graphical sessions at once, and this only
touches `/dev/rfkill`). `ExecStartPre` waits up to 30s for `/dev/rfkill` to
become writable, because the uaccess ACL can land *after* the user manager
reaches `default.target`.

**Verified on hardware:** blocked bluetooth → `bluetoothctl list` empty and
`org.bluez` not even activatable → started the unit → `hci0` rfkill entry back,
controller `A0:D3:65:F5:10:67` present, `/org/bluez/hci0` and its paired-device
child back on the bus. Note this only runs at login, so deliberately blocking BT
mid-session for battery still works and is respected until next login.

Login-time is the right layer *because* the persisted-block mechanism is a
boot-time restore — the unit is idempotent and doesn't depend on ever identifying
every possible blocker. Remaining gap: a block asserted **mid-session** (e.g. the
WMI hotkey) still needs a manual `rfkill unblock bluetooth` until next login.

**Holding well — checked 2026-08-16 (three weeks on):**
```
rfkill list bluetooth   -> dell-bluetooth soft:no hard:no ; hci0 soft:no hard:no
bluetoothctl list       -> Controller A0:D3:65:F5:10:67 jj-laptop [default]
bluetooth-unblock.service -> enabled, active
/var/lib/systemd/rfkill/platform-dell-laptop:bluetooth -> 0
```
The persisted state file reads `0`, so the shutdown race has not re-triggered
since the unit went in. That is not proof the race cannot happen — the unit
clears the block at login either way — only that it has not recurred.

**Still open / next steps if it recurs:**
1. File the noctalia gating bug (rfkill unblock unreachable when no adapter exists).
2. If it recurs often, consider masking `systemd-rfkill` — but that also drops
   wifi rfkill persistence, so prefer the unit.

---

## 🟩 hyprglass: plugin never loads at startup, and its config never applies
> **Re-enabled 2026-07-28 (second attempt) and verified toggling.** The earlier
> parking was triggered by glass looking wrong on non-glass themes; the actual cause
> was found on re-setup — `themes/liquidglass/hypr/layers.lua` had been overwritten
> with the full 5-rule `_base` set, so the four namespaces glass.lua claims were
> being blurred twice. Fixed by restoring the 1-rule version. Toggling itself was
> never broken: verified across repeated on/off cycles and both directions of
> `apply.sh`, plus an extra reload while off to confirm it stays off.
>
> **The failure mode to remember:** `save.sh` captures the LIVE `layers.lua`. Saving
> liquidglass while a non-glass theme's rules are installed silently pulls the full
> rule set into the glass theme, and the only symptom is that glass looks muddy. If
> that happens, count the `layer_rule` calls in `themes/liquidglass/hypr/layers.lua`
> — 5 means clobbered, 1 is correct.
**Symptom:** `hyprpm enable hyprglass` made glass appear, but nothing loads the
plugin at session start — it was live only because `hyprpm` had been run by hand.
Separately, `hypr/plugins/hyprglass.lua` was never `require`d, so even while
loaded, none of its config was in effect.

**Context (2026-07-28):** investigated while designing per-theme plugin support —
hyprglass should be ON only for a (not yet built) liquid-glass theme, OFF for
comicmono/paper_bw. Hyprland 0.56.0, hyprglass 1.0.0.

### Tried — DIDN'T work
- **`hl.plugin.load("<abs path to .so>")` in the Lua config.** Documented on the
  wiki as the way to register a plugin, but on 0.56.0 it **fails silently**:
  from a cold (unloaded) state it returns success (`load_ok=true, err=nil`) while
  `hl.plugin.<name>` stays `nil` in the same parse, the guarded config block is
  skipped, and `hyprctl plugin list` still shows `no plugins loaded` after the
  parse, after a second `hyprctl reload`, and minutes later. Same from
  `hyprctl repl` at runtime. **The return value is not trustworthy — don't use
  this call to gate anything.**
  One non-reproducible success (plugin appeared after a reload following a
  repl-registered load); three subsequent attempts failed. Not understood.
  *Caveat:* only tested via `hyprctl reload`, never a real compositor start —
  it may work on the initial parse at launch. Untested because restarting
  Hyprland here risks the tty1 dead-panel issue (see below).
- **`hyprctl keyword plugin:hyprglass:*`** — dead under the Lua parser, as
  already noted in the Lua gotchas section above.

### Tried — WORKED
- **`hyprpm reload -n`** loads it reliably, every time.
- **`hyprctl plugin unload <so>`** is clean — three unload/load cycles, no crash.
  Safe to iterate on glass settings this way.
- **Per-theme enable/disable via config fragment.** `hg.config({ enabled = false,
  default_preset = "subtle" })` at parse time gave `enabled: int:0 set:true` and
  `default_preset: str:subtle set:true`, and held across a further reload.

### Two behaviours that drive the design
1. **`hyprctl reload` keeps plugins loaded but resets all their options to
   defaults.** Verified: set `enabled=false` → `int:0 set:true`; after reload →
   `int:1 set:false`, same plugin handle. Because hyprglass defaults to
   `enabled = true`, **a theme that says nothing about hyprglass gets glass with
   default settings.** So the theme tooling must *always* emit an explicit
   fragment (real config, or a disable stub) — this is load-bearing, not defensive.
2. **`hyprpm reload -n` runs after config parse**, so on a cold start the
   `if hl.plugin.hyprglass` guard is skipped and no theme glass config applies —
   landing in exactly the default-on state above. Autostart therefore has to load
   *then* re-parse:
   `hyprpm reload -n && hyprctl reload config-only`
   (`config-only` avoids re-running monitor reload — see the monitor entry above.)

### hyprglass vs Hyprland layer blur — they do NOT deconflict
`manage_window_blur` (default on) auto-sets `noblur` on glassed **windows**.
There is **no layer equivalent**: `hkRenderLayer` (`src/main.cpp`) composites glass
and never touches Hyprland's layer blur, so a `layer_rule{ blur = true }` on a
glassed namespace runs both — two blur passes, wrong result. Layer rules must
therefore be **theme-owned**: dropped for namespaces a glass theme claims.

### hyprglass namespace matching is EXACT — no regex
`shouldGlassLayer` uses `unordered_set::contains(ns)`; per-namespace presets use
`map::find(ns)`. Hyprland's `layer_rule` takes a regex, hyprglass does not, so
patterns that work in `windowrules.lua` will silently match nothing in `hg.layer()`.
**An empty whitelist glasses everything** (`if (include.empty()) return true;`) —
including the wallpaper layer.

### Live noctalia layer namespaces (measured 2026-07-28)
| namespace | source |
|---|---|
| `noctalia-bar-default` | the bar — suffix is the **bar name**, so renaming/adding a bar silently breaks an exact-match whitelist |
| `noctalia-panel` | **all** panels — launcher, control-center, wallpaper and session are indistinguishable at the namespace level |
| `noctalia-notification` | notifications |
| `noctalia-osd` | OSDs |
| `noctalia-screen-corner` | screen corners |
| `noctalia-wallpaper` | wallpaper — must never be glassed |
| `noctalia-desktop-widget-<widget>-<16 hex>` | desktop widgets — **per-instance IDs, cannot be exact-matched** |

Consequence: a whitelist can cover bar/panel/notification/osd/screen-corner but
**not** desktop widgets. To include those the only route is the inverse — empty
whitelist (glass all) plus `exclude` on `noctalia-wallpaper`, which is stable.

Also: `windowrules.lua` has a rule for `^noctalia-attached-panel$`, which never
appeared in any capture — likely dead.

### Fix in place (2026-07-28)
Implemented in the `refactor(hyprland)` commit:
- `modules/plugins.lua` runs `hyprpm reload -n && hyprctl reload config-only` on
  `hyprland.start` — load, then re-parse so theme glass config actually applies.
- `themes/<name>/manifest.conf` carries `hyprglass = on|off`;
  `themes/<name>/hypr/glass.lua` carries the config.
- `apply.sh` always writes `theme/glass.lua`, using an explicit disable stub when
  off. Verified live: stub gives `enabled: int:0 set:true` and survives reloads.
- Layer rules moved to `theme/layers.lua` so a glass theme can cede namespaces.

**✅ VERIFIED on a live session, 2026-08-16.** The autostart chain works
end-to-end:
```
hyprctl plugin list                       -> hyprglass 1.0.0, handle 555e6e2b4ce0
hyprctl getoption plugin:hyprglass:enabled-> int: 0   set: true
themes/active                             -> noctalia  (manifest: hyprglass = off)
```
`set: true` with the plugin loaded is the whole design working: `hyprpm reload -n
&& hyprctl reload config-only` loaded it, and the theme's explicit **disable
stub** then applied. Without the stub this would read `set: false` and glass
would default on. Also confirmed `themes/liquidglass/hypr/layers.lua` still has
**1** `layer_rule` (5 would mean clobbered — see the note at the top).

**Still open — one item:** does `hl.plugin.load` behave differently on the
initial startup parse? If it works there it is the tidier path and
`modules/plugins.lua` could drop the re-parse. Untested because restarting
Hyprland risks the tty1 dead-panel issue above. Low value — the current chain
is verified working.

**`noctalia-attached-panel` is very likely dead.** It has never appeared in any
layer capture, including a live one on 2026-08-16. Not proven, since a
namespace only shows while its surface exists — but nothing has ever produced
it. Its layer rule was dropped in the restructure with no ill effect.

---

## 🟩 kitty.conf is not stowed — live config drifted from the repo
**Symptom:** found 2026-07-28 while wiring per-theme app overlays. Every other file
in `~/.config/kitty/` is a symlink into this repo (`ssh.conf`, `jjserver.conf`,
`dank-*.conf`, `themes/`), but **`kitty.conf` itself is a real file**. There's a
`kitty.conf.bak` next to it from 2026-06-15, which is the fingerprint of something
rewriting the config in place — almost certainly `kitten themes`, which replaces
`kitty.conf` (symlink and all) and leaves a `.bak`. The `BEGIN_KITTY_THEME` markers
that were in the repo copy are its signature.

**What drifted.** Only two differences, but both matter:

| | repo (`HEAD`) | live |
| --- | --- | --- |
| palette include | `include current-theme.conf` | `include themes/noctalia.conf` |
| `map ctrl+shift+t no_op` | present | **missing** |

- The **live** file is right about the palette: `themes/noctalia.conf` is rewritten
  by Noctalia on every theme change (timestamped today), while
  `current-theme.conf` has been stale since 2026-07-20 and nothing updates it.
- The **repo** file is right about the keybind: `map ctrl+shift+t no_op` stops
  kitty's OS-level tabs stacking on top of zellij's tabs. That fix is **not in
  effect right now**.

**Fixed in the repo (2026-07-28):** `kitty/.config/kitty/kitty.conf` now has the
correct `themes/noctalia.conf` include, keeps the keybind, and gains
`include theme-extra.conf` for per-theme settings (see `scripts/desktop-theme/apps.conf`).

**Resolved 2026-07-28.** Checked first that the repo copy was a strict superset of
the live one — it had the two lines above and the live file had nothing the repo
lacked — then:

```bash
rm ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.bak
stow -R kitty
```

`~/.config/kitty/kitty.conf` is a symlink into the repo again, the `ctrl+shift+t`
fix is live, and `include theme-extra.conf` now actually loads the per-theme
overlay. Both deleted files were backed up first.

Leftover, harmless: `~/.config/kitty/current-theme.conf` is still on disk but
nothing includes it any more. Delete it whenever.

**Avoid re-breaking it:** don't run `kitten themes` — it rewrites `kitty.conf` and
will clobber the symlink again. Palette changes go through Noctalia.

**Worth auditing:** other packages may have the same silent un-stowing. A quick
check is to look for real files sitting among symlinks in each `~/.config/<app>`.

---

## 🟩 Noctalia appends `require("noctalia")` to hyprland.lua if it isn't there
**Symptom:** after the 2026-07-28 re-login, `hyprland.lua` had grown a stray
`-- For Noctalia Color templates` / `require("noctalia").apply_theme()` at the end —
a duplicate, since `theme/init.lua` already called it. File mtime matched the login
to the second.

**Cause:** `/usr/share/noctalia/assets/templates/hyprland/apply.sh` (a builtin
template post_hook) does exactly this:

```bash
if ! grep -qF 'require("noctalia")' "$lua_config_file"; then
  printf '\n%s\n' "$include_line" >>"$lua_config_file"
fi
```

It greps **`hyprland.lua` only** — not the rest of the config tree. The modular
restructure had moved that call into `theme/init.lua`, so the string vanished from
the file Noctalia checks and it helpfully put one back.

**Fix:** the call lives in `hyprland.lua` again, as the last line (where it has to
be anyway — the palette must override earlier border colours), with a comment saying
why it can't move. `theme/init.lua` documents the exception rather than making the
call. Verified: running the post_hook by hand no longer appends.

**Rule of thumb:** the literal string `require("noctalia")` must stay in
`hyprland.lua`. Splitting the config further is fine; moving *that line* is not.

---

## 🟩 save.sh "Permission denied", and it silently clobbered a theme
**Symptom (2026-07-28):** the Noctalia theme-switcher panel's **Update** button
reported `Permission denied`. From a shell:
`save.sh: line 103: /NOTES.md: Permission denied`.

**Cause: a shell variable clash I introduced.** `save.sh` sets `dest="$themes/$name"`
at the top, and the per-app overlay loop added later read into the *same* name:

```bash
while IFS=$'\t' read -r app dest reload; do   # <-- clobbers $dest
```

Process substitution (`< <(apps_list)`) runs the loop in the current shell, not a
subshell, so `$dest` really was overwritten — and the final failing `read` clears
its variables, leaving `dest=""`. Everything after the loop then wrote to `/`:
`"$dest/NOTES.md"` → `/NOTES.md` → denied. Fixed by renaming the loop variables to
`app_dest` / `app_reload` in apply.sh, reset.sh and save.sh. (`common.sh`'s own loop
was already safe — it declares `local app dest reload`.)

**The damage was worse than the error suggested.** `save.sh` wrote its outputs
one-by-one directly into `themes/<name>/`, so dying part-way left a *half-updated*
theme. During the confusion `themes/liquidglass` ended up overwritten with a
non-glass look — `hyprglass = on` flipped to `off`, `apps/kitty.conf` deleted,
`hypr/layers.lua` replaced with the long base version. Recovered with
`git checkout -- themes/liquidglass`; the lesson is that **committing a theme is
what makes it recoverable.**

**Hardening:** `save.sh` now builds the whole theme in a staging dir
(`themes/.<name>.staging.XXXXXX`, seeded from the existing theme so NOTES.md and an
off-state glass.lua survive) and only swaps it into place once every write has
succeeded. A mid-run failure now leaves the theme byte-for-byte untouched — tested
by making the target unwritable mid-save.

**Also worth knowing:** `bar.*` is a theme key, so **which widgets are on your bar
travels with the theme.** Adding the theme-switcher widget and saving `comicmono`
captured it into that theme only; applying a different theme will remove it until
that theme is re-saved too. Deliberate (widget layout is part of a look) but easy to
trip over — see `keys.conf`.

---

## 🟩 liquidglass dimmed video and images, not just chrome

**Symptom:** on `liquidglass`, YouTube video (and any photo, PDF or map) rendered
washed out, as if a haze sat over it. Terminals looked right; it was specifically
content that should have been opaque.

**Cause:** `decoration:active_opacity` / `inactive_opacity` were `0.85` in
`themes/liquidglass/hypr/appearance.lua`. Hyprland's opacity applies to the **entire
window surface** and it has no concept of "chrome" vs "content" — so buying glass
behind a terminal background that way necessarily dims video at the same rate.

The confusing part is that it looked like a hyprglass problem and wasn't. hyprglass
draws its slab *behind* the window, so glass genuinely does require a translucent
window — which is why the 0.85 was there and why the comments in both
`appearance.lua` and `glass.lua` presented it as mandatory. It isn't: the requirement
is that the window be translucent **where you want glass**, and Hyprland is the wrong
layer to express that.

**Fix (2026-08-02):** push the alpha down into the apps, which know which pixels are
chrome, and pin Hyprland at `1.0`.

| layer | before | after |
| --- | --- | --- |
| `decoration:active_opacity` / `inactive_opacity` | 0.85 | **1.0** |
| kitty `background_opacity` | 0.62 | 0.53 |
| alacritty `[window] opacity` | 0.62 | 0.53 |
| Zen `noctalia-transparency.css` `:root` tint | 80% | 68% |

The app values are the old ones **multiplied by 0.85**, so the look is unchanged —
only content stopped being dimmed. Zen needed nothing structural: `dotfiles/zen/`
already made *only* the chrome panes transparent and left web content alone, so the
browser now shows glass around a full-contrast video.

`appearance.lua` gained a `translucent = {}` table at the bottom — a per-class
`opacity … override` opt-in for apps that can't do their own alpha and would
otherwise get no glass at all. Empty by default. Anything that displays content does
**not** belong in it; that just re-creates this bug per-app.

**Worth knowing:**
- "This window has no glass" is now the expected result for an opaque app, not a
  fault. Check whether the app is translucent before touching any glass setting.
- The stale comment in `glass.lua` claimed appearance.lua kept opacity at
  `0.88 / 0.80`; it had been 0.85/0.85 for some time. Both files' comments were
  rewritten to describe where translucency actually comes from.
- Zen's tint sits **behind** web content, so raising it can never fix washed-out
  video — if video ever looks hazy again, look for a surface-wide alpha
  (Hyprland opacity, or a `windowrule opacity`), not at the CSS.

---

## 🟩 Four layers set a font, and they disagreed

**Found 2026-08-04.** The terminal, the noctalia bar, and every GTK/Qt window
were on three different families: kitty and noctalia on CaskaydiaCove, GTK and
Qt on Hurmit, and fontconfig's generic `monospace` still falling through to Noto
Sans Mono, untouched. Nothing had ever set all of them together.

Settled on **ZedMono Nerd Font** everywhere, chosen by cycling three candidates
live rather than from a specimen sheet. `scripts/desktop-font.sh <id>` writes all
four layers in one command; `--show` reports what each is on, `--list` what is
installed.

**Two traps found while building it, both silent:**

- **`fc-match` never fails.** Asked for style `BoldItalic` it answers with
  Regular, because fontconfig spells the style `Bold Italic`. kitty's
  `font_features` is keyed by PostScript name, so all four lines ended up naming
  the regular face and ligatures quietly stopped applying to bold and italic.
  The script reads names from `fc-list` per family instead, and the suffixes are
  genuinely not predictable: `CommitMonoNFM` has no suffix at all, `FiraCode`
  abbreviates Regular to `FiraCodeNFM-Reg`, `VictorMonoNFM-Regular` spells it
  out.
- **`sed -i` breaks a stow symlink.** It writes a temp file and renames it over
  the target. The moment `gtk/.config/gtk-{3,4}.0/settings.ini` became a stow
  package, the script's own GTK writer would have un-managed it on the next run.
  Fixed with `sed -i --follow-symlinks`. Same failure mode as the yazi/zen
  templates and `kitty.conf` above — third occurrence, so treat any
  temp-file-plus-rename writer aimed at a stowed path as a bug.

**Not solved, deliberately:** `~/.config/kdeglobals` stays out of the stow tree,
because KConfig also saves by rename and would detach it the first time a Plasma
setting changed. Its font keys are recorded in `SYSTEM.md` instead. The GTK
files were stowed despite carrying kde-gtk-config's `gtk-modules` line, on the
evidence that Plasma had not rewritten them in six weeks — `stow-audit.sh` is
the tripwire if that turns out to be wrong.

**The font is a theme key, so it had to be banked three times.** `bar.*` and
`shell.font_family` match `scripts/desktop-theme/keys.conf`, which means the font
travels with the theme — but kitty's font lives in `kitty.conf` and does not.
Banking into `paper_bw` alone left a trap: switching to `comicmono` or
`liquidglass` would put the bar back on CaskaydiaCove while the terminal stayed
on ZedMono. All three themes now carry `ZedMono Nerd Font Propo` / `ZedMono Nerd
Font`, each verified by merging it against the live `settings.toml` and running
`noctalia config validate` in a sandbox.

**So a new theme starts with the wrong font.** `save.sh` snapshots whatever is
live, so a theme banked while ZedMono is applied inherits it — but a theme copied
from an older one, or hand-written, will not. If the font stops being something
you want per-theme, the fix is to drop `bar.*.font_family` and
`shell.font_family` from `keys.conf` so they stay machine config, and let
`desktop-font.sh` be the only writer.

---

## 🟩 jjlink internet crawled — duplicate IP on the router WAN, plus wrong MTU

**Symptom (2026-08-16).** Internet over `jjlink` was unusable on the laptop and
the phone. Downloads landed anywhere between 0.65 Mbit/s and 89 Mbit/s with no
pattern. The line is ~85 Mbit/s fibre.

**Two independent faults, both introduced during a router config session
earlier the same day.**

### Root cause 1 — duplicate `10.0.0.107` on the house LAN

The TP-Link AX1500's WAN port and an unidentified device both held
`10.0.0.107`. Measured at the same moment from two hosts:

```
laptop   (Wi-Fi, 17 Mozart)  10.0.0.107 = 24:2f:d0:d1:b6:e1   <- TP-Link WAN
jjserver (wired to Nokia)    10.0.0.107 = ba:e0:5e:bf:eb:ee   <- something else
```

Six samples each, both stable. Each host had locked onto whichever answered
its ARP first. Return traffic for the room router's NAT therefore reached the
wrong device roughly half the time.

**Fix:** set the AX1500 WAN to a **static** address outside the Nokia's DHCP
pool. `10.0.0.240`, mask `255.255.255.0`, gateway `10.0.0.254`, DNS `1.1.1.1`.
The Nokia's pool hands out `.100`–`.119`; `.240` and `.250` were free.

### Root cause 2 — MTU 1500 against a 1492 PPPoE path

The Nokia runs PPPoE, so the path MTU is 1492. The AX1500 was passing 1500.
Large packets died silently while small ones passed, which is why TCP connects
completed in 19 ms and then stalled.

```
ping -M do -s 1472 1.1.1.1  ->  From 10.0.0.254: Frag needed and DF set (mtu = 1492)
```

**Fix:** set the AX1500 WAN MTU to **1492**.

### Result

Measured from pve-prod (wired) immediately after the fix:

```
                       before            after
ping loss, pve-prod    48.9 – 57.8%      0%   (60 packets)
TCP, 12x 10 MB         5 dead, 1 slow    9/9 at 9.7–10.4 MB/s
                       6 at ~10 MB/s     (10–12 were Cloudflare HTTP 429)
```

**Confirmed from the laptop on jjlink Wi-Fi**, which is the path that was
originally reported broken:

```
link   jjlink 5 GHz, -42 dBm, rx 1200.9 Mbit/s (chose 5 GHz unaided)
ping   0% loss, 40 packets, 16.3 ms
LAN    185 / 395 / 330 Mbit/s to pve-prod
WAN    11.42  11.42  11.30  11.32  11.25  11.35 MB/s   (CacheFly, 20 MB x6)
```

Six consecutive runs at ~90 Mbit/s with 1.5% spread — full line rate. Before
the fix the same path gave 0.34 MB/s and 75% ping loss.

**Two measurement artefacts to recognise, not faults:** `speed.cloudflare.com`
starts returning **HTTP 429** to the whole household public IP after repeated
testing, and a single stream to a European endpoint (OVH) is distance-limited
to ~1.5 MB/s regardless of local health. Use `http://cachefly.cachefly.net/100mb.test`
with `-r 0-19999999` as the fallback throughput endpoint.

### Dead ends — do not re-tread

- **The roof cable.** Suspected first and cleared. jjserver reached the room
  router's WAN across it with 0–1.1% loss at full line rate.
- **The 2.4 GHz radio.** A single sample per band gave 2.4 GHz 0.65 Mbit/s and
  5 GHz 89 Mbit/s, which looked like a band-scoped limit. It was sampling
  noise. NetworkManager used the **same** cloned MAC (`stable-ssid`) on both
  bands one minute apart, so nothing device-scoped could differ.
- **A leftover guest-network bandwidth cap.** The AX1500 has no bandwidth
  control feature at all, only QoS prioritisation. QoS was off throughout.
- **2.4 GHz channel width and channel 6 congestion.** Disproved by a 113 Mbit/s
  LAN transfer over the same association that gave 0.65 Mbit/s to the internet.
- **ICMP loss figures generally.** The router deprioritises ICMP to its own
  addresses. `ping` to a router management IP is not a valid loss test here.

### Method note — the actual lesson

Every wrong conclusion above came from **one sample per condition** against a
fault that failed about half the time at random. Nothing was reliable until
tests were run as 12 repeated samples, and until the two ends were measured
**simultaneously** rather than in sequence. Do that first next time.

### Topology (supersedes `docs/homelab.md` §7, which is stale)

```
fibre -> Nokia 10.0.0.254 (ISP-managed, SSID "17 Mozart", PPPoE, MTU 1492)
           |- eth -> jjserver 10.0.0.101
           `- eth [roof cable] -> TP-Link AX1500
                                  WAN 10.0.0.240 static
                                  LAN 10.42.0.1, SSID jjlink (2.4 + 5 GHz)
                                    |- eth -> pve 10.42.0.10
                                    |- eth -> pve-prod 10.42.0.11
                                    |- LXC  10.42.0.12 (DNS/AdGuard), 10.42.0.13
                                    `- wifi -> laptop, phone
```

`docs/homelab.md` still says AdGuard is `10.42.0.192` and that this laptop is
`10.42.0.1`. Both are wrong. AdGuard moved to `10.42.0.12`; the laptop relay
was replaced by the AX1500. See `SYSTEM.md` → NetworkManager profiles.

### Still open

- **Laptop-to-router ethernet cable is faulty.** It failed gigabit negotiation
  four times and settled at 100 Mbit/s; `carrier_changes` reached 10.
  ```
  22:51:36 NIC Link is Up 1000 Mbps Full Duplex
  22:51:37 NIC Link is Down          (x4)
  22:51:54 NIC Link is Up 100 Mbps Full Duplex
  ```
  Not a cause of the above — pve-prod on a different cable showed the identical
  50% loss. Costs nothing today since the line is ~85 Mbit/s. The laptop
  normally uses jjlink Wi-Fi anyway; the cable was only for diagnosis.
- **pve's own tailscale daemon** has not returned since the router reboot.
  pve-prod runs on that host and is fine, so only the daemon is down.

---

## 🟩 Fingerprint reader dead — Broadcom CV3+ has no in-tree driver

**Solved 2026-08-17.** The power-button reader had never worked. `fprintd` and
`libfprint` were both installed, `authselect` already had `with-fingerprint`
enabled, and `fprintd-list` still answered `No devices available`. The daemon
was starting on every PAM call and finding nothing, which is what all those
`fprintd.service` lines in the journal were.

**Root cause.** The reader is `0a5c:5865`, a **Broadcom ControlVault 3+**.
Fedora's `libfprint` ships Broadcom support for IDs 5842–5845 only. There was
no `/usr/lib64/libfprint-2/` directory at all, because stock Fedora builds
`libfprint` without TOD (Touch OEM Driver) support. The CV3+ Citadel chip wants
signed firmware and speaks a proprietary encrypted protocol, so an open driver
cannot exist for it. A vendor blob loaded through TOD is the only path.

**Fix.** Swap `libfprint` for the TOD-enabled build from the
`grahamwhiteuk/libfprint-tod` COPR and add the CV3+ blob. Exact packages,
versions, file paths and the undo command are in `SYSTEM.md` → "Fingerprint
reader". Enrolled `right-index-finger`; `fprintd-verify` and `su - jj` both
pass.

### Things that would have cost time

- **No reboot needed**, despite what every guide says. `udevadm control
  --reload-rules`, `udevadm trigger --subsystem-match=usb --action=add`, then
  `systemctl restart fprintd` was enough — the device appeared immediately.
- **An empty print directory is not a failure.** After a successful enrol,
  `/var/lib/fprint/jj/broadcom-cv3plus/` is still empty and
  `/etc/fprintd.conf` still says `[storage] type=file`. The template lives on
  the Citadel chip. Trust `fprintd-list`, not `ls`.
- **`sudo` is useless as a test here.** `/etc/sudoers.d/` has
  `jj ALL=(ALL) NOPASSWD: ALL`, so it never authenticates and always looks like
  a pass. `su - jj` is the real test: `/etc/pam.d/su` pulls in `system-auth` as
  a substack.
- **Don't touch `authselect`.** `with-fingerprint` was already enabled on the
  `local` profile. Enabling it "again" is a no-op at best.
- **Check the firmware versions in the journal before blaming the driver.**
  `fprintd` prints `Current AAI Version` and `SBI Version` on startup. Ours
  (`6.0.55.0` / `48`) matched the package exactly. Upstream's known enrolment
  failure is a mismatch between the on-chip firmware and the blob, and the
  driver will flash the chip to fix it.

### Cost of the fix — read before updating

`dnf swap libfprint libfprint-tod` hands ownership of a **core authentication
library** to a personal COPR that is explicitly outside Fedora's quality and
security process. CV3+ is marked *experimental* by its maintainer, and the only
hardware he tested is not this laptop. If a Fedora update ever fights the COPR,
the recovery is `sudo dnf swap libfprint-tod libfprint` — the password path
keeps working throughout, because `pam_fprintd` is `sufficient` and falls
through to `pam_unix`.

### Not solved — the reader is useless for WebAuthn

Wanting the reader for Authentik logins is what started this, and that part does
not work. **Linux has no platform authenticator.** No browser exposes `fprintd`
to WebAuthn, so the fingerprint cannot back a passkey the way Windows Hello or
Touch ID does. Findings from the search on 2026-08-17:

- **Firefox on Linux supports USB security keys only** — no phone, no QR, no
  hybrid transport. Its "insert and touch your security key" dialog is the whole
  feature set. This is still true in Firefox 153.
- **Chromium on Linux does offer "Use a phone or tablet"** (QR + Bluetooth), and
  that is what got a passkey enrolled in Authentik. Several Fedora users report
  the phone is never found after scanning; it worked here first try.
- In Authentik, **Authenticator attachment must be *No preference* or
  *Cross-platform***. Setting it to *Platform* hides the phone option and puts
  you back at the security-key-only dialog.
- The one route that would use this reader for WebAuthn is a TPM-backed virtual
  FIDO2 token gated on `fprintd` (`mc256/tpm-fido2-thinkpad-linux`: a daemon on
  `/dev/uhid`, keys sealed to the TPM). **Shelved, not tried.** This machine
  meets every requirement (TPM 2.0 STMicro at `/dev/tpmrm0`, `/dev/uhid`
  present, `uhid` built into the kernel, `60-fido-id.rules` already shipped) but
  the project is small, was tested on a ThinkPad with a Synaptics reader, and
  its fingerprint gate is enforced in **userspace, not by the TPM** — which
  means nothing on a box where `jj` is passwordless root anyway.

---

## 🟩 SUPER + swipe to swap the two monitors' workspaces

**Goal (2026-08-22):** a SUPER-held 3-finger horizontal swipe on the touchpad
should exchange the workspaces on eDP-1 and HDMI-A-1. Config lives in
`hyprland/.config/hypr/modules/input.lua`.

**The dispatcher is `hl.dsp.workspace.swap_monitors`** — the Lua name for
`swapactiveworkspaces`. It is not in the LSP stubs by that name, so grepping
`/usr/share/hypr/stubs/hl.meta.lua` for "swapactive" finds nothing. Look under
`HL.DspWorkspaceNamespace` instead.

**Tried, didn't work:**

- `hl.dsp.workspace.swap_monitors("current", "+1")` — two positional strings.
  `hl.workspace.swap_monitors: expected a table { monitor1, monitor2 }`.
- `hl.dsp.workspace.swap_monitors({ "current", "+1" })` — positional table.
  `'monitor1' is required` / `'monitor2' is required`, then `Monitor not found`.
- `action = { ["end"] = fn }` — rejected with `hl.gesture: action callback
  table must define at least one of start, update, end, or finish`. **The error
  message is wrong.** `end` is listed but not accepted. Measured on 0.56.2 by
  registering one gesture per candidate key: `start`, `update` and `finish`
  pass; `end`, `on_end`, `gesture_end`, `done` and `complete` all fail.

**Worked:**

```lua
hl.dsp.workspace.swap_monitors({ monitor1 = "current", monitor2 = "+1" })
```

Named keys. `"current"` is the focused monitor, `"+1"` the next by monitor id.

**Gesture shadowing — order matters.** Hyprland keeps the **first** gesture
registered for a finger count plus direction and refuses later ones:
`hl.gesture: Gesture will be overshadowed by a previous gesture. Previous
HORIZONTAL shadows new HORIZONTAL`. So the modded gesture is declared **before**
the plain `action = "workspace"` one in `input.lua`.

**`mods` is part of a gesture's identity.** Registering `mods = "SUPER"` and
plain 3-finger horizontal together produces **no** shadow error, so a differing
`mods` makes them distinct gestures. The plain workspace swipe therefore does
not also fire while SUPER is held.

**Verifying a Lua config edit:** Hyprland auto-reloads on file change, but the
reload is not written to `hyprland.log`. `hyprctl configerrors` is the check —
it printed the `["end"]` failure with the exact file and line, and prints
nothing now. `hyprctl gestures` does not exist (`unknown request`).

---

## See also (existing deep dives)
- 🟧/🟩 **Greeter ghost + dwindle crash + hybrid-GPU + Lua gotchas** —
  [hyprland-plasma-diagnosis.md](hyprland-plasma-diagnosis.md). Read first when
  revisiting greeter/login or Plasma↔Hyprland interactions.
- **Dwindle layout crash on shutdown** — [hyprland-plasma-diagnosis.md](hyprland-plasma-diagnosis.md)
  → ISSUE 2. (The standalone draft bug report was deleted 2026-07-27 as stale: written
  against 0.55.4, never filed, and no Hyprland coredump since the 0.56.0 upgrade.)

---

## 🟩 cliamp played nothing from YouTube Music

**Symptom:** cliamp v1.63.2 would not stream YouTube Music. Time was being spent
in the Google Cloud Console OAuth screens, which is the wrong place to look —
Google was only one of three separate faults, and the least important one.

**Three faults, found in this order.**

**1. OAuth was never completed, and never needed to be.** `~/.config/cliamp/config.toml`
had `[ytmusic]` with a `client_id` and `client_secret`, so the Google Cloud half
was already done. But `~/.config/cliamp/ytmusic_credentials.json` did not exist,
so the consent step had never finished. cliamp's own docs
([docs/youtube-music.md](https://github.com/bjarneo/cliamp/blob/main/docs/youtube-music.md))
say `cookies_from` **skips OAuth entirely**. YouTube Music already runs on this
machine as a Chromium web app on the `Default` profile, so those cookies are
signed in and Google Cloud is not involved at all. Added to `[ytmusic]`:

```toml
cookies_from = "chromium"
```

**2. yt-dlp could not resolve any audio format.** cliamp streams by shelling out
to `yt-dlp` (confirmed by `strings` on the binary: `--cookies-from-browser`,
`-f`, `bestaudio`). Run by hand, yt-dlp 2026.08.19 failed:

```
WARNING: Signature solving failed: Some formats may be missing.
WARNING: Only images are available for download.
ERROR: Requested format is not available.
```

YouTube signs media URLs with a JavaScript challenge, and yt-dlp must execute
that JavaScript to see any audio stream. Two things were missing:

* **A usable JS runtime.** Deno is yt-dlp's default and is not installed. Node
  22.23.1 **is** installed, but Node is only used when `--js-runtimes node` is
  passed.
* **The challenge solver script.** Fedora's `yt-dlp+default` rpm is installed and
  does **not** pull it in — `import yt_dlp_ejs` fails in the system python3.

**3. cliamp passes neither flag.** cliamp only ever passes `-f bestaudio`, so the
flags had to become yt-dlp defaults or every track would fail. That is what the
new **`yt-dlp` stow package** is for: `yt-dlp/.config/yt-dlp/config` sets
`--js-runtimes node` and `--remote-components ejs:github`.

### Tried — DIDN'T work
* `yt-dlp -f bestaudio --cookies-from-browser chromium <url>` with no other
  flags. Cookie decryption succeeded (Chromium was running at the time and it
  still worked), but only image formats resolved.
* Adding `--js-runtimes node` alone. The message sharpened to
  `Remote component challenge solver script (node) was skipped`, but still no
  audio. The runtime was never the whole problem.

### Tried — WORKED
* `--js-runtimes node --remote-components ejs:github` together resolved a real
  stream: `Aphex Twin - Xtal (HQ) | 128.476 kbps | opus`.
* The same two flags moved into `~/.config/yt-dlp/config`, then yt-dlp run with
  **no** runtime flags: same result. This is what makes cliamp work.
* End to end, 2026-09-03: `cliamp --daemon --provider ytmusic --vol -30`, then
  `cliamp queue <music.youtube.com url>` and `cliamp play`. Status went
  `stopped` → `playing`, position advanced 5 → 21 of 294 seconds.

### Still to do
`--remote-components ejs:github` makes yt-dlp **download the solver script from
GitHub at run time**. It works, but a signed package is better. The terra repo
(already enabled) has it:

```
sudo dnf install python3-yt-dlp-ejs
```

Install that, then delete the `--remote-components` line from
`yt-dlp/.config/yt-dlp/config`. The comment in that file says the same.

### Note for the next YouTube breakage
This whole failure mode is **not cliamp's**. It hits anything that shells out to
yt-dlp, and YouTube changes the challenge often. If audio stops again, test
`yt-dlp -f bestaudio --simulate <url>` by hand FIRST. If that fails, the fix is a
yt-dlp update or an ejs update, not a cliamp setting.
