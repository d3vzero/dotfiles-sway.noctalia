#!/bin/bash
# music-category-status.sh <Album|Single|Cover>
CATEGORY="$1"
ACTIVE_FILE=~/.cache/waybar-music/active_category
ACTIVE=$( [ -f "$ACTIVE_FILE" ] && cat "$ACTIVE_FILE" )

if [ "$ACTIVE" = "$CATEGORY" ]; then
    echo "[$CATEGORY]"
else
    echo "$CATEGORY"
fi
