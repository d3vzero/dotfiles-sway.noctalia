#!/bin/bash
SHUFFLE_FILE=~/.cache/waybar-music/shuffle
STATE=$( [ -f "$SHUFFLE_FILE" ] && cat "$SHUFFLE_FILE" )

if [ "$STATE" = "on" ]; then
    echo "Shuffle: ON"
else
    echo "Shuffle: OFF"
fi
