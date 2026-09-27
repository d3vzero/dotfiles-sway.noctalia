#!/bin/bash
set -euo pipefail

STATE_DIR="$HOME/.cache/casual-record"
PID_FILE="$STATE_DIR/wf-recorder.pid"
MODULES_FILE="$STATE_DIR/modules.txt"
OUT_DIR="$HOME/Videos/Casual"
mkdir -p "$STATE_DIR" "$OUT_DIR"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    # --- STOP ---
    kill -INT "$(cat "$PID_FILE")"
    sleep 1
    rm -f "$PID_FILE"

    if [ -f "$MODULES_FILE" ]; then
        # Unload TERBALIK dari urutan load: loopback dulu (mereka "nebeng"
        # ke null-sink), null-sink PALING TERAKHIR. Unload null-sink duluan
        # sementara loopback masih nempel ke situ bikin PipeWire re-negotiate
        # graph mendadak -> sempat kepause stream lain (Firefox/YouTube).
        tac "$MODULES_FILE" | while read -r modid; do
            [ -n "$modid" ] && pactl unload-module "$modid" 2>/dev/null || true
        done
        rm -f "$MODULES_FILE"
    fi

    notify-send "Casual Record" "Rekaman dihentikan, tersimpan di $OUT_DIR"
else
    # --- START ---
    # Ambil nama sink LITERAL sekali di awal (bukan macro @DEFAULT_SINK@) --
    # loopback ke nama statis lebih sederhana buat PipeWire dibanding macro
    # dinamis yang butuh WirePlumber terus melacak "siapa default sekarang".
    DEFAULT_SINK=$(pactl get-default-sink)
    DEFAULT_SOURCE=$(pactl get-default-source)

    MOD1=$(pactl load-module module-null-sink sink_name=casual_record_mix sink_properties=device.description=CasualRecordMix)
    MOD2=$(pactl load-module module-loopback source="${DEFAULT_SINK}.monitor" sink=casual_record_mix)
    MOD3=$(pactl load-module module-loopback source="$DEFAULT_SOURCE" sink=casual_record_mix)
    printf '%s\n%s\n%s\n' "$MOD1" "$MOD2" "$MOD3" > "$MODULES_FILE"

    OUT_FILE="$OUT_DIR/casual_$(date +%Y%m%d-%H%M%S).mkv"
    wf-recorder --audio=casual_record_mix.monitor -f "$OUT_FILE" &
    echo $! > "$PID_FILE"

    notify-send "Casual Record" "Mulai rekam (display + system + mic)"
fi
