#!/bin/bash
# sway-window-switcher.sh
# Pilih window aktif (semua workspace) lewat fuzzel --dmenu, lalu fokus ke situ.
# Format baris: <workspace>  <app_id> — <judul>, pakai icon app kalau ada.

mapfile -t ROWS < <(swaymsg -t get_tree | jq -r '
  .. | objects | select(.type == "workspace" and .name != "__i3_scratch")
  | .name as $ws
  | recurse(.nodes[]?, .floating_nodes[]?)
  | select((.type == "con" or .type == "floating_con") and .pid != null)
  | [.id, $ws, (.app_id // .window_properties.class // "?"), (.name // "")]
  | @tsv')

[ "${#ROWS[@]}" -eq 0 ] && exit 0

IDX=$(
    for row in "${ROWS[@]}"; do
        IFS=$'\t' read -r _id ws app title <<< "$row"
        # \0icon\x1f<nama> = ekstensi icon gaya rofi, didukung fuzzel dmenu mode
        printf '%s  %s — %s\0icon\x1f%s\n' "$ws" "$app" "$title" "$app"
    done | fuzzel --dmenu --index --prompt "Window ❯ " --width 80 --lines 15
) || exit 0   # Esc / batal -> keluar diam-diam

CON_ID=$(cut -f1 <<< "${ROWS[$IDX]}")
swaymsg "[con_id=$CON_ID] focus" >/dev/null
