#!/bin/bash
OUTPUTS=$(mpc outputs)

DAC_ID=$(echo "$OUTPUTS" | grep -i "DAC" | grep -oP '(?<=Output )\d+')
SYS_ID=$(echo "$OUTPUTS" | grep -i "System" | grep -oP '(?<=Output )\d+')

if [ -z "$DAC_ID" ] || [ -z "$SYS_ID" ]; then
    notify-send -u critical "MPD Output" "Output 'DAC'/'System' tidak ditemukan. Cek: mpc outputs"
    exit 1
fi

DAC_ENABLED=$(echo "$OUTPUTS" | grep -i "DAC" | grep -c "is enabled")

if [ "$DAC_ENABLED" -eq 1 ]; then
    mpc disable "$DAC_ID" > /dev/null
    mpc enable "$SYS_ID" > /dev/null
    notify-send "MPD Output" "Sekarang: SYSTEM"
else
    mpc disable "$SYS_ID" > /dev/null
    mpc enable "$DAC_ID" > /dev/null
    notify-send "MPD Output" "Sekarang: DAC (Bit Perfect)"
fi
