#!/usr/bin/env bash
# Generate the server theme from a fixed palette through the SAME Noctalia templates
# used for the wallpaper theme, then push it to the server.
#
# Single source of truth: noctalia/.config/noctalia/palettes/<name>.json
# Pipeline mirrors the client: palette -> templates -> theme files (nvim, zellij).
# To change the server theme: edit the palette json (or add a new one and pass its
# name / set $SERVER_PALETTE), then run this.
#
# Usage: scripts/deploy-server-theme.sh [palette-name] [user@host]
#   palette-name: default $SERVER_PALETTE or "cobalt"
#   user@host:    default jjserver@100.68.211.32
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
palette_name="${1:-${SERVER_PALETTE:-cobalt}}"
remote="${2:-jjserver@100.68.211.32}"

palette="$repo/noctalia/.config/noctalia/palettes/$palette_name.json"
tpl="$repo/noctalia/.config/noctalia/templates"
render="$repo/scripts/render-theme.py"

[ -f "$palette" ] || { echo "no such palette: $palette" >&2; exit 1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Same templates as the wallpaper flow; zellij template already names its block
# "noctalia", so no rename is needed (config.kdl selects theme "noctalia").
python3 "$render" "$palette" "$tpl/nvim-theme.lua"   >"$tmp/noctalia-theme.lua"
python3 "$render" "$palette" "$tpl/zellij-theme.kdl" >"$tmp/noctalia.kdl"

echo "Rendered palette '$palette_name' -> pushing to $remote"
scp -q "$tmp/noctalia-theme.lua" "$remote:.config/nvim/lua/noctalia-theme.lua"
scp -q "$tmp/noctalia.kdl"       "$remote:.config/zellij/themes/noctalia.kdl"
echo "Done:"
echo "  ~/.config/nvim/lua/noctalia-theme.lua"
echo "  ~/.config/zellij/themes/noctalia.kdl"
echo "(reload nvim / restart the zellij session to pick it up)"
