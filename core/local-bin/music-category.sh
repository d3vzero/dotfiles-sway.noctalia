#!/bin/bash
# music-category.sh <Album|Single|Cover>
CATEGORY="$1"
if [ -z "$CATEGORY" ]; then
    echo "Usage: $0 <Album|Single|Cover>"
    exit 1
fi

STATE_DIR=~/.cache/waybar-music
mkdir -p "$STATE_DIR"
SHUFFLE_FILE="$STATE_DIR/shuffle"
ACTIVE_FILE="$STATE_DIR/active_category"
INDEX_FILE="$STATE_DIR/index_$CATEGORY"
LAST_CLICKED_FILE="$STATE_DIR/last_clicked"

SHUFFLE_ON=$( [ -f "$SHUFFLE_FILE" ] && cat "$SHUFFLE_FILE" )

if [ "$SHUFFLE_ON" = "on" ]; then
    # --- MODE SHUFFLE: acak seluruh folder kategori ---
    echo "$CATEGORY" > "$ACTIVE_FILE"
    mpc stop > /dev/null 2>&1; mpc clear > /dev/null
    mpc add "$CATEGORY" 2>/tmp/mpc-error.log
    if [ $? -ne 0 ]; then
        notify-send -u critical "Music" "Gagal load folder $CATEGORY — cek: mpc ls \"$CATEGORY\""
        exit 1
    fi
    mpc random on > /dev/null
    mpc play > /dev/null
    notify-send "Music (Shuffle)" "Memutar acak dari folder $CATEGORY"
else
    # --- MODE SEQUENTIAL: cycle subfolder satu-satu ---
    echo "$CATEGORY" > "$ACTIVE_FILE"
    mpc random off > /dev/null

    mapfile -t FOLDERS < <(mpc ls "$CATEGORY" 2>/tmp/mpc-error.log | sort)
    TOTAL=${#FOLDERS[@]}
    if [ "$TOTAL" -eq 0 ]; then
        notify-send -u critical "Music" "Folder $CATEGORY kosong atau tidak ditemukan"
        exit 1
    fi

    IDX=0
    [ -f "$INDEX_FILE" ] && IDX=$(cat "$INDEX_FILE")
    LAST=$( [ -f "$LAST_CLICKED_FILE" ] && cat "$LAST_CLICKED_FILE" )

    if [ "$LAST" = "$CATEGORY" ]; then
        IDX=$(( (IDX + 1) % TOTAL ))
    else
        IDX=0
    fi
    echo "$CATEGORY" > "$LAST_CLICKED_FILE"
    echo "$IDX" > "$INDEX_FILE"

    TARGET="${FOLDERS[$IDX]}"
    mpc stop > /dev/null 2>&1; mpc clear > /dev/null
    mpc add "$TARGET" > /dev/null
    mpc play > /dev/null
    notify-send "Music: $CATEGORY" "Memutar folder $((IDX + 1))/$TOTAL: $(basename "$TARGET")"
fi
