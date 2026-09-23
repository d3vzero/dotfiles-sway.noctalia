#!/bin/bash
# Tunggu MPD benar-benar bisa dikonek dulu, biar mpd-mpris tidak race saat boot
for i in {1..20}; do
    if mpc status >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done
exec mpd-mpris
