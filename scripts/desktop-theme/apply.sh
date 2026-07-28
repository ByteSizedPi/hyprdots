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

# --- Hyprland: generated fragments required from hypr/theme/init.lua ---
# Copy rather than symlink: Hyprland's file watch follows the path it parsed, so
# a symlinked fragment doesn't reliably trigger its auto-reload.
mkdir -p "$hypr_theme_dir"

# Appearance: only if the theme ships one, so a theme can deliberately inherit
# whatever look is already installed.
if [ -f "$src/hypr/appearance.lua" ]; then
  cp "$src/hypr/appearance.lua" "$hypr_appearance"
fi

# Layer rules: ALWAYS written. A glass theme cedes some noctalia surfaces to
# hyprglass by dropping their rules here; a non-glass theme blurs them natively.
# Falling back to _base guarantees the shell surfaces are never left unstyled.
if [ -f "$src/hypr/layers.lua" ]; then
  cp "$src/hypr/layers.lua" "$hypr_layers"
else
  cp "$themes/_base/hypr/layers.lua" "$hypr_layers"
fi

# hyprglass: ALWAYS written — see write_glass_disabled() for why the off case
# still needs a real file.
if [ "$(theme_manifest_get "$src" hyprglass)" = "on" ]; then
  [ -f "$src/hypr/glass.lua" ] ||
    die "manifest.conf says 'hyprglass = on' but $src/hypr/glass.lua is missing"
  cp "$src/hypr/glass.lua" "$hypr_glass"
  glass_state="on (from themes/$name)"
else
  write_glass_disabled
  glass_state="off (disable stub)"
fi

printf '%s\n' "$name" >"$themes/active"

# --- Per-app overlays (kitty font/padding/opacity, etc — see apps.conf) ---
# Written for EVERY configured app, not just the ones this theme customises: a
# placeholder is how switching away from a theme that had settings clears them.
apps_note=""
while IFS=$'\t' read -r app app_dest app_reload; do
  [ -n "$app" ] || continue
  if [ -f "$src/apps/$app.conf" ]; then
    mkdir -p "$(dirname "$app_dest")"
    cp "$src/apps/$app.conf" "$app_dest"
    apps_note="$apps_note $app"
  else
    write_app_placeholder "$app" "$app_dest"
  fi
  [ -z "$app_reload" ] || sh -c "$app_reload" >/dev/null 2>&1 || true
done < <(apps_list)

reload_live

echo "Applied theme '$name'"
echo "  settings.toml    theme surface replaced (previous kept at settings.toml.bak)"
echo "  appearance.lua   $([ -f "$src/hypr/appearance.lua" ] && echo "from themes/$name" || echo "unchanged (theme ships none)")"
echo "  layers.lua       $([ -f "$src/hypr/layers.lua" ] && echo "from themes/$name" || echo "from themes/_base")"
echo "  glass.lua        $glass_state"
echo "  app overlays    ${apps_note:- none (all placeholders)}"
