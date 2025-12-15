#!/bin/bash

CURRENT=$(brightnessctl --device='*kbd_backlight' get 2>/dev/null)
STATE=$([ "$CURRENT" = "0" ] && echo "off" || echo "on")
echo "{\"text\":\"\",\"class\":\"$STATE\",\"alt\":\"$STATE\"}"