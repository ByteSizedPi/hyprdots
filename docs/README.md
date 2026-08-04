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

## Theming

- **[theming.md](theming.md)** — saving, switching and defining looks. Usage
  examples for `scripts/desktop-theme/{save,apply,reset}.sh`, the measured Noctalia config
  precedence (state `settings.toml` beats stowed `config.toml`), the
  behaviour-vs-appearance split, per-theme hyprglass, the theme key surface,
  safety and undo, and troubleshooting.
- **[../themes/README.md](../themes/README.md)** — quick reference for what's in
  `themes/`.

## Maintenance

- **`../scripts/stow-audit.sh`** — verifies every stow package file is really a
  symlink into this repo. Catches configs that got silently un-managed by a tool
  rewriting them in place. Exit 1 on drift, so it's usable from a hook.

## Tooling

- **[claude-modes.md](claude-modes.md)** — the `claude` stow package: two output
  styles ("Technical (STE)" for work, "Open" for concepts/philosophy), the
  `ste-writing` skill, how to switch per directory, and why the bundled linter
  is optional.

## Power

- **[power-profiles.md](power-profiles.md)** — `power-profile-auto.service`:
  performance on AC, power-saver on battery, via UPower's `OnBattery` instead of
  a udev rule (udev has no per-user rules). Covers the tuned/tuned-ppd stack on
  this machine, the polkit reasoning, and how to change the target profiles.

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

## How to maintain this

- New component or interaction learned → update `system-overview.md`.
- New issue, or progress on one → add/update an entry in `problems.md` (status +
  symptom + tried(worked/didn't) + root cause + next steps). Long investigations
  get their own file here, linked from `problems.md`.
- Change outside the repo → `../SYSTEM.md`.
- New theme, or a change to the theme tooling / key surface → `theming.md`
  (and re-save affected themes with `scripts/desktop-theme/save.sh <name> --force`).
