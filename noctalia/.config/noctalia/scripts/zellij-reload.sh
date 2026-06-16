#!/bin/bash
sed -i "s|^// noctalia-theme-applied:.*|// noctalia-theme-applied: $(date +%s)|" ~/.config/zellij/config.kdl
