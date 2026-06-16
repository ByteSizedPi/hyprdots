#!/bin/bash
set -euo pipefail

WALLPAPER=$(grep -m1 'path = ' ~/.local/state/noctalia/settings.toml | sed 's/.*path = "//;s/".*//')

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    exit 0
fi

noctalia theme "$WALLPAPER" -c ~/.config/noctalia/user-templates.toml

# noctalia sends SIGUSR1 to nvim to reload the theme, but zellij's render loop
# only flushes pane output on user interaction — so the updated highlights sit
# in the pty buffer until a keypress. SIGWINCH goes through zellij's resize
# path which forces an immediate pane repaint. The brief sleep lets SIGUSR1
# finish applying highlights before the repaint is triggered.
sleep 0.3 && pkill -WINCH nvim 2>/dev/null || true
