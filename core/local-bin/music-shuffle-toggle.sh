#!/bin/bash
STATE_DIR=~/.cache/waybar-music
mkdir -p "$STATE_DIR"
SHUFFLE_FILE="$STATE_DIR/shuffle"
ACTIVE_FILE="$STATE_DIR/active_category"

CUR=$( [ -f "$SHUFFLE_FILE" ] && cat "$SHUFFLE_FILE" )

if [ "$CUR" = "on" ]; then
    # --- MATIKAN SHUFFLE ---
    echo "off" > "$SHUFFLE_FILE"
    mpc random off > /dev/null
    notify-send "Music Shuffle" "Off"
else
    # --- NYALAKAN SHUFFLE ---
    echo "on" > "$SHUFFLE_FILE"
    mpc random on > /dev/null

    # Kalau ada kategori yang lagi aktif, langsung reload folder itu jadi mode shuffle
    ACTIVE=$( [ -f "$ACTIVE_FILE" ] && cat "$ACTIVE_FILE" )
    if [ -n "$ACTIVE" ]; then
        mpc stop > /dev/null 2>&1; mpc clear > /dev/null
        mpc add "$ACTIVE" 2>/dev/null
        mpc random on > /dev/null
        mpc play > /dev/null
    fi
    notify-send "Music Shuffle" "On"
fi
