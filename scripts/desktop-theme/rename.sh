#!/usr/bin/env bash
# Rename a saved theme.
#
# Moves the directory and, if the renamed theme is the one currently applied,
# updates themes/active to match. Nothing else changes: the live desktop is
# untouched, since a theme's name isn't part of its look.
#
# Usage: scripts/desktop-theme/rename.sh <old-name> <new-name>
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

old_name="${1:-}"
new_name="${2:-}"
[ -n "$old_name" ] && [ -n "$new_name" ] || die "usage: rename.sh <old-name> <new-name>"
validate_theme_name "$new_name"
[ "$old_name" != "$new_name" ] || die "old and new names are the same"

old="$themes/$old_name"
new="$themes/$new_name"
[ -d "$old" ] || die "no such theme: $old_name"
[ -f "$old/noctalia.toml" ] || die "$old_name doesn't look like a theme (no noctalia.toml)"
[ ! -e "$new" ] || die "theme '$new_name' already exists"

mv "$old" "$new"

# Keep the pointer honest. Doing this after the move means a failed move leaves
# themes/active still naming a directory that exists.
was_active=""
if [ "$(active_theme)" = "$old_name" ]; then
  printf '%s\n' "$new_name" >"$themes/active"
  was_active=" (and themes/active)"
fi

echo "Renamed '$old_name' -> '$new_name'$was_active"
echo "The live desktop is unchanged — a theme's name isn't part of its look."
