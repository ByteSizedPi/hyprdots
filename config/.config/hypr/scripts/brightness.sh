#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 up|down"
    exit 1
fi

action=$1

case "$action" in
    up)
        brightnessctl s 10%+ >/dev/null
    ;;
    down)
        current=$(brightnessctl get)
        max=$(brightnessctl max)
        percent=$((100 * current / max))
        
        if [ "$percent" -gt 10 ]; then
            brightnessctl s 10%- >/dev/null
        else
            brightnessctl s 10% >/dev/null
        fi
    ;;
    *)
        echo "Invalid argument: use 'up' or 'down'"
        exit 1
    ;;
esac
