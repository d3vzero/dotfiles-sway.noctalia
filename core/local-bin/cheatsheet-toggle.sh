#!/bin/bash
MARK="cheatsheet_win"
CHEATSHEET_FILE="$HOME/.local/share/cheatsheet.txt"

if swaymsg -t get_marks | grep -q "\"$MARK\""; then
    swaymsg "[con_mark=\"$MARK\"] scratchpad show"
    exit 0
fi

kitty --app-id cheatsheet --title "Cheatsheet" -e less -R "$CHEATSHEET_FILE" &

FOUND=0
for _ in $(seq 1 100); do
    if swaymsg -t get_tree | grep -q "\"app_id\": \"cheatsheet\""; then
        FOUND=1
        break
    fi
    sleep 0.1
done

if [ "$FOUND" -eq 0 ]; then
    notify-send -u critical "Cheatsheet" "Jendela gagal terdeteksi dalam 10 detik"
    exit 1
fi

swaymsg "[app_id=\"cheatsheet\"] mark --add \"$MARK\""
swaymsg "[app_id=\"cheatsheet\"] floating enable"
swaymsg "[app_id=\"cheatsheet\"] resize set 700 600"
swaymsg "[app_id=\"cheatsheet\"] move position center"
swaymsg "[app_id=\"cheatsheet\"] move scratchpad"
swaymsg "[con_mark=\"$MARK\"] scratchpad show"
