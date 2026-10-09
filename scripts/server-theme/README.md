# scripts/server-theme — push a pinned palette to the remote server

**Execution context: REMOTE.** `deploy.sh` renders a fixed palette locally, `scp`s
the results to the homelab server, and pokes its live session so nvim/zellij
re-theme without reconnecting. It needs ssh reachability.

Unrelated to `../desktop-theme/`, which manages *this* machine's look. The two
groups share only the Noctalia templates in
`noctalia/.config/noctalia/templates/`.

```bash
./deploy.sh                      # jjserver, with its palette from hosts.conf
./deploy.sh pve-prod             # another host from hosts.conf
./deploy.sh pve-prod cobalt      # override the palette for one run
SERVER_THEME=cobalt ./deploy.sh  # override via env
```

**Single source of truth:** `hosts.conf`, one line per server:
`<label> <ssh target> <palette>`. Change a palette there and re-run for that
label. (Until 2026-10-07 this was `noctalia/.config/noctalia/palettes/active`,
one palette for the one server.)

| file | role |
| --- | --- |
| `hosts.conf` | servers, their ssh target and palette |
| `deploy.sh` | render → `scp` → live-poke the remote session |
| `render.py` | substitute a palette JSON into a Noctalia template → stdout |

Because the server is themed from a **fixed palette** rather than from a wallpaper,
`render.py` reuses the same templates Noctalia uses locally — no Noctalia or matugen
needed on the server.

## Outputs

Remote: `~/.config/nvim/lua/noctalia-theme.lua`,
`~/.config/zellij/themes/noctalia.kdl`, `~/.config/server-theme.txt` (breadcrumb).

Local, named by label so nothing else needs editing when a palette changes:

| file | consumed by |
| --- | --- |
| `kitty/.config/kitty/themes/server-<label>.conf` | `kitty/ssh.conf` (any `kitten ssh` to that host). Also `kitty/<label>.conf`, unused since the SUPER+S group was removed on 2026-10-09 |
| `hyprland/.config/hypr/theme/<label>.lua` | nothing since 2026-10-09 (was the SUPER+S tab border colour in `modules/scratchpads.lua`) |

## Adding a server

1. Add a line to `hosts.conf`.
2. On the server: clone the dotfiles to `~/dotfiles` and symlink
   `~/.config/nvim` and `~/.config/zellij` into it (no stow on the servers).
3. Run `./deploy.sh <label>`.
4. Add a `hostname` block in `kitty/.config/kitty/ssh.conf`.

## Palettes

`noctalia/.config/noctalia/palettes/*.json` — Material role names mapped to hex,
the same roles Noctalia extracts from a wallpaper. Copy one to a new name to add a
palette.
