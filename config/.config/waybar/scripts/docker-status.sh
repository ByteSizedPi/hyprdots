#!/bin/bash

if systemctl is-active --quiet docker; then
    echo "{\"text\":\"\",\"class\":\"on\"}"
else
    echo "{\"text\":\"\",\"class\":\"off\"}"
fi

