#!/bin/bash
# bootstrap/install-chroot.sh
# Jalan DI DALAM `artix-chroot /mnt` sebagai root, dari repo yang sudah
# di-clone ke /opt/dotfiles (lihat docs/INSTALL.md langkah 3).
#
# Cakupan: HANYA level sistem (butuh root, sekali jalan).
# Semua level user (config, aurutils, jmtpfs, Omafiles, ble.sh, profil)
# dikerjakan ./install.sh SETELAH reboot, sebagai user biasa -- jadi tidak
# ada lagi su/run_as_user/XDG_RUNTIME_DIR workaround di sini.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_NAME="DrDDrake"
HOST_NAME="DracoAtom-PC"
HOME_DIR="/home/$USER_NAME"
DEST="$HOME_DIR/dotfiles-sway.noctalia"

if [ "$(id -u)" -ne 0 ]; then
    echo "!! Harus root (jalankan di dalam artix-chroot)."
    exit 1
fi
# Tolak jalan di sistem yang sedang hidup: di dalam chroot, "/" berbeda
# dengan root milik PID 1 (host). Kalau sama -> bukan chroot -> stop.
if [ "$(stat -c %d:%i /)" = "$(stat -c %d:%i /proc/1/root/.)" ]; then
    echo "!! Bukan di dalam chroot. Script ini HANYA untuk instalasi baru"
    echo "   (artix-chroot /mnt). Untuk sistem yang sudah jalan: ./install.sh"
    exit 1
fi

echo "==> [1/12] Timezone & clock"
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
hwclock --systohc

echo "==> [2/12] Locale"
grep -v "en_US.UTF-8 UTF-8" /etc/locale.gen > /tmp/locale.gen.new || true
echo "en_US.UTF-8 UTF-8" >> /tmp/locale.gen.new
mv /tmp/locale.gen.new /etc/locale.gen
locale-gen
if ! locale -a | grep -qi en_US.utf8; then
    echo "!! locale gagal generate, cek manual: grep -n en_US /etc/locale.gen"
    exit 1
fi
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "==> [3/12] Hostname"
echo "$HOST_NAME" > /etc/hostname

echo "==> [4/12] Repo Arch (core + extra + multilib)"
pacman -S --needed --noconfirm artix-archlinux-support
if ! grep -q "^\[extra\]" /etc/pacman.conf; then
cat >> /etc/pacman.conf <<'EOF'

[core]
Include = /etc/pacman.d/mirrorlist-arch

[extra]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch
EOF
fi
pacman-key --init
pacman-key --populate archlinux

echo "==> [5/12] Full upgrade + core/expat"
pacman -Syu --noconfirm
# expat = paket [core] Arch; lib32-expat (multilib) pin ke versi ini PERSIS.
# Artix native expat (world/galaxy) bisa beda revisi -> Steam gagal resolve.
pacman -S --needed --noconfirm core/expat

echo "==> [6/12] Paket core (dari core/packages.txt di repo)"
pacman -S --needed --noconfirm - < "$REPO_DIR/core/packages.txt"

echo "==> [7/12] NVIDIA: blacklist nouveau + KMS"
cat > /etc/modprobe.d/nvidia.conf <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -P

echo "==> [8/12] GRUB"
if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 nvidia.NVreg_EnableGpuFirmware=1 /' /etc/default/grub
fi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Artix
grub-mkconfig -o /boot/grub/grub.cfg

echo "==> [9/12] tmpfs (RAMdisk)"
if ! grep -q "$HOME_DIR/.cache" /etc/fstab; then
cat >> /etc/fstab <<EOF
tmpfs   /tmp        tmpfs   rw,nosuid,nodev,size=4G     0 0
tmpfs   /var/tmp    tmpfs   rw,nosuid,nodev,size=1G     0 0
tmpfs   $HOME_DIR/.cache   tmpfs   rw,nosuid,nodev,size=6G,uid=1000,gid=100   0 0
EOF
fi

echo "==> [10/12] Service runit"
for svc in dbus NetworkManager mpd bluetoothd sshd agetty-tty1; do
    ln -sf /etc/runit/sv/$svc /etc/runit/runsvdir/default/
done
# udisks2 SENGAJA tidak di-link -> D-Bus-activated, tidak perlu supervisi runit

echo "==> [11/12] User & sudo"
if ! id "$USER_NAME" >/dev/null 2>&1; then
    useradd -m -g users -G wheel,video,audio -s /bin/bash "$USER_NAME"
fi
echo ">> Set password root:"
passwd
echo ">> Set password $USER_NAME:"
passwd "$USER_NAME"
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "$USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/reboot, /usr/bin/poweroff" > "/etc/sudoers.d/10-$USER_NAME-power"
chmod 440 "/etc/sudoers.d/10-$USER_NAME-power"

echo "==> [12/12] Taruh repo dotfiles di home user"
if [ ! -d "$DEST" ]; then
    cp -a "$REPO_DIR" "$DEST"
fi
mkdir -p "$HOME_DIR/.cache"
chown -R "$USER_NAME":users "$HOME_DIR"

echo ""
echo "==> SELESAI bootstrap."
echo "    exit  ->  umount -R /mnt  ->  reboot  (cabut USB live)"
echo "    Setelah reboot, login $USER_NAME di tty1, lalu:"
echo "      cd ~/dotfiles-sway.noctalia && ./install.sh daily work ai"
