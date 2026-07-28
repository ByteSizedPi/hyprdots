#!/usr/bin/env bash
# Clear the theme surface to get a blank slate to design against.
#
# Removes every theme key from Noctalia's live settings.toml, so those settings fall
# through to noctalia/.config/noctalia/config.toml and then to Noctalia's built-in
# defaults. Hyprland gets the neutral themes/_base/hypr/ fragments, with hyprglass off.
#
# NOTHING else is touched: monitors, widget positions, idle, keybinds and calendar all
# survive. The previous settings.toml is kept at settings.toml.bak.
#
# Wallpaper paths are theme keys, so a reset DOES clear the wallpaper — expect a bare
# desktop until you set one or re-apply a theme. wallpaper.directory (the picker's
# browse root) survives, so the images are still one click away.
#
# Intended loop:
#   scripts/desktop-theme/save.sh oldlook     # bank what you have
#   scripts/desktop-theme/reset.sh            # blank slate
#   ...tweak in Noctalia's Settings UI + edit ~/.config/hypr/theme/appearance.lua...
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
  echo "and resets the ~/.config/hypr/theme/ fragments to the neutral base."
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

# --- Hyprland: neutral starting point, glass explicitly off ---
mkdir -p "$hypr_theme_dir"
cp "$themes/_base/hypr/appearance.lua" "$hypr_appearance"
cp "$themes/_base/hypr/layers.lua" "$hypr_layers"
write_glass_disabled
rm -f "$hypr_borders"

# --- Per-app overlays: back to placeholders ---
while IFS=$'\t' read -r app app_dest app_reload; do
  [ -n "$app" ] || continue
  app_file="$(app_source_name "$app" "$app_dest")"
  mkdir -p "$(dirname "$app_dest")"
  if [ -f "$(app_base_file "$app_file")" ]; then
    cp "$(app_base_file "$app_file")" "$app_dest"
  else
    write_app_placeholder "$app" "$app_dest"
  fi
  [ -z "$app_reload" ] || sh -c "$app_reload" >/dev/null 2>&1 || true
done < <(apps_list)

# No named theme is applied any more; leave the pointer empty rather than lying.
: >"$themes/active"
reload_live

echo "Theme surface cleared — you're on Noctalia defaults."
echo "  previous settings kept at $settings.bak"
[ -n "$cur" ] && echo "  restore with: scripts/desktop-theme/apply.sh $cur"
echo "Tweak, then: scripts/desktop-theme/save.sh <newname>"
