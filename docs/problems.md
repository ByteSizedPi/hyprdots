# Problem log

Running record of issues on this machine. Each entry: **status**, symptom, what
was **tried (worked / didn't)**, root cause (if known), next steps. Start new
work from the **OPEN** items and don't repeat the "didn't work" lists.

Status key: 🟥 OPEN · 🟧 MITIGATED (worked around, root cause unsolved) · 🟩 SOLVED

---

## 🟩 Monitor profiles never applied / eDP-1 stuck at scale 1.5
**Symptom:** plugged in the home AOC monitor and the layout was wrong — it came
up at 60Hz despite being a 144Hz panel. Log showed exactly two lines, ever:
`[monitors] config.reloaded` → `[monitors] no profile matched the connected
monitors`. **The monitor profiles had never actually been applied — Hyprland's
built-in defaults were doing all the work the whole time.**

**Root cause — startup ordering.** Hyprland parses the Lua config *before*
aquamarine/DRM exists. From the log:
```
line  8: [cfg] Using lua config found at .../hyprland.lua
line 14: [Lua] [monitors] config.reloaded      <- our handler runs
line 15: [Lua] [monitors] no profile matched
line 19: Creating an Aquamarine backend!       <- backend starts HERE
line 23: drm: Enumerated device ... Found 1 GPUs
```
So at `config.reloaded` **`hl.get_monitors()` returns an empty list** and nothing
can match. The engine then never got another chance: `hyprland.start` never
fired, and `monitor.added` does **not** fire for monitors already present at
enumeration. Old engine also *disabled* any monitor no profile mentioned, so an
unknown monitor would have gone dark.

**Fix (2026-07-16):** in `monitors.lua`, retry the initial apply on a timer until
the backend reports monitors — `hl.timer(fn, { timeout = 250, type = "oneshot" })`,
re-armed up to 40× (10s ceiling). Plus `monitor-profiles.lua` gained a top-level
`default = "preferred, auto"` applied to any monitor the winning profile doesn't
name (instead of disabling it), with explicit `= "disable"` to opt out.

**Verified** by loading the engine with a stubbed `hl` against real monitors:
matches `home` → AOC `1920x1080@144 @1920x0` + eDP-1 `1920x1080@60 @0x0`; and an
unknown monitor correctly gets `preferred, auto` rather than being disabled.

**Regression, same day (2026-07-16 evening):** eDP-1 came up at `scale: 1.50`
(Hyprland's own auto-scale) again on a fresh login, despite the fix above.
`journalctl` showed **zero** `[monitors]` log lines for the new session — the
engine never ran at all this time, not even the broken 09:53 run that at least
logged something. `hyprctl eval` confirmed `hl.monitor({scale=1})` works fine
called manually, and `hyprctl reload` (which fires `config.reloaded`, not a
real reload — see gotchas below) made the engine run correctly and fix the
scale. That proves the earlier fix's actual gap:

**Real root cause:** the entire engine only ever runs from inside
`hl.on("hyprland.start", function() apply_when_ready(...) end)`. The file's
own header comment already said `hyprland.start` "does NOT reliably fire for
monitors that were already present at enumeration" — but the retry-timer
mitigation built for that is only *reachable* by that same unreliable event.
On a genuine cold login where `hyprland.start` doesn't fire, the retry loop
never starts and nothing ever touches eDP-1's scale. The "Verified" note above
tested the matching logic directly (stubbed `hl`), and the working retest
earlier that day used `hyprctl reload` — both routes bypass this gap, which is
why the fix looked solid before.

**Fix applied (2026-07-16 evening):** `monitors.lua` now also calls
`apply_when_ready("module load")` unconditionally at the bottom of the file,
not only from the `hyprland.start` handler. `hl.get_monitors()` is empty at
parse time either way, so this just enters the same retry-timer path — a
harmless duplicate on runs where `hyprland.start` does fire, the only trigger
on runs where it doesn't.

**Not yet verified across a real restart** — `hyprctl reload` doesn't
re-execute the Lua file (see gotchas below), so this session's live scale was
only patched via a manual `hl.monitor` call + `hyprctl reload`, which doesn't
prove the new module-load call works. Flip to 🟩 once confirmed.

**2026-07-17 morning — verification attempt failed for TWO separate reasons:**
1. The "check hyprland.log for `[monitors]` lines" method is **unusable**:
   Hyprland stops capturing Lua `print()` after its early "Disabling stdout
   logs!" line, and every print that matters (the retry timers) fires after
   that point. Today's real Hyprland session had **zero** `[monitors]` lines —
   indistinguishable from the engine not running at all. Fixed: the engine now
   writes its own timestamped log to **`~/.local/state/hypr-monitors.log`**
   (and still print()s). Re-verified the whole engine with a stubbed `hl`:
   cold start with late backend → `laptop` profile (eDP-1 @60 scale 1),
   AOC hotplug → `home` (@144 at 1920x0), unplug → `laptop` again. All pass.
2. The Hyprland session itself only lived ~4 minutes (07:00:36 → 07:04:35),
   died silently (no coredump, no OOM-kill, log ends mid cursor activity), and
   the 07:04 re-login landed in **Plasma on tty1** without the user noticing —
   see the new entry below. So there was no session to verify against.

**2026-07-17, later — engine verified live, and the REAL scale culprit found.**
The 07:17 cold login ran the engine perfectly (log: cold start → retry →
`applied profile: home`) and yet eDP-1 sat at 1.50. Systematic elimination:
- `hl.monitor` runtime calls: mode/refresh/position **apply live** (HDMI
  144→120→144 worked), but **`scale` is silently ignored** — bundled,
  scale-only, number or string, always `ok`, never applied.
- `wlr-randr --output eDP-1 --scale 1`: also silently ignored (so
  kanshi/shikane could not have fixed this either).
- Monitor userdata is read-only (`m.scale=1` → "attempt to modify read-only
  hl object"); no scale dispatcher in `hl.dsp`.
- **Scale IS honored at output (re)connect**: `hl.monitor{disabled=true}`
  then `hl.monitor{disabled=false, mode=…, position=…, scale=1}` applied
  scale 1 instantly. → **Hyprland 0.55.4 bug: monitor rule `scale` only
  takes effect when the output (re)connects, never on a live output.**
  At cold start the engine's scale=1 gets overwritten by Hyprland's own
  connect-time auto-scale (1.5), and nothing after that could change it.
- Trap found on the way: re-enabling a disabled monitor **requires an
  explicit `disabled = false`** in the spec — a plain spec leaves it dark
  (eDP-1 vanished until re-enabled with the flag).

**Fix (2026-07-17):** `monitors.lua` now (a) always passes `disabled = false`
for normal specs, and (b) `verify_scale()`: 1s after each apply with a numeric
scale, compares actual vs wanted; on drift it disable/enable-cycles the output
(the only thing that applies scale), with `suppress_events` so its own churn
doesn't retrigger profile matching, max 3 attempts, everything logged.
Stub-tested (drift 1.5 → cycle → converge) and live-tested (`hyprctl reload`
with correct state → no churn, scale stays 1). **Remaining check: one cold
login showing `scale drift 1.50 -> want 1 — cycling output` →
`converged` in `~/.local/state/hypr-monitors.log` and eDP-1 at scale 1.**
Then flip to 🟩. Consider reporting the scale-at-connect-only bug upstream.

**2026-07-18 — that cold login happened, and it FAILED. Two bugs found in the
fix itself.** The 09:03 cold boot logged the drift detection working exactly as
designed, then `eDP-1 scale STUCK at 1.50 (want 1) — giving up`. Every log line
appeared **five times**. Two distinct causes:

1. **The disable/enable cycle must span two event-loop turns.** Reproduced
   live: the two calls issued back-to-back inside one `hyprctl eval` left
   eDP-1 at 1.50, while the *same two calls* as separate `hyprctl eval`s (2s
   apart) snapped it to 1.00 immediately. Hyprland coalesces the same-tick
   pair — the output never actually disconnects, so the connect-time scale
   path never runs. `verify_scale` issued them back-to-back, so **the whole
   recovery mechanism was a no-op on every cold boot**. This also explains the
   long-standing "it fixes itself once you poke it" behaviour: manual pokes
   are naturally separate ticks.
   ⚠️ This *narrows* the 07-17 finding above — "scale IS honored at (re)connect"
   is true, but only when the reconnect is real, which needs the split.
2. **Five concurrent verify chains raced each other.** At cold start
   `apply_best_profile()` runs up to 5× (module load, `hyprland.start`,
   `config.reloaded`, one `monitor.added` per output) and each armed its own
   chain. They interleaved: chain B re-enabled the output while chain A still
   had it down, so nothing ever settled and all five hit "STUCK".

**Fix (2026-07-18):** `verify_scale` now (a) re-enables from inside a 400ms
`hl.timer` so the disable and enable land in different turns, and (b) is
guarded by `verify_armed[name]` — one chain per output, with `verify_want[name]`
always holding the newest spec so the single chain converges on the last-applied
value.

Verified in-session: split-tick cycle 1.50→1.00 (the direct proof for #1);
5× duplicate log lines gone after the guard; `hyprctl reload` with a deliberate
scale change (1 → 1.25 → 1) applies cleanly with no churn.
Could not be reproduced in-session (re-plugging makes the connect-time handler
win, and on `hyprctl reload` scale applies live), so it needed a real login.

**✅ CONFIRMED FIXED — cold login 2026-07-18 09:16:**
```
09:16:10 [monitors] eDP-1 scale drift 1.50 -> want 1 — cycling output (attempt 1)
09:16:12 [monitors] eDP-1 scale converged to 1 after re-enable
```
Once, converged, no duplicates. Both bugs above were real and both fixes hold.

**Residual cost (new, open):** the recovery cycle is *visible* — the output goes
down and back up ~1s into the session, which glitches the screen. Worse, the
`hyprland.start` handler launches `noctalia --daemon` at 09:16:09, one second
*before* the cycle destroys eDP-1's output at 09:16:10 — a Wayland client whose
surfaces are on an output that disappears right after it starts is a plausible
way to lose noctalia (it was not running after this boot; no coredump, so it
exited rather than crashed — evidence is circumstantial, not proven).
→ **Proper fix is to never need the cycle:** register the profile specs as
monitor rules at *config-parse* time so Hyprland's connect-time auto-scale never
wins the initial enumeration.

**2026-07-18 — rewritten from scratch. The engine is gone (361 lines → 4 rules.)**
Reviewing the above, the whole apparatus was compensation for one wrong
assumption. `hl.monitor()` called at **config-parse time registers a persistent
rule**, and Hyprland applies rules at output connect *and* on hotplug, natively
([wiki](https://wiki.hypr.land/Configuring/Basics/Monitors/),
[Lua API](https://alejandrominaya.github.io/hyprland-lua-docs/)). The engine only
ever called `hl.monitor()` from *deferred timers*, i.e. always after enumeration
— permanently missing the one moment when `scale` is honoured. Every mechanism
above (retry loop, `verify_scale`, disable/enable cycle, `suppress_events`,
split-tick timing, chain guard) existed to claw back a setting we forfeited by
being late.

Second realisation: **there were no profiles.** Every monitor's spec was
identical in every profile that named it (eDP-1 `0x0` scale 1; AOC `1920x0`
@144; Samsung `1920x0`) — no spec depended on what else was plugged in. "Laptop
only" isn't a profile, it's just what happens when nothing else is connected.
The `ws` and `exec` profile features were never used by any profile.

`monitors.lua` is now four declarative `hl.monitor()` calls (laptop, AOC,
Samsung, catch-all `output = ""`), `monitor-profiles.lua` is deleted, and
`~/.local/state/hypr-monitors.log` is obsolete. **`scale = 1` explicitly, never
`"auto"`** — auto-scale choosing 1.5 was the entire original bug.
Confirmed: luajit syntax check passes; live state after the swap is eDP-1
`scale=1.0 pos=0x0 @60` + AOC `scale=1.0 pos=1920x0 @144`.
Old engine is in `git log` for this file if a genuinely conditional layout is
ever needed.

**✅ CONFIRMED on a cold login, 2026-07-18 (instance `..._1784360807_...`):**
`eDP-1 scale=1.0 pos=0x0 @60` + `HDMI-A-1 scale=1.0 pos=1920x0 @144`, correct at
first connect, **no cycling and no visible glitch**. `~/.local/state/hypr-monitors.log`
was not recreated — nothing is running that could write it, which is the point:
the scale is right because nothing *does* anything. Hyprland applies four rules
at connect, which is all it ever needed.

**Settled a side question:** noctalia survived this login. It had been dying on
boot, and the suspicion was that the recovery cycle destroyed eDP-1's output ~1s
after `autostart.lua` launched it. No cycle → no crash, so that was the cause —
not a noctalia bug. (The *visual glitching* on that boot was separate: a drkonqi
crash-loop, still open below.)

### Hyprland Lua config gotchas (learned here — save yourself the time)
- **`hyprctl reload` DOES re-execute the Lua config** (verified 2026-07-17:
  engine log shows a fresh `module load` on every reload; edited code took
  effect live). An earlier note here claimed the opposite — that observation
  was wrong or predates 0.55.4. Handlers don't appear to duplicate across
  reloads.
- **Monitor rule `scale` only applies at output (re)connect** on a live
  output every path silently no-ops (`hl.monitor`, wlr-randr, userdata is
  read-only). To change scale at runtime: disable the output, then re-enable
  with `disabled = false` + full spec — and the two calls **must be in separate
  event-loop turns** (put the re-enable in an `hl.timer`), or Hyprland
  coalesces them into a no-op. `monitors.lua` automates this (`verify_scale`).
  Mode/refresh/position apply live just fine.
- **Re-enabling a disabled monitor requires explicit `disabled = false`** —
  a plain `hl.monitor{output=…, mode=…}` will NOT wake it.
- **Lua `print()` stops reaching hyprland.log almost immediately.** Only prints
  made *before* the "Disabling stdout logs!" line (very early in startup) land
  in the log; everything printed later — timer callbacks, event handlers — is
  silently dropped. A session with zero `[monitors]` lines proves nothing.
  `monitors.lua` therefore keeps its own log: `~/.local/state/hypr-monitors.log`.
- **`hyprctl keyword` doesn't work** with the Lua parser ("keyword can't work
  with non-legacy parsers. Use eval."). Use `hyprctl eval '<lua>'` instead.
- **`hyprctl eval` discards return values** (prints only `ok`) and its `print()`
  does not reach the log. To get output, `io.open()` a file and write to it.
- **`hl.get_monitors()` returns `HL.Monitor` userdata**, not plain tables —
  `pairs(m)` errors. Read fields directly (`m.name`, `m.description`).
- **Valid `hl.on` events** (the full list, from an error message): `hyprland.start,
  config.reloaded, workspace.active, monitor.layout_changed, hyprland.shutdown,
  workspace.move_to_monitor, monitor.removed, monitor.added, keybinds.submap,
  layer.opened, window.open, window.open_early, window.urgent, monitor.focused,
  window.close, layer.closed, window.destroy, screenshare.state, workspace.removed,
  workspace.created, window.kill, window.active, window.pin, window.title,
  window.fullscreen, window.class, window.update_rules, window.move_to_workspace`
- **`hl.timer` signature:** `hl.timer(fn, { timeout = <ms>, type = "oneshot"|"repeat" })`.
- **Monitor positions are LOGICAL pixels, so scale changes the math.** With no
  profile applied, Hyprland's auto-scale picked **1.5** for eDP-1 → its logical
  width was **1280**, not 1920. Placing the next monitor at `1920x0` then left a
  640px gap and content overflowed off-screen ("only the top-left is visible").
  Fix: pin `scale` explicitly (eDP-1 → `1`) and place the neighbour at `1920x0`.
  Rule of thumb: `next_x = previous_width / previous_scale`.
- **`hyprctl monitors` does not reflect a scale change immediately.** Reading
  right after `hl.monitor{scale=...}` can still show the OLD scale, which makes
  a working call look like it failed. Re-read after a second before concluding.
- **`hl.monitor` accepts `scale` as a number or the string `"auto"`.** Prefer an
  explicit number for the built-in panel; `"auto"` is a good default for unknown
  external monitors so a HiDPI/4K screen comes up usable.

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
leaked-surface crash-looping may be a separate defect). Re-enable idle
(prefer a long `lock` timeout; keep `screen_off`/`lock_and_suspend` off)
only once noctalia is stable. → MITIGATED, not solved.

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

## See also (existing deep dives)
- 🟧/🟩 **Greeter ghost + dwindle crash + hybrid-GPU + Lua gotchas** —
  [hyprland-plasma-diagnosis.md](hyprland-plasma-diagnosis.md). Read first when
  revisiting greeter/login or Plasma↔Hyprland interactions.
- **Dwindle layout crash on shutdown** — [hyprland-plasma-diagnosis.md](hyprland-plasma-diagnosis.md)
  → ISSUE 2. (The standalone draft bug report was deleted 2026-07-27 as stale: written
  against 0.55.4, never filed, and no Hyprland coredump since the 0.56.0 upgrade.)
