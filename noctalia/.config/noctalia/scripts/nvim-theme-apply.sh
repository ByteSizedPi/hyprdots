#!/usr/bin/env bash
set -euo pipefail

if pkill -SIGUSR1 nvim >/dev/null 2>&1; then
    sleep 0.5
    pkill -WINCH nvim >/dev/null 2>&1 || true
    notify-send -a 'Noctalia' 'Neovim' 'Theme applied' -t 3000
fi
