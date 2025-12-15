#!/bin/bash

# Check if rofi is already running
if ! pgrep -x "rofi" > /dev/null; then
    rofi -show drun
fi
