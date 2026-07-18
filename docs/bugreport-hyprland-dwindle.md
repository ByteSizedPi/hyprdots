# Bug report: Segfault in dwindle layout on window unmap during compositor shutdown

**For:** https://github.com/hyprwm/Hyprland/issues

**Title:** [0.55.4] Reproducible segfault in dwindle layout (`calculateWorkspace` → `setPositionGlobal`) on unmap of a special-workspace window during compositor shutdown

> **Why this isn't just a duplicate:** the same dwindle crash was reported in #15096 (0.55.2) and #13778 (0.54.2) and both were **closed as *not planned* for lack of a reliable reproduction**. This report adds a **100%-deterministic reproduction** and identifies a concrete trigger the earlier reports lacked: a window in a **special workspace** unmapping during `CCompositor::cleanup()` (i.e. on exit). See *Related issues* below.

## Reproduction (100% reproducible)
1. Use the **dwindle** layout.
2. Open one or more windows in **special workspaces** (e.g. `special:zellij` and `special:jjserver`, each with a terminal).
3. Exit Hyprland with `hyprctl dispatch exit` (or end the session so the compositor tears down).

**Expected:** clean exit (status 0) regardless of special-workspace contents.
**Actual:** SIGSEGV during `CCompositor::cleanup()`; non-zero exit; a coredump is generated. No crash if the special workspaces are empty at exit.

## Summary
On shutdown, `main()` → `CCompositor::cleanup()` destroys clients. A window in a special workspace unmaps, which triggers `CMonitor::setSpecialWorkspace` → a dwindle layout recalculation that calls `ITarget::setPositionGlobal` on already-freed monitor/layout state → SIGSEGV. Appears to be a use-after-free: layout recalculation runs against monitor/layout objects already torn down earlier in `cleanup()`.

Downstream consequences of the non-zero exit:
1. `uwsm`/systemd sees the compositor exit as a failure (logout via `hyprctl dispatch exit` always hits this path).
2. `xdg-desktop-portal-hyprland` then segfaults in its own atexit destructor (`~CPortalManager`) cleaning up now-dead Wayland objects.
3. The greeter's `kwin_wayland` framebuffer is left bound to a KMS overlay plane (unclean handoff), producing a persistent "ghost" of the login screen over the next session (likely environment-specific; hybrid Intel+NVIDIA here).

## Backtrace (Hyprland)
```
Signal: 11 (SEGV)
#0  Layout::ITarget::setPositionGlobal(Hyprutils::Math::CBox const&)
#1  Layout::Tiled::SDwindleNodeData::recalcSizePosRecursive(bool, bool, bool)
#2  Layout::Tiled::CDwindleAlgorithm::calculateWorkspace()
#3  Layout::CAlgorithm::recalculate(eRecalculateReason)
#4  CMonitor::setSpecialWorkspace(SP<CWorkspace> const&)
#5  Desktop::View::CWindow::onUnmap()
#6  Desktop::View::CWindow::unmapWindow()
#7  Hyprutils::Signal::CSignalListener::emitInternal(void*)
...
#16 wl_display_destroy_clients (libwayland-server)
#17 CCompositor::cleanup()
#18 main
```

## Environment
```
Hyprland: 0.55.4, commit a0136d8c04687bb36eb8a28eb9d1ff92aea99704 (tag v0.55.4)
          (latest upstream release as of 2026-06-11; packaged via Fedora COPR lionheartp/Hyprland)
OS:       Fedora Linux 44 (KDE Plasma Desktop Edition)
Kernel:   7.0.12-201.fc44.x86_64
GPU:      Intel Arc Graphics (Meteor Lake-P) [iGPU] + NVIDIA RTX 500 Ada Laptop [dGPU] (hybrid)
DM:       plasma-login-manager (greeter compositor: kwin_wayland)
Launch:   uwsm (systemd-managed session, wayland-wm@hyprland.desktop.service)
Layout:   dwindle
```

## Related issues
- **#15096** (closed, *not planned*) — "Crash in dwindle layout while unmapping window on Hyprland 0.55.2". Same crash chain: `setPositionGlobal()` ← `calculateWorkspace()` ← `removeTarget()` ← `unmapWindow()`. Closed because the reporter had no reliable reproduction.
- **#13778** (closed, *not planned*) — "SIGSEGV in `CDwindleAlgorithm::calculateWorkspace()` during rapid window unmap events" (0.54.2). Exact crashing function; only (semi-)reproducible under an artificial rapid window-spawn workload.
- **#5498** (merged PR) — "compositor: move `wl_display_destroy_clients` so we don't crash on exit". Prior fix in the same exit/cleanup path, indicating shutdown-ordering here is historically fragile.

## Workarounds
- **Community-suggested (untested upstream):** switch away from the **dwindle** layout — per #13778, this "may also work if the bug is dwindle-specific". Since the crash is entirely within `CDwindleAlgorithm`, the **master** layout likely avoids this code path. *No maintainer-confirmed workaround exists in any of the related issues.*
- **Practical mitigation for this exact case:** the crash only fires when special-workspace windows are present at exit, so it does not affect a running session; logout still completes (the process exits, just via SIGSEGV instead of cleanly). Do **not** add `Restart=on-failure` to the compositor service to "recover" — under uwsm that intercepts logout and relaunches the compositor.
- **For the resulting greeter "ghost"** (orphaned KMS plane): force a full modeset with a VT switch — `sudo chvt 2 && sleep 1 && sudo chvt 3`.

## Notes
- Likely fix direction: guard the unmap-triggered layout recalculation so it is skipped during shutdown, or order client destruction before monitor/layout teardown in `CCompositor::cleanup()`.

---

## Before posting — review starting points (not part of the report)

Read the full comment threads (the fetch tool only reliably saw the original posts — there may be maintainer discussion buried in comments). Decide: **comment-to-reopen on #15096** vs **new issue cross-linking both**.

Threads to read in full:
- #15096 — https://github.com/hyprwm/Hyprland/issues/15096 (closest: 0.55.x, same chain; check why it was closed and by whom)
- #13778 — https://github.com/hyprwm/Hyprland/issues/13778 (exact crash function; has the "try non-dwindle layout" note)
- #5498 — https://github.com/hyprwm/Hyprland/pull/5498 (prior exit-path fix; see what was changed in cleanup ordering)

Search for newer/duplicate reports before filing:
- calculateWorkspace crashes: https://github.com/hyprwm/Hyprland/issues?q=calculateWorkspace+in%3Atitle%2Cbody
- special workspace + exit/cleanup: https://github.com/hyprwm/Hyprland/issues?q=setSpecialWorkspace+OR+%22crash+on+exit%22
- check it's not already fixed on `main` past v0.55.4: https://github.com/hyprwm/Hyprland/commits/main (grep dwindle / cleanup / setSpecialWorkspace)

Crash-report guidelines (follow these or it gets closed):
- https://wiki.hypr.land/Crashes-and-Bugs/ — attach the full `hyprctl rollinglog`, a symbolized backtrace, and `hyprctl systeminfo`.

Commands to gather the required attachments:
```
hyprctl systeminfo > systeminfo.txt
hyprctl rollinglog > rollinglog.txt
coredumpctl info /usr/bin/Hyprland > backtrace.txt   # most recent Hyprland coredump
```
