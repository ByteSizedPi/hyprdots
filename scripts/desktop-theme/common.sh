# Shared paths/helpers for theme-{save,apply,reset}.sh. Sourced, not executed.
#
# THE MODEL (see docs/system-overview.md → "Theming"):
#   themes/<name>/noctalia.toml   theme surface, written INTO state settings.toml
#   themes/<name>/hypr-theme.lua  copied to ~/.config/hypr/theme.lua (generated)
#   themes/active                 one line: the name currently applied
# Noctalia's state settings.toml OUTRANKS config/config.toml, so a theme has to be
# merged into settings.toml — config.toml is only a fresh-machine fallback layer.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # scripts/desktop-theme
repo="$(cd "$here/../.." && pwd)"                    # repo root
themes="$repo/themes"
keys="$here/keys.conf"              # sibling: which keys count as "theme"
toml="$here/settings-toml.py"       # sibling: extract / strip / merge

# Noctalia's live, GUI-managed settings (NOT stowed). Honour the env override so
# these scripts can be tested against a sandbox state dir.
state_home="${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}"
settings="$state_home/noctalia/settings.toml"

# Generated Hyprland theme fragment, required from ui.lua (gitignored, like noctalia.lua).
# NOTE: setting NOCTALIA_STATE_HOME alone only sandboxes the Noctalia half — the
# Hyprland fragment and themes/active are still live. Set XDG_CONFIG_HOME too for a
# full dry run.
hypr_theme="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/ui-theme.lua"

die() {
  echo "error: $*" >&2
  exit 1
}

# Read themes/active, or empty if unset.
active_theme() { [ -f "$themes/active" ] && tr -d '[:space:]' <"$themes/active" || true; }

# Validate a candidate settings.toml in an isolated state dir before we go live —
# a bad merge would otherwise leave the shell with an unparseable config.
validate_candidate() {
  local candidate="$1" sbx
  sbx="$(mktemp -d)"
  trap 'rm -rf "$sbx"' RETURN
  mkdir -p "$sbx/state/noctalia" "$sbx/config/noctalia"
  cp "$candidate" "$sbx/state/noctalia/settings.toml"
  # Bring the real config dir along so template wiring validates too.
  cp "$HOME/.config/noctalia"/*.toml "$sbx/config/noctalia/" 2>/dev/null || true
  NOCTALIA_CONFIG_HOME="$sbx/config" NOCTALIA_STATE_HOME="$sbx/state" \
    noctalia config validate >/dev/null 2>&1 ||
    die "candidate settings.toml failed 'noctalia config validate' — not applying"
}

# Replace settings.toml atomically, keeping one backup so a bad apply is recoverable.
install_settings() {
  local candidate="$1"
  cp -p "$settings" "$settings.bak" 2>/dev/null || true
  mv "$candidate" "$settings"
}

# Poke the running shell + compositor. Both are no-ops if nothing is running.
reload_live() {
  noctalia msg config-reload >/dev/null 2>&1 || echo "note: noctalia not running (or reload failed)" >&2
  hyprctl reload >/dev/null 2>&1 || echo "note: hyprland not running (or reload failed)" >&2
}
