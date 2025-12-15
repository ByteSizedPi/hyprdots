#!/bin/bash

pkill -x waybar; waybar &
swaync-client -R
swaync-client --reload-css