#!/usr/bin/env bash
# Generate a server theme from a fixed palette through the SAME Noctalia templates
# used for the wallpaper flow, then push it to that server.
#
# SINGLE SOURCE OF TRUTH: scripts/server-theme/hosts.conf, one line per server
# (<label> <ssh target> <palette>). Change a palette there and re-run this for that
# label. Outputs are named by label, so kitty/ssh.conf, the per-host kitty configs
# and modules/scratchpads.lua never need editing when a palette changes.
#
# Usage: scripts/server-theme/deploy.sh [label] [palette]
#   label    a label from hosts.conf (default: jjserver)
#   palette  override the hosts.conf palette for this run (or set $SERVER_THEME)
set -euo pipefail

# Repo root (this script lives in <repo>/scripts/server-theme) and the paths we read from.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # scripts/server-theme
repo="$(cd "$here/../.." && pwd)"                    # repo root
pal_dir="$repo/noctalia/.config/noctalia/palettes"   # palette JSONs
tpl="$repo/noctalia/.config/noctalia/templates"      # shared Noctalia templates
render="$here/render.py"                             # substitutes a palette into a template

label="${1:-jjserver}"
read -r _ remote host_palette < <(awk -v l="$label" '$1 == l { print; exit }' "$here/hosts.conf") || {
  echo "no host '$label' in $here/hosts.conf" >&2
  exit 1
}
name="${2:-${SERVER_THEME:-$host_palette}}" # arg/env override the hosts.conf palette

palette="$pal_dir/$name.json" # the chosen palette file
[ -f "$palette" ] || {
  echo "no such palette: $palette" >&2
  exit 1
} # fail early if it's missing

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT # scratch dir, auto-cleaned

# --- server side: render with fixed output names, push, then poke the live session ---
python3 "$render" "$palette" "$tpl/nvim-theme.lua" >"$tmp/noctalia-theme.lua"  # render nvim theme
python3 "$render" "$palette" "$tpl/zellij-theme.kdl" >"$tmp/noctalia.kdl"      # render zellij theme
scp -q "$tmp/noctalia-theme.lua" "$remote:.config/nvim/lua/noctalia-theme.lua" # ship nvim theme
scp -q "$tmp/noctalia.kdl" "$remote:.config/zellij/themes/noctalia.kdl"        # ship zellij theme

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

# --- client side: named by label so ssh.conf and kitty/<label>.conf stay stable ---
# The kitty theme's "## name:" header is made unique per host, so the themes kitten
# lists each server theme separately.
python3 "$render" "$palette" "$tpl/kitty-theme.conf" |
  sed "s/^## name: Server$/## name: Server $label/" \
    >"$repo/kitty/.config/kitty/themes/server-$label.conf" # kitty scheme for this host
python3 "$render" "$palette" "$tpl/hyprland-jjserver-colors.lua" \
  >"$repo/hyprland/.config/hypr/theme/$label.lua" # hypr border colour for this host

echo "Deployed server theme: palette '$name' -> $label ($remote)"
echo "  server: nvim + zellij theme files, ~/.config/server-theme.txt (live-poked)"
echo "  client: kitty/themes/server-$label.conf + hypr/theme/$label.lua"
