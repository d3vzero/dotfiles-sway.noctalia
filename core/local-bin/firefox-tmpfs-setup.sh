#!/bin/bash
# firefox-tmpfs-setup.sh
# Jalankan SEKALI SAJA, Firefox harus tertutup total (pgrep firefox kosong).
# Pindah file yang paling sering ditulis Firefox ke tmpfs (~/.cache),
# supaya tidak terus-terusan nulis ke NVMe. Password/bookmark/history/
# settings TETAP permanen (tidak dipindah/disentuh).

set -euo pipefail

if pgrep -x firefox >/dev/null; then
    echo "!! Firefox masih jalan. Tutup dulu total, lalu ulangi."
    exit 1
fi

PROFILE_DIR=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -n1)
if [ -z "$PROFILE_DIR" ]; then
    echo "!! Profile Firefox tidak ketemu. Pastikan Firefox sudah pernah dibuka"
    echo "   minimal 1x (dan ditutup total) sebelum jalankan script ini."
    exit 1
fi

VOLATILE_DIR=~/.cache/firefox-volatile
mkdir -p "$VOLATILE_DIR"

move_and_link() {
    local target="$1"
    local src="$PROFILE_DIR/$target"
    local dst="$VOLATILE_DIR/$target"

    if [ -L "$src" ]; then
        echo "   $target sudah symlink, skip."
        return
    fi
    if [ -e "$src" ]; then
        mv "$src" "$dst"
    fi
    ln -s "$dst" "$src"
    echo "   $target -> $dst"
}

echo "==> Profile: $PROFILE_DIR"
move_and_link "cookies.sqlite"
move_and_link "cookies.sqlite-wal"
move_and_link "cookies.sqlite-shm"
move_and_link "storage"
move_and_link "sessionstore-backups"
move_and_link "sessionstore.jsonlz4"

echo "==> Selesai. firefox-tmpfs-recreate.sh sudah otomatis jalan tiap sesi"
echo "    Sway start (lewat exec di config) - tidak perlu diulang manual."
echo ""
echo "Konsekuensi: cookies fresh tiap reboot (semua login web logout tiap"
echo "restart PC), tab restore hilang tiap reboot PC (bukan tiap restart"
echo "Firefox biasa)."
