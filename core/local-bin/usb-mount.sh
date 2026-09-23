#!/bin/bash
# usb-mount.sh
# Deteksi otomatis: USB flashdisk (block device) atau HP Android (MTP)
# Mount, lalu langsung buka Omafiles di lokasi mount-nya.
# Catatan: USB flashdisk biasa sudah auto-detect lewat Omafiles/gvfs -
# script ini kepakai utamanya buat HP Android (MTP), yang TIDAK
# ke-detect otomatis oleh udisks2/gvfs.

DEVICE=""
while IFS= read -r line; do
    NAME=""; RM=""; MOUNTPOINT=""; TYPE=""
    eval "$line"
    if [ "$RM" = "1" ] && [ "$TYPE" = "part" ] && [ -z "$MOUNTPOINT" ]; then
        DEVICE="$NAME"
        break
    fi
done < <(lsblk -Pno NAME,RM,MOUNTPOINT,TYPE)

if [ -n "$DEVICE" ]; then
    RESULT=$(udisksctl mount -b "/dev/$DEVICE" 2>&1)
    MOUNTPOINT=$(echo "$RESULT" | grep -oP "(?<=at ).*" | tr -d '.')
    if [ -n "$MOUNTPOINT" ]; then
        notify-send "USB Flashdisk Terpasang" "Buka di $MOUNTPOINT"
        env QT_QUICK_BACKEND=software /home/DrDDrake/.local/bin/omafiles "$MOUNTPOINT" &
        disown
        exit 0
    else
        notify-send -u critical "Mount Flashdisk Gagal" "$RESULT"
        exit 1
    fi
fi

MTP_MOUNT=~/Android
mkdir -p "$MTP_MOUNT"

if mountpoint -q "$MTP_MOUNT"; then
    notify-send "HP Sudah Terpasang" "Buka di $MTP_MOUNT"
    env QT_QUICK_BACKEND=software /home/DrDDrake/.local/bin/omafiles "$MTP_MOUNT" &
    disown
    exit 0
fi

if jmtpfs "$MTP_MOUNT" 2>/tmp/jmtpfs-error.log; then
    notify-send "HP Terpasang (MTP)" "Buka di $MTP_MOUNT"
    env QT_QUICK_BACKEND=software /home/DrDDrake/.local/bin/omafiles "$MTP_MOUNT" &
    disown
    exit 0
fi

notify-send -u critical "Tidak Ada Device Terdeteksi" "Cek kabel USB, atau ubah mode USB HP ke File Transfer/MTP"
exit 1
