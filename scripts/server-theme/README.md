# scripts/server-theme — push a pinned palette to the remote server

**Execution context: REMOTE.** `deploy.sh` renders a fixed palette locally, `scp`s
the results to the homelab server, and pokes its live session so nvim/zellij
re-theme without reconnecting. It needs ssh reachability.

Unrelated to `../desktop-theme/`, which manages *this* machine's look. The two
groups share only the Noctalia templates in
`noctalia/.config/noctalia/templates/`.

```bash
./deploy.sh                      # use the active palette + default host
./deploy.sh cobalt               # override the palette
./deploy.sh cobalt user@host     # override palette + host
SERVER_THEME=cobalt ./deploy.sh  # override via env
```

**Single source of truth:** `noctalia/.config/noctalia/palettes/active` — one line,
the palette name. Change that file and re-run; nothing else needs editing.

| file | role |
| --- | --- |
| `deploy.sh` | render → `scp` → live-poke the remote session |
| `render.py` | substitute a palette JSON into a Noctalia template → stdout |

Because the server is themed from a **fixed palette** rather than from a wallpaper,
`render.py` reuses the same templates Noctalia uses locally — no Noctalia or matugen
needed on the server.

## Outputs

Remote: `~/.config/nvim/lua/noctalia-theme.lua`,
`~/.config/zellij/themes/noctalia.kdl`, `~/.config/server-theme.txt` (breadcrumb).

Local, fixed names so `ssh.conf` / `jjserver.conf` never need editing when the
palette changes: `kitty/.config/kitty/themes/server-theme.conf` and
`hyprland/.config/hypr/jjserver-colors.lua` (consumed by `windowrules.lua` so the
`jjserver` special-workspace border matches).

## Palettes

`noctalia/.config/noctalia/palettes/*.json` — Material role names mapped to hex,
the same roles Noctalia extracts from a wallpaper. Copy one to a new name to add a
palette.
