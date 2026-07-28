#!/usr/bin/env bash
# Copy a saved theme under a new name, so you can fork a variant without disturbing
# the original.
#
# Copies the whole theme directory — noctalia.toml, hypr/ fragments, apps/ overlays
# and manifest.conf — so the clone is a byte-for-byte starting point. NOTES.md is
# replaced with a fresh stub recording where it came from, because keeping the
# original's notes would describe the wrong thing.
#
# Does NOT apply the clone or touch themes/active: cloning is an edit to the theme
# library, not to the running desktop. Apply it when you want to see it.
#
# Usage: scripts/desktop-theme/clone.sh <source> <new-name>
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

src_name="${1:-}"
new_name="${2:-}"
[ -n "$src_name" ] && [ -n "$new_name" ] || die "usage: clone.sh <source> <new-name>"
validate_theme_name "$new_name"

src="$themes/$src_name"
dest="$themes/$new_name"
[ -d "$src" ] || die "no such theme: $src_name"
[ -f "$src/noctalia.toml" ] || die "$src_name doesn't look like a theme (no noctalia.toml)"
[ ! -e "$dest" ] || die "theme '$new_name' already exists"

# Stage then swap, same reasoning as save.sh: a half-copied theme directory is worse
# than no theme directory.
staging="$(mktemp -d "$themes/.$new_name.staging.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
cp -a "$src/." "$staging/"

cat >"$staging/NOTES.md" <<EOF
# theme: $new_name

Cloned from **$src_name** on $(date -u +%F). Describe what you're changing — the
key list won't.

- **Feel:**
- **Differs from $src_name:**
EOF

mv "$staging" "$dest"
trap - EXIT

echo "Cloned '$src_name' -> '$new_name'"
echo "  $(find "$dest" -type f | wc -l | tr -d ' ') files copied"
echo "  hyprglass = $(theme_manifest_get "$dest" hyprglass)"
echo "themes/active is unchanged — apply it with:"
echo "  scripts/desktop-theme/apply.sh $new_name"
