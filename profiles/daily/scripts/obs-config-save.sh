#!/bin/bash
# obs-config-save.sh -- simpan setting OBS (~/.config/obs-studio) ke repo.
# TUTUP OBS DULU: sebagian setting baru ditulis OBS saat keluar.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SRC="$HOME/.config/obs-studio"
DST="$DOTFILES_DIR/profiles/daily/obs-studio"

if pgrep -x obs >/dev/null; then
    echo "!! OBS masih jalan. Tutup dulu, lalu ulangi."
    exit 1
fi
[ -d "$SRC" ] || { echo "!! $SRC tidak ada"; exit 1; }

rm -rf "$DST"
mkdir -p "$DST"
# Dibuang: log/crash/cache, cookie+cache dock browser (obs-browser),
# stream key (service.json), backup otomatis.
tar -C "$SRC" \
    --exclude=logs --exclude=crashes --exclude=profiler_data --exclude=updates \
    --exclude=obs-browser --exclude=rtmp-services --exclude=service.json --exclude='*.bak' --exclude='.sentinel' \
    -cf - . | tar -C "$DST" -xf -

# Password WebSocket dikosongkan -- diisi ulang install.sh dari ~/.config/obs-tools/password
WS="$DST/plugin_config/obs-websocket/config.json"
if [ -f "$WS" ]; then
    jq '.server_password = ""' "$WS" > "$WS.tmp" && mv "$WS.tmp" "$WS"
fi

echo "==> Tersimpan ke $DST ($(du -sh "$DST" | cut -f1))"
echo "==> Cek data sensitif:"
grep -rniE 'stream_?key|server_password"[^"]*"[^"]+"|secret' "$DST" || echo "    (tidak ada, aman)"
