#!/usr/bin/env bash
# Apply a saved theme: merge its keys into Noctalia's live settings.toml, drop its
# Hyprland fragment into place, and reload both.
#
# Non-theme settings in settings.toml (monitors, widget positions, idle, keybinds,
# calendar) are preserved — only the theme surface is replaced. Wallpaper paths ARE
# part of that surface, so applying a theme changes the wallpaper too.
# The previous settings.toml is kept at settings.toml.bak.
#
# Close Noctalia's Settings window first: the running shell may flush its in-memory
# state over this write.
#
# Usage: scripts/desktop-theme/apply.sh [name]        (default: themes/active)
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

name="${1:-$(active_theme)}"
[ -n "$name" ] || die "no theme given and themes/active is empty"
src="$themes/$name"
[ -d "$src" ] || die "no such theme: $src"
[ -f "$src/noctalia.toml" ] || die "$src/noctalia.toml missing"
[ -f "$settings" ] || die "no live settings at $settings"

# --- Noctalia: strip the old theme surface, splice in this theme's ---
candidate="$(mktemp)"
trap 'rm -f "$candidate"' EXIT
python3 "$toml" merge "$settings" "$keys" "$src/noctalia.toml" >"$candidate"
validate_candidate "$candidate"
install_settings "$candidate"
trap - EXIT

# --- Hyprland: generated fragment required from ui.lua ---
if [ -f "$src/hypr-theme.lua" ]; then
  mkdir -p "$(dirname "$hypr_theme")"
  # Copy rather than symlink: Hyprland's file watch follows the path it parsed, so
  # a symlinked fragment doesn't reliably trigger its auto-reload.
  cp "$src/hypr-theme.lua" "$hypr_theme"
fi

printf '%s\n' "$name" >"$themes/active"
reload_live

echo "Applied theme '$name'"
echo "  settings.toml  theme surface replaced (previous kept at settings.toml.bak)"
echo "  ui-theme.lua   $([ -f "$src/hypr-theme.lua" ] && echo "from themes/$name" || echo "unchanged (theme ships none)")"
