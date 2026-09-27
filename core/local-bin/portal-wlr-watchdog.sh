#!/bin/bash
# portal-wlr-watchdog.sh
# Loop selama sesi Sway hidup -- cek tiap 15 detik apakah
# xdg-desktop-portal-wlr masih hidup. Kalau mati (race condition
# startup atau crash acak), restart otomatis + bounce dispatcher
# utama (xdg-desktop-portal) biar dia re-scan backend yang baru
# hidup -- persis urutan fix manual yang sudah terbukti berhasil.

CHECK_INTERVAL=15

while true; do
    if ! pgrep -f "xdg-desktop-portal-wlr" >/dev/null; then
        notify-send -u critical "Portal Watchdog" "xdg-desktop-portal-wlr mati, restart otomatis..."

        /usr/lib/xdg-desktop-portal-wlr &
        disown
        sleep 1

        pkill -f "^/usr/lib/xdg-desktop-portal$" 2>/dev/null
        sleep 1
        /usr/lib/xdg-desktop-portal &
        disown

        sleep 2
        if pgrep -f "xdg-desktop-portal-wlr" >/dev/null; then
            notify-send "Portal Watchdog" "xdg-desktop-portal-wlr pulih normal"
        else
            notify-send -u critical "Portal Watchdog" "Gagal restart otomatis, perlu cek manual"
        fi
    fi
    sleep "$CHECK_INTERVAL"
done
