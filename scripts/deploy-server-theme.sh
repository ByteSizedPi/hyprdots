#!/usr/bin/env bash
# Generate the server theme from a fixed palette through the SAME Noctalia templates
# used for the wallpaper flow, then push it to the server.
#
# SINGLE SOURCE OF TRUTH: noctalia/.config/noctalia/palettes/active  (one line, the
# palette name, e.g. "cobalt"). Change that one file and re-run this — nothing else.
# All outputs use FIXED names, so ssh.conf / jjserver.conf never need editing when you
# switch themes. Override the active palette ad-hoc with arg 1 or $SERVER_THEME.
#
# Usage: scripts/deploy-server-theme.sh [palette-name] [user@host]
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pal_dir="$repo/noctalia/.config/noctalia/palettes"
tpl="$repo/noctalia/.config/noctalia/templates"
render="$repo/scripts/render-theme.py"

# Resolve the active palette: arg 1 > $SERVER_THEME > palettes/active > "cobalt".
active="cobalt"
[ -f "$pal_dir/active" ] && active="$(tr -d '[:space:]' <"$pal_dir/active")"
name="${1:-${SERVER_THEME:-$active}}"
remote="${2:-jjserver@100.68.211.32}"

palette="$pal_dir/$name.json"
[ -f "$palette" ] || { echo "no such palette: $palette" >&2; exit 1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# --- server side (fixed output names; pushed via scp) ---
python3 "$render" "$palette" "$tpl/nvim-theme.lua"   >"$tmp/noctalia-theme.lua"
python3 "$render" "$palette" "$tpl/zellij-theme.kdl" >"$tmp/noctalia.kdl"
scp -q "$tmp/noctalia-theme.lua" "$remote:.config/nvim/lua/noctalia-theme.lua"
scp -q "$tmp/noctalia.kdl"       "$remote:.config/zellij/themes/noctalia.kdl"
# breadcrumb on the server recording which palette is active
ssh "$remote" "printf 'palette: %s\ndeployed: %s\n' '$name' '$(date -u +%FT%TZ)' >~/.config/server-theme.txt"

# --- client side (fixed names; kitty theme is always 'Server', so ssh.conf is stable) ---
python3 "$render" "$palette" "$tpl/kitty-theme.conf" \
	>"$repo/kitty/.config/kitty/themes/server-theme.conf"
python3 "$render" "$palette" "$tpl/hyprland-jjserver-colors.lua" \
	>"$repo/hyprland/.config/hypr/jjserver-colors.lua"

echo "Deployed server theme: palette '$name' -> $remote"
echo "  server: nvim + zellij theme files, ~/.config/server-theme.txt"
echo "  client: kitty 'Server' scheme + hypr jjserver border"
echo "Now: hyprctl reload; relaunch the jjserver window (META+A); restart the zellij session."
