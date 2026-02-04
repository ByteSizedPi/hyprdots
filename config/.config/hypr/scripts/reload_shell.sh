#!/bin/bash

hyprctl reload
pkill -x waybar; waybar &
makoctl reload