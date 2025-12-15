#!/bin/bash
current=$(brightnessctl --device='*kbd_backlight' get 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$current" ]; then
    echo false
    exit 0
fi

if [ "$current" -gt 0 ]; then
    echo true
else
    echo false
fi