# dotfiles — system knowledge base & working agreement

This repo is the **single source of truth** for how this machine is configured
beyond the base Fedora install. Everything not part of the stock distribution
should be discoverable from here.

## Read this before doing anything

Before diagnosing, configuring, or changing system state, read:

1. **`docs/system-overview.md`** — what this system is built from (Hyprland,
   noctalia, Plasma, greetd, hybrid GPU…), how the pieces interact, and where
   each component's config lives.
2. **`docs/problems.md`** — the running log of issues: what's **solved**, what's
   **still open**, and for each, what was tried that **worked** vs **didn't**.
   Start new work from the open problems so you don't re-tread dead ends.
3. **`SYSTEM.md`** — every change made **outside the stow tree** (`/etc`,
   system units, etc.), with full file contents and how to reapply.

`docs/README.md` is the index for all of the above plus the deep-dive writeups.

## Working agreement (please follow)

- **Log every non-distro change.** Config inside this repo → it's a stow
  package, so committing it is the record. Anything outside the repo (`/etc`,
  `/usr/lib`, system units) → record it in `SYSTEM.md` with full content + a
  reason + how to reapply. User systemd units belong in the `systemd` stow
  package, not hand-placed.
- **Log what you try, not just what works.** Update `docs/problems.md` as you
  go: failed attempts are as valuable as fixes — they stop the next session
  repeating them. Mark each problem solved / open and keep the "tried" list
  current.
- **Prefer the stow-tracked config file** over editing GUI-managed runtime
  state — but check which layer actually wins first. **Noctalia is the
  counter-example:** `~/.local/state/noctalia/settings.toml` (GUI-managed, not
  stowed) **outranks** the stowed `config.toml` per key, so mirroring a change
  into `config.toml` produces silently dead config. There, `config.toml` is only
  the **fresh-machine seed**; live changes go to `settings.toml`, and the theme
  surface is managed by `scripts/desktop-theme/{save,apply,reset}.sh`. See
  `docs/problems.md` → "noctalia config.toml precedence".
- **Verify precedence, don't assume it.** `noctalia config export merged` shows the
  effective config; `NOCTALIA_CONFIG_HOME`/`NOCTALIA_STATE_HOME` let you test
  against a throwaway dir instead of the live session.
- This machine runs **two graphical sessions at once** (Plasma on one VT,
  Hyprland on another) on a **hybrid GPU** — keep that in mind for any
  display/DRM/seat issue.

## Layout

- Top-level dirs are **GNU stow packages** (`hyprland`, `noctalia`, `kitty`,
  `zellij`, `nvim`, `systemd`, …). `stow <pkg>` symlinks them into `$HOME`.
- `docs/` — system overview, problem log, and per-issue deep dives.
- `SYSTEM.md` — out-of-tree (`/etc`) change log.
- **Not stow packages:** `docs/`, `scripts/`, and `themes/` (swappable system-wide
  looks — see `themes/README.md`). Don't `stow` these.
