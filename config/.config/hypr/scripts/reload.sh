#!/bin/bash

# WP_DIR="$HOME/Pictures/Wallpapers/"
# WP_CUR="$HOME/.config/hypr/hyprpaper/wp.txt"
# WP_CFG="$HOME/.config/hypr/hyprpaper.conf"

# Get a random wallpaper
# WP_NEW=$(find "$WP_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
# save path
# echo "$WP_NEW" > "$WP_CUR"
# generate color palette
# matugen image $(cat "$WP_CUR")
# rewrite hyprpaper config
# cat > "$WP_CFG" <<EOF
# preload = $WP_NEW
# wallpaper = , $WP_NEW
# EOF

hyprctl reload