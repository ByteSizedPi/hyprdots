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

# Repo root (this script lives in <repo>/scripts) and the paths we read from.
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pal_dir="$repo/noctalia/.config/noctalia/palettes"   # palette JSONs + the `active` pointer
tpl="$repo/noctalia/.config/noctalia/templates"      # shared Noctalia templates
render="$repo/scripts/render-theme.py"               # substitutes a palette into a template

# Resolve the active palette: arg 1 > $SERVER_THEME > palettes/active > "cobalt".
active="cobalt"                                                          # last-resort default
[ -f "$pal_dir/active" ] && active="$(tr -d '[:space:]' <"$pal_dir/active")"  # the single source of truth
name="${1:-${SERVER_THEME:-$active}}"                                   # let arg/env override ad-hoc
remote="${2:-jjserver@100.68.211.32}"                                   # target host (arg 2 overrides)

palette="$pal_dir/$name.json"                                           # the chosen palette file
[ -f "$palette" ] || { echo "no such palette: $palette" >&2; exit 1; }  # fail early if it's missing

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT                           # scratch dir, auto-cleaned

# --- server side: render with fixed output names, push, then poke the live session ---
python3 "$render" "$palette" "$tpl/nvim-theme.lua"   >"$tmp/noctalia-theme.lua"  # render nvim theme
python3 "$render" "$palette" "$tpl/zellij-theme.kdl" >"$tmp/noctalia.kdl"        # render zellij theme
scp -q "$tmp/noctalia-theme.lua" "$remote:.config/nvim/lua/noctalia-theme.lua"  # ship nvim theme
scp -q "$tmp/noctalia.kdl"       "$remote:.config/zellij/themes/noctalia.kdl"   # ship zellij theme

# One ssh trip that: writes the breadcrumb, signals the running nvim to reload, and
# nudges the watched zellij config in place (same inode-preserving trick as the local
# zellij-reload.sh) so the server session re-themes immediately — no reconnect needed.
# Values are passed as positional args so the single-quoted heredoc needs no escaping;
# $(date +%s) inside it runs on the server.
ssh "$remote" bash -s -- "$name" "$(date -u +%FT%TZ)" <<'EOSSH'
set -e
name=$1; ts=$2
printf 'palette: %s\ndeployed: %s\n' "$name" "$ts" >~/.config/server-theme.txt
pkill -SIGUSR1 nvim 2>/dev/null || true
cfg=~/.config/zellij/config.kdl
new="$(sed "s|^// noctalia-theme-applied:.*|// noctalia-theme-applied: $(date +%s)|" "$cfg")"
printf '%s\n' "$new" >"$cfg"
EOSSH

# --- client side: fixed names so ssh.conf/jjserver.conf stay stable across theme swaps ---
python3 "$render" "$palette" "$tpl/kitty-theme.conf" \
	>"$repo/kitty/.config/kitty/themes/server-theme.conf"           # kitty 'Server' scheme
python3 "$render" "$palette" "$tpl/hyprland-jjserver-colors.lua" \
	>"$repo/hyprland/.config/hypr/jjserver-colors.lua"             # hypr jjserver border colors

echo "Deployed server theme: palette '$name' -> $remote"
echo "  server: nvim + zellij theme files, ~/.config/server-theme.txt (live-poked)"
echo "  client: kitty 'Server' scheme + hypr jjserver border"
echo "Now (client only): hyprctl reload; relaunch the jjserver window (META+A)."
