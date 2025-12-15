#!/bin/bash

TERMINAL_CLASS="menu-terminal"
TERMINAL_TITLE="MenuTerm"

# Check if a terminal with the right class and title is already open
# if ! hyprctl clients -j | jq -e \
# ".[] | select(.class == \"$TERMINAL_CLASS\" and .title == \"$TERMINAL_TITLE\")" > /dev/null; then
# Not found — launch the terminal with zellij
# kitty --class "$TERMINAL_CLASS" --title "$TERMINAL_TITLE" -e zellij a Quick || zellij -s Quick &
# kitty -e $(zellij a Quick || zellij -s Quick)
# fi
