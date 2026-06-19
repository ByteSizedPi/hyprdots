#!/usr/bin/env bash
# Push the fixed "cobalt" theme FROM this client TO a server's per-machine theme outputs.
#
# Model: the client owns the single theme. The server runs the same synced nvim/zellij
# configs; only the generated theme OUTPUTS differ, and those are gitignored/per-machine.
# This copies the tracked cobalt sources into the server's output paths. Re-run whenever
# the cobalt sources change (e.g. regenerated once via matugen) to update the server.
#
# Usage: scripts/push-server-theme.sh [user@host]   (default: jjserver@100.68.211.32)
set -euo pipefail

remote="${1:-jjserver@100.68.211.32}"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
nvim_src="$repo/nvim/.config/nvim/lua/themes/cobalt.lua"
zellij_src="$repo/zellij/.config/zellij/themes/cobalt.kdl"

# nvim: same module interface (returns { setup = ... }) -> straight copy to the output path.
scp -q "$nvim_src" "$remote:.config/nvim/lua/noctalia-theme.lua"

# zellij: config.kdl selects theme "noctalia", so the block must be named "noctalia".
# Rename on the way over; the rest of the theme is identical.
sed 's/^\([[:space:]]*\)cobalt {/\1noctalia {/' "$zellij_src" \
	| ssh "$remote" 'cat > .config/zellij/themes/noctalia.kdl'

echo "Pushed cobalt theme to $remote:"
echo "  ~/.config/nvim/lua/noctalia-theme.lua"
echo "  ~/.config/zellij/themes/noctalia.kdl"
echo "(reload nvim / restart the zellij session to pick it up)"
