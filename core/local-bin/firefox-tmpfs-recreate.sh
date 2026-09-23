#!/bin/bash
# firefox-tmpfs-recreate.sh
# Jalan tiap startup sesi Sway (via exec di config), SEBELUM Firefox
# dibuka. ~/.cache ada di tmpfs -> kosong lagi tiap reboot. Script ini
# nyiapin ulang skeleton folder/file kosong di lokasi yang sama, biar
# symlink dari profile Firefox tidak nunjuk ke path yang hilang.
# Aman dijalankan walau firefox-tmpfs-setup.sh belum pernah dijalankan
# (cuma bikin folder kosong, tidak error).

VOLATILE_DIR=~/.cache/firefox-volatile
mkdir -p "$VOLATILE_DIR/storage"
mkdir -p "$VOLATILE_DIR/sessionstore-backups"
touch "$VOLATILE_DIR/cookies.sqlite"
