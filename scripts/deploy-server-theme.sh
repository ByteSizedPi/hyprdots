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

# kitty: client-side terminal palette for the jjserver window (kitten ssh color_scheme
# in ssh.conf). kitty runs on the client, so this is rendered locally, not pushed.
title="$(printf '%s' "${palette_name:0:1}" | tr '[:lower:]' '[:upper:]')${palette_name:1}"
kitty_theme="$repo/kitty/.config/kitty/themes/${palette_name}-server.conf"
python3 "$render" "$palette" "$tpl/kitty-theme.conf" \
	| sed "1,/^## name:/ s/^## name:.*/## name: ${title} Server/" >"$kitty_theme"

# hyprland: client-side jjserver special-workspace border color (the palette primary),
# consumed by windowrules.lua. Local render; reload hyprland to apply.
hypr_colors="$repo/hyprland/.config/hypr/jjserver-colors.lua"
python3 "$render" "$palette" "$tpl/hyprland-jjserver-colors.lua" >"$hypr_colors"

echo "Done:"
echo "  server: ~/.config/nvim/lua/noctalia-theme.lua, ~/.config/zellij/themes/noctalia.kdl"
echo "  client: $kitty_theme  (ssh.conf should use: color_scheme ${title} Server)"
echo "  client: $hypr_colors  (jjserver border = palette primary; hyprctl reload to apply)"
echo "(reload nvim / restart the zellij session; new kitten-ssh windows pick up kitty colors)"
