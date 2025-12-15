#!/bin/bash
if systemctl is-active --quiet docker; then
    sudo systemctl disable docker
    sudo systemctl stop docker
else
    sudo systemctl enable docker
    sudo systemctl start docker
fi