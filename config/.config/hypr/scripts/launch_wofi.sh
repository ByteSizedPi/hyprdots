#!/bin/bash

# Check if wofi is already running
if ! pgrep -x "wofi" > /dev/null; then
    wofi --show drun
fi
