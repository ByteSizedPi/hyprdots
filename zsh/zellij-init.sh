# ============================================================================
# AUTO-START ZELLIJ (Kitty only)
# ============================================================================
#
# Behavior:
# - special:menu workspace: Attach to persistent 'main' session (or create it)
#   The 'main' session is serialized and can be resurrected after reboots.
#
# - Any other workspace: Create an ephemeral session with a unique name.
#   These sessions are NOT serialized and are automatically killed/deleted
#   when the terminal closes.
#
# ============================================================================

# Only run in kitty terminal and when not already inside zellij
if [[ -n "$KITTY_WINDOW_ID" ]] && [[ -z "$ZELLIJ" ]]; then
    if hyprctl activewindow 2>/dev/null | grep -q 'special:menu'; then
        # ==============================================
        # SPECIAL:MENU WORKSPACE -> PERSISTENT 'MAIN' SESSION
        # ==============================================
        # Attach to 'main' session, create if it doesn't exist.
        # Uses default session_serialization=true from config.kdl,
        # so this session persists and can be resurrected after reboot.
        zellij attach main --create
    fi
fi
