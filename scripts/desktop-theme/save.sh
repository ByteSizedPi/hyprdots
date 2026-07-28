#!/usr/bin/env bash
# Snapshot the CURRENT live look into themes/<name>/ so it can be restored later.
#
# Captures:
#   - the theme-relevant keys of Noctalia's live settings.toml (see keys.conf),
#     wallpaper paths included — theme.source = "wallpaper" means the picture IS
#     the palette, so the look isn't reproducible without it
#   - the live Hyprland fragments ~/.config/hypr/theme/{appearance,layers}.lua
# Everything else — noctalia.lua, kitty/zellij/nvim/gtk themes, hyprtoolkit.conf —
# is regenerated output and deliberately NOT captured.
#
# hypr/glass.lua and manifest.conf come along too, when the live session has glass
# on. The one thing that can't be captured is a value poked in via `hyprctl repl` —
# that lives only in the running plugin, not on disk.
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

# --- Hyprland appearance: gaps, radius, opacity, blur, animations ---
mkdir -p "$dest/hypr"
if [ -f "$hypr_appearance" ]; then
  cp "$hypr_appearance" "$dest/hypr/appearance.lua"
else
  echo "note: $hypr_appearance missing — copying the neutral base instead" >&2
  cp "$themes/_base/hypr/appearance.lua" "$dest/hypr/appearance.lua"
fi

# --- Hyprland layer rules: which noctalia surfaces Hyprland blurs itself ---
if [ -f "$hypr_layers" ]; then
  cp "$hypr_layers" "$dest/hypr/layers.lua"
else
  cp "$themes/_base/hypr/layers.lua" "$dest/hypr/layers.lua"
fi

# --- hyprglass: captured like everything else, when the live theme uses it ---
# The live glass.lua is either a real config or apply.sh's disable stub, so key off
# the stub marker rather than mere existence — banking the stub as a theme's "look"
# would be meaningless.
#
# NOTE what this does and doesn't see. Editing the FILE and reloading is captured
# fine. Poking values with `hyprctl repl 'hl.plugin.hyprglass.config{...}'` is NOT:
# hg.layer()/hg.preset() are Lua-side registrations with no readback, so a live poke
# exists only in the running plugin. Edit the file if you want to keep it.
if [ -f "$hypr_glass" ] && ! grep -qF -e "$glass_stub_marker" "$hypr_glass"; then
  cp "$hypr_glass" "$dest/hypr/glass.lua"
  glass_on="on"
  glass_note="captured from live"
else
  glass_on="off"
  glass_note="none — glass is off in the live session"
fi

# Manifest tracks the live state: saving means "bank what I'm looking at". An
# existing glass.lua is left on disk when flipping to off — apply.sh ignores it
# while the manifest says off, so switching back on later costs one word.
cat >"$dest/manifest.conf" <<EOF
# Non-Noctalia theme keys. Read by scripts/desktop-theme/apply.sh.
#
# hyprglass = on   requires hypr/glass.lua alongside this file
# hyprglass = off  apply.sh installs an explicit disable stub
hyprglass = $glass_on
EOF

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
echo "  noctalia.toml       $n theme keys"
echo "  hypr/appearance.lua $(wc -l <"$dest/hypr/appearance.lua") lines"
echo "  hypr/layers.lua     $(wc -l <"$dest/hypr/layers.lua") lines"
echo "  hypr/glass.lua      $glass_note"
echo "  manifest.conf       hyprglass = $(theme_manifest_get "$dest" hyprglass)"
echo "  themes/active       $name"
echo "Commit it: git -C \"$repo\" add themes/$name && git -C \"$repo\" commit"
