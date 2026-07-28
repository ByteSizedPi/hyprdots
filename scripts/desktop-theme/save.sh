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
validate_theme_name "$name"
force="${2:-}"

dest="$themes/$name"
[ ! -d "$dest" ] || [ "$force" = "--force" ] ||
  die "theme '$name' already exists — pass --force to overwrite"

[ -f "$settings" ] || die "no live settings at $settings"

# Build the whole theme in a staging dir and swap it in at the very end, so a
# failure part-way through can't leave a half-updated theme behind. It can:
# 2026-07-28, a variable clash made this script die after rewriting most of a
# theme, which silently replaced a glass theme's definition with a non-glass one.
# Seeded from the existing theme so anything we don't rewrite (NOTES.md, and
# glass.lua when the live session has glass off) survives untouched.
staging="$(mktemp -d "$themes/.$name.staging.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
[ -d "$dest" ] && cp -a "$dest/." "$staging/"

# --- Noctalia: pull the theme surface out of the live GUI-managed settings ---
python3 "$toml" extract "$settings" "$keys" >"$staging/noctalia.toml.new"
n=$(grep -c '=' "$staging/noctalia.toml.new" || true)
[ "$n" -gt 0 ] || die "extracted 0 theme keys — is $settings empty?"
mv "$staging/noctalia.toml.new" "$staging/noctalia.toml"

# --- Hyprland appearance: gaps, radius, opacity, blur, animations ---
mkdir -p "$staging/hypr"
dest_apps="$staging/apps"
mkdir -p "$dest_apps"
if [ -f "$hypr_appearance" ]; then
  cp "$hypr_appearance" "$staging/hypr/appearance.lua"
else
  echo "note: $hypr_appearance missing — copying the neutral base instead" >&2
  cp "$themes/_base/hypr/appearance.lua" "$staging/hypr/appearance.lua"
fi

# --- Hyprland layer rules: which noctalia surfaces Hyprland blurs itself ---
if [ -f "$hypr_layers" ]; then
  cp "$hypr_layers" "$staging/hypr/layers.lua"
else
  cp "$themes/_base/hypr/layers.lua" "$staging/hypr/layers.lua"
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
  cp "$hypr_glass" "$staging/hypr/glass.lua"
  glass_on="on"
  glass_note="captured from live"
else
  glass_on="off"
  glass_note="none — glass is off in the live session"
fi

# Manifest tracks the live state: saving means "bank what I'm looking at". An
# existing glass.lua is left on disk when flipping to off — apply.sh ignores it
# while the manifest says off, so switching back on later costs one word.
cat >"$staging/manifest.conf" <<EOF
# Non-Noctalia theme keys. Read by scripts/desktop-theme/apply.sh.
#
# hyprglass = on   requires hypr/glass.lua alongside this file
# hyprglass = off  apply.sh installs an explicit disable stub
hyprglass = $glass_on
EOF

# --- Border/glow overrides, if the live session has any ---
if [ -f "$hypr_borders" ]; then
  cp "$hypr_borders" "$staging/hypr/borders.lua"
  borders_note="captured from live"
else
  rm -f "$staging/hypr/borders.lua"
  borders_note="none"
fi

# --- Per-app overlays: capture whatever the live files hold (see apps.conf) ---
# Skips apply.sh's placeholders, so "this theme has no kitty settings" stays that way
# instead of being banked as an empty look.
apps_note=""
while IFS=$'\t' read -r app app_dest app_reload; do
  [ -n "$app" ] || continue
  app_file="$(app_source_name "$app" "$app_dest")"
  if app_overlay_is_default "$app_dest" "$(app_base_file "$app_file")"; then
    # Untouched placeholder or an unmodified _base default — banking it would turn
    # "inherits the default" into "pins a copy of today's default" for every theme.
    rm -f "$dest_apps/$app_file"
  else
    mkdir -p "$dest_apps"
    cp "$app_dest" "$dest_apps/$app_file"
    apps_note="$apps_note $app"
  fi
done < <(apps_list)

# --- a place to describe the look, since the TOML won't say what you were going for ---
[ -f "$staging/NOTES.md" ] || cat >"$staging/NOTES.md" <<EOF
# theme: $name

Saved $(date -u +%F). Describe the intent here — the key list won't.

- **Feel:**
- **Palette:** $(grep -m1 '^theme\.' "$staging/noctalia.toml" 2>/dev/null || echo "see noctalia.toml")
EOF

# --- swap the finished theme into place ---
# Everything above wrote to staging only; this is the first moment $dest changes.
if [ -d "$dest" ]; then
  rm -rf "$dest.old"
  mv "$dest" "$dest.old"
fi
mv "$staging" "$dest"
trap - EXIT
rm -rf "$dest.old"

# What you just saved is what you're running, so it becomes the active theme.
printf '%s\n' "$name" >"$themes/active"

echo "Saved theme '$name' -> themes/$name/"
echo "  noctalia.toml       $n theme keys"
echo "  hypr/appearance.lua $(wc -l <"$dest/hypr/appearance.lua") lines"
echo "  hypr/layers.lua     $(wc -l <"$dest/hypr/layers.lua") lines"
echo "  hypr/glass.lua      $glass_note"
echo "  hypr/borders.lua    $borders_note"
echo "  manifest.conf       hyprglass = $(theme_manifest_get "$dest" hyprglass)"
echo "  apps/               ${apps_note:- none captured}"
echo "  themes/active       $name"
echo "Commit it: git -C \"$repo\" add themes/$name && git -C \"$repo\" commit"
