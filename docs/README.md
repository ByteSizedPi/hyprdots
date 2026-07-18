# docs/ — system knowledge base

Central, version-controlled record of how this machine is built and what's been
tried on it. Read order for a new session:

1. **[system-overview.md](system-overview.md)** — components, how they interact,
   where each config lives.
2. **[problems.md](problems.md)** — problem log: solved vs open, with
   tried-worked / tried-didn't for each.
3. **[../SYSTEM.md](../SYSTEM.md)** — out-of-tree (`/etc`, system units) changes,
   full content + reapply steps. (Lives at repo root because the global rule
   writes there.)

## Homelab (second machine)

- **[homelab.md](homelab.md)** — R720xd + jjserver homelab: hardware inventory,
  live drive/SMART states, storage & backup architecture, PERC H710 decision,
  Proxmox install plan, laptop Wi-Fi relay, buying priorities, migration
  checklist. Keep the drive tables current.

## Deep-dive writeups (referenced from problems.md)

- **[hyprland-plasma-diagnosis.md](hyprland-plasma-diagnosis.md)** — greeter
  ghost + dwindle crash + hybrid-GPU + Lua-config gotchas.
- **[hyprland-tty1-dead-screen.md](hyprland-tty1-dead-screen.md)** — tty1 panel
  physically dead while Plasma runs on tty2 (unsolved; leading hypothesis =
  dual-session seat/DRM-master contention).
- **[bugreport-hyprland-dwindle.md](bugreport-hyprland-dwindle.md)** — dwindle
  layout crash bug report.

## How to maintain this

- New component or interaction learned → update `system-overview.md`.
- New issue, or progress on one → add/update an entry in `problems.md` (status +
  symptom + tried(worked/didn't) + root cause + next steps). Long investigations
  get their own file here, linked from `problems.md`.
- Change outside the repo → `../SYSTEM.md`.
