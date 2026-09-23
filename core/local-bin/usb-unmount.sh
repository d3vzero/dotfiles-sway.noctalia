#!/bin/bash
# usb-unmount.sh
# Lepas semua USB flashdisk yang ter-mount (unmount + power-off, aman dicabut)
# dan HP Android (MTP) kalau sedang terpasang.

UNMOUNTED=0

while IFS= read -r line; do
    NAME=""; RM=""; MOUNTPOINT=""; TYPE=""
    eval "$line"
    if [ "$RM" = "1" ] && [ "$TYPE" = "part" ] && [ -n "$MOUNTPOINT" ]; then
        if udisksctl unmount -b "/dev/$NAME" 2>/dev/null; then
            udisksctl power-off -b "/dev/$NAME" 2>/dev/null
            UNMOUNTED=1
        fi
    fi
done < <(lsblk -Pno NAME,RM,MOUNTPOINT,TYPE)

if mountpoint -q ~/Android 2>/dev/null; then
    if fusermount -u ~/Android 2>/dev/null; then
        UNMOUNTED=1
    fi
fi

if [ "$UNMOUNTED" -eq 1 ]; then
    notify-send "USB Dilepas" "Aman untuk cabut flashdisk/kabel HP sekarang"
else
    notify-send "Tidak Ada yang Terpasang" "Tidak ada USB/HP yang sedang di-mount"
fi
