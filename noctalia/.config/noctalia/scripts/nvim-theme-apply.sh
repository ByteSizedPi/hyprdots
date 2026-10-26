#!/usr/bin/env bash
set -euo pipefail

# Tell every running nvim to reload the regenerated theme. The SIGUSR1 handler
# in nvim/.config/nvim/lua/plugins/base16.lua re-requires the theme and does its
# own `redraw!`, so no extra WINCH/sleep is needed here (that was vestigial from
# before the handler owned the repaint).
pkill -SIGUSR1 nvim >/dev/null 2>&1 || true
