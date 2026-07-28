#!/usr/bin/env bash
# Snapshot the CURRENT live look into themes/<name>/ so it can be restored later.
#
# Captures exactly two inputs:
#   - the theme-relevant keys of Noctalia's live settings.toml (see keys.conf),
#     wallpaper paths included — theme.source = "wallpaper" means the picture IS
#     the palette, so the look isn't reproducible without it
#   - the current generated Hyprland theme fragment (~/.config/hypr/theme.lua)
# Everything else — noctalia.lua, kitty/zellij/nvim/gtk themes, hyprtoolkit.conf —
# is regenerated output and deliberately NOT captured.
#
# Usage: scripts/desktop-theme/save.sh <name> [--force]
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

name="${1:-}"
[ -n "$name" ] || die "usage: save.sh <name> [--force]"
[[ "$name" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "theme name must be lowercase alnum/dash/underscore: '$name'"
[ "$name" != "active" ] || die "'active' is the pointer file, not a theme name"
force="${2:-}"

dest="$themes/$name"
[ ! -d "$dest" ] || [ "$force" = "--force" ] ||
  die "theme '$name' already exists — pass --force to overwrite"

[ -f "$settings" ] || die "no live settings at $settings"
mkdir -p "$dest"

# --- Noctalia: pull the theme surface out of the live GUI-managed settings ---
python3 "$toml" extract "$settings" "$keys" >"$dest/noctalia.toml.new"
n=$(grep -c '=' "$dest/noctalia.toml.new" || true)
[ "$n" -gt 0 ] || die "extracted 0 theme keys — is $settings empty?"
mv "$dest/noctalia.toml.new" "$dest/noctalia.toml"

# --- Hyprland: the themed half of ui.lua (borders, radius, opacity, blur, anims) ---
if [ -f "$hypr_theme" ]; then
  cp "$hypr_theme" "$dest/hypr-theme.lua"
else
  echo "note: $hypr_theme missing — copying the neutral base instead" >&2
  cp "$themes/_base/hypr-theme.lua" "$dest/hypr-theme.lua"
fi

# --- a place to describe the look, since the TOML won't say what you were going for ---
[ -f "$dest/NOTES.md" ] || cat >"$dest/NOTES.md" <<EOF
# theme: $name

Saved $(date -u +%F). Describe the intent here — the key list won't.

- **Feel:**
- **Palette:** $(grep -m1 '^theme\.' "$dest/noctalia.toml" 2>/dev/null || echo "see noctalia.toml")
EOF

# What you just saved is what you're running, so it becomes the active theme.
printf '%s\n' "$name" >"$themes/active"

echo "Saved theme '$name' -> themes/$name/"
echo "  noctalia.toml    $n theme keys"
echo "  hypr-theme.lua   $(wc -l <"$dest/hypr-theme.lua") lines"
echo "  themes/active    $name"
echo "Commit it: git -C \"$repo\" add themes/$name && git -C \"$repo\" commit"
