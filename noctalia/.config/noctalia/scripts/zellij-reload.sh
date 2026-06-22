#!/bin/bash
# Poke Zellij into re-reading its theme. Zellij has no signal/IPC theme reload,
# so we nudge the config file it watches; on change it re-reads themes/.
#
# IMPORTANT: do NOT use `sed -i`. That writes a temp file and renames it over
# config.kdl, giving it a new inode. Zellij watches the file's inode, so the
# rename unlinks what it's watching and the event is missed until the watcher
# re-arms on a fallback timer (seconds of lag). Instead rewrite in place (`>`
# truncates the existing inode) so the inotify watch sees the change instantly.
cfg=~/.config/zellij/config.kdl
new="$(sed "s|^// noctalia-theme-applied:.*|// noctalia-theme-applied: $(date +%s)|" "$cfg")"
printf '%s\n' "$new" >"$cfg"
