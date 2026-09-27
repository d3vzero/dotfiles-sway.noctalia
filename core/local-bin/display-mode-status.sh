#!/bin/bash
OUTPUT_NAME="DP-3"
INFO=$(swaymsg -t get_outputs -r | jq -r --arg name "$OUTPUT_NAME" \
  '.[] | select(.name == $name) | "\(.current_mode.width)x\(.current_mode.height) \(.current_mode.refresh)"')
WH=$(echo "$INFO" | awk '{print $1}')
REFRESH_MHZ=$(echo "$INFO" | awk '{print $2}')
REFRESH_HZ=$(awk -v r="$REFRESH_MHZ" 'BEGIN{printf "%.0f", r/1000}')
echo "${WH}@${REFRESH_HZ}Hz"
