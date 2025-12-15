#!/bin/bash
# Close control center
swaync-client -cp

# Small delay
sleep 0.1

# Take screenshot
geometry=$(slurp 2>/dev/null)
if [ -n "$geometry" ]; then
    grim -g "$geometry" - | wl-copy
    notify-send -i "camera-photo-symbolic" "Screenshot" "Copied to clipboard"
fi