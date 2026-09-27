#!/bin/bash
OUTPUT_NAME="DP-3"

MODES=$(swaymsg -t get_outputs -r | jq -r --arg name "$OUTPUT_NAME" '
  .[] | select(.name == $name) | .modes[] |
  "\(.width)x\(.height)@\((.refresh/1000)|floor)Hz|\(.width)|\(.height)|\(.refresh)"
' | sort -u -t'|' -k1,1)

DISPLAY_LIST=$(echo "$MODES" | awk -F'|' '{print $1}')

CHOICE=$(echo "$DISPLAY_LIST" | fuzzel --dmenu --no-exit-on-keyboard-focus-loss --prompt "Resolusi: ")
[ -z "$CHOICE" ] && exit 0

LINE=$(echo "$MODES" | awk -F'|' -v c="$CHOICE" '$1==c' | head -n1)
W=$(echo "$LINE" | awk -F'|' '{print $2}')
H=$(echo "$LINE" | awk -F'|' '{print $3}')
REFRESH_MHZ=$(echo "$LINE" | awk -F'|' '{print $4}')
REFRESH_HZ=$(awk -v r="$REFRESH_MHZ" 'BEGIN{printf "%.3f", r/1000}')

swaymsg output "$OUTPUT_NAME" mode "${W}x${H}@${REFRESH_HZ}Hz"

/home/DrDDrake/.local/bin/obs-sync-video-settings.py "$W" "$H" "$REFRESH_HZ"

notify-send "Display Mode" "Diganti ke ${W}x${H}@${REFRESH_HZ}Hz"
