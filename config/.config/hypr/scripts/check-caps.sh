#!/bin/bash

# Check if Caps Lock is on
if [[ $(xset q 2>/dev/null | grep "Caps Lock" | awk '{print $4}') == "on" ]]; then
    echo " Caps Lock is ON"
else
    echo ""
fi
