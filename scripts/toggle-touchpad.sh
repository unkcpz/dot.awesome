#!/bin/bash

DEVICE="UNIW0001:00 093A:0255 Touchpad" 

STATE=$(xinput list-props "$DEVICE" | grep "Device Enabled" | awk '{print $NF}')

if [ "$STATE" -eq 1 ]; then
    xinput disable "$DEVICE"
else
    xinput enable "$DEVICE"
fi

