#!/bin/bash
set -euo pipefail

WALLPAPER=$(grep -m1 'path = ' ~/.local/state/noctalia/settings.toml | sed 's/.*path = "//;s/".*//')

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    exit 0
fi

noctalia theme "$WALLPAPER" -c ~/.config/noctalia/user-templates.toml
