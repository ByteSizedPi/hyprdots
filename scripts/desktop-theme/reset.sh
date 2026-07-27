#!/usr/bin/env bash
# Clear the theme surface to get a blank slate to design against.
#
# Removes every theme key from Noctalia's live settings.toml, so those settings fall
# through to noctalia/.config/noctalia/config.toml and then to Noctalia's built-in
# defaults. Hyprland gets the neutral themes/_base/hypr-theme.lua.
#
# NOTHING else is touched: monitors, wallpapers, widget positions, idle, keybinds and
# calendar all survive. The previous settings.toml is kept at settings.toml.bak.
#
# Intended loop:
#   scripts/desktop-theme/save.sh oldlook     # bank what you have
#   scripts/desktop-theme/reset.sh            # blank slate
#   ...tweak in Noctalia's Settings UI + edit ~/.config/hypr/ui-theme.lua...
#   scripts/desktop-theme/save.sh newlook     # bank the result
#
# Usage: scripts/desktop-theme/reset.sh [--yes]
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ -f "$settings" ] || die "no live settings at $settings"

cur="$(active_theme)"
if [ "${1:-}" != "--yes" ]; then
  n=$(python3 "$toml" extract "$settings" "$keys" | grep -c '=' || true)
  echo "This clears $n theme keys from $settings"
  echo "and resets ~/.config/hypr/ui-theme.lua to the neutral base."
  [ -n "$cur" ] && echo "Active theme is '$cur' — make sure it's saved (themes/$cur/) first."
  printf 'Continue? [y/N] '
  read -r reply
  [ "$reply" = "y" ] || [ "$reply" = "Y" ] || die "aborted"
fi

# --- Noctalia: keep everything that isn't a theme key ---
candidate="$(mktemp)"
trap 'rm -f "$candidate"' EXIT
python3 "$toml" strip "$settings" "$keys" >"$candidate"
validate_candidate "$candidate"
install_settings "$candidate"
trap - EXIT

# --- Hyprland: neutral starting point ---
mkdir -p "$(dirname "$hypr_theme")"
cp "$themes/_base/hypr-theme.lua" "$hypr_theme"

# No named theme is applied any more; leave the pointer empty rather than lying.
: >"$themes/active"
reload_live

echo "Theme surface cleared — you're on Noctalia defaults."
echo "  previous settings kept at $settings.bak"
[ -n "$cur" ] && echo "  restore with: scripts/desktop-theme/apply.sh $cur"
echo "Tweak, then: scripts/desktop-theme/save.sh <newname>"
