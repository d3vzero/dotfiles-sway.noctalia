#!/bin/bash
# install.sh -- layer user dotfiles-sway.noctalia.
# Jalan sebagai user biasa (BUKAN root). Boleh dari tty1 polos (pertama
# kali setelah bootstrap/install-chroot.sh, Sway belum pernah jalan) atau
# dari dalam sesi Sway. Aman di-run ulang kapan saja (idempotent).
# Usage: ./install.sh <profil> [profil ...]    contoh: ./install.sh daily work ai
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES=("$@")
ME="$(id -un)"

if [ "$(id -u)" -eq 0 ]; then
    echo "!! Jangan jalankan sebagai root/sudo -- jalankan sebagai user biasa."
    exit 1
fi
if [ "${#PROFILES[@]}" -eq 0 ]; then
    echo "Usage: $0 <profil> [profil ...]"
    echo "Profil tersedia: $(ls "$DOTFILES_DIR/profiles" | tr '\n' ' ')"
    exit 1
fi

echo "==> [1/8] Repo Arch (core+extra+multilib) + full upgrade"
sudo pacman -S --needed --noconfirm artix-archlinux-support
if ! grep -q "^\[extra\]" /etc/pacman.conf; then
sudo tee -a /etc/pacman.conf > /dev/null <<'EOF'

[core]
Include = /etc/pacman.d/mirrorlist-arch

[extra]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch
EOF
fi
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Syu --noconfirm
# expat = paket [core] Arch; lib32-expat (multilib) pin ke versi ini PERSIS.
sudo pacman -S --needed --noconfirm core/expat

echo "==> [2/8] Paket core"
sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/core/packages.txt"

echo "==> [3/8] aurutils + repo lokal /var/cache/aurrepo"
if ! command -v aur >/dev/null 2>&1; then
    rm -rf /tmp/aurutils-src
    git clone https://aur.archlinux.org/aurutils.git /tmp/aurutils-src
    (cd /tmp/aurutils-src && makepkg -si --noconfirm)
    rm -rf /tmp/aurutils-src
fi
# Repo lokal DILUAR $HOME -- sejak pacman 7.0 download jalan sebagai user
# sandbox "alpm", yang tidak bisa nembus $HOME (permission 700).
if [ ! -f /var/cache/aurrepo/aur.db.tar.zst ]; then
    sudo mkdir -p /var/cache/aurrepo
    sudo chown "$ME":alpm /var/cache/aurrepo
    sudo chmod 750 /var/cache/aurrepo
    repo-add /var/cache/aurrepo/aur.db.tar.zst
fi
if ! grep -q "^\[aur\]" /etc/pacman.conf; then
sudo tee -a /etc/pacman.conf > /dev/null <<'EOF'

[aur]
SigLevel = Optional TrustAll
Server = file:///var/cache/aurrepo
EOF
fi
sudo pacman -Sy

echo "==> [4/8] jmtpfs (AUR, buat usb-mount.sh MTP)"
aur sync --noview jmtpfs
sudo pacman -Sy
sudo pacman -S --needed --noconfirm jmtpfs

echo "==> [5/8] Symlink config"
mkdir -p ~/.config ~/.local/bin ~/.local/state ~/.local/share/applications
BACKUP=~/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)
backup_if_real() {
    if [ -e "$1" ] && [ ! -L "$1" ]; then
        mkdir -p "$BACKUP"; mv "$1" "$BACKUP/"
        echo "    backup: $1 -> $BACKUP/"
    fi
}
for dir in "$DOTFILES_DIR"/core/config/*/; do
    name=$(basename "$dir")
    backup_if_real ~/.config/"$name"
    ln -sfn "${dir%/}" ~/.config/"$name"
    echo "    ~/.config/$name -> ${dir%/}"
done
backup_if_real ~/.bashrc
ln -sf "$DOTFILES_DIR/core/config/bashrc" ~/.bashrc
backup_if_real ~/.bash_profile
ln -sf "$DOTFILES_DIR/core/config/bash_profile" ~/.bash_profile
for f in "$DOTFILES_DIR"/core/local-bin/*; do
    [ -e "$f" ] || continue
    ln -sf "$f" ~/.local/bin/
    chmod +x ~/.local/bin/"$(basename "$f")"
done
for f in "$DOTFILES_DIR"/core/applications/*.desktop; do
    [ -e "$f" ] || continue
    ln -sf "$f" ~/.local/share/applications/
done
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
for mime in text/plain text/markdown text/x-shellscript application/x-shellscript; do
    xdg-mime default nvim-kitty.desktop "$mime"
done

echo "==> [6/8] Folder kerja, /etc/mpd.conf, state Noctalia, wallpaper, plugin"
mkdir -p ~/.local/state/mpd ~/Pictures/Wallpapers \
  ~/Music/Album ~/Music/Single ~/Music/Cover \
  ~/Videos/OBS/RAW ~/Videos/OBS/Split/All ~/Videos/OBS/Split/Screen \
  ~/Videos/OBS/Split/Audio ~/Videos/OBS/Split/Mic ~/Videos/Casual
if [ -f "$DOTFILES_DIR/core/etc/mpd.conf" ]; then
    sudo cp "$DOTFILES_DIR/core/etc/mpd.conf" /etc/mpd.conf
    sudo sv restart mpd 2>/dev/null || true
fi
# settings.toml = STATE (Noctalia nulis balik saat runtime) -> copy sekali, bukan symlink
mkdir -p ~/.local/state/noctalia
if [ ! -f ~/.local/state/noctalia/settings.toml ]; then
    cp "$DOTFILES_DIR/core/noctalia-state/settings.toml" ~/.local/state/noctalia/settings.toml
fi
cp -n "$DOTFILES_DIR"/core/assets/* ~/Pictures/Wallpapers/ 2>/dev/null || true
mkdir -p ~/.config/noctalia/plugins/d3vzero/mpd-tools
cp -r "$DOTFILES_DIR"/core/noctalia-plugins/mpd-tools/. ~/.config/noctalia/plugins/d3vzero/mpd-tools/

echo "==> [7/8] Build manual: Omafiles + ble.sh"
if [ ! -x ~/.local/bin/omafiles ] && ! command -v omafiles >/dev/null 2>&1; then
    rm -rf /tmp/omafiles-src
    git clone https://github.com/Percius04/omafiles /tmp/omafiles-src
    cmake -S /tmp/omafiles-src -B /tmp/omafiles-src/build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
    ninja -C /tmp/omafiles-src/build
    cmake --install /tmp/omafiles-src/build
    rm -rf /tmp/omafiles-src
fi
if [ ! -f ~/.local/share/blesh/ble.sh ]; then
    rm -rf /tmp/ble.sh-src
    git clone --recursive https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh-src
    make -C /tmp/ble.sh-src install PREFIX="$HOME/.local"
    rm -rf /tmp/ble.sh-src
fi

mkdir -p ~/.config/sway/conf.d

echo "==> [8/8] Profil: ${PROFILES[*]}"
for profile in "${PROFILES[@]}"; do
    PDIR="$DOTFILES_DIR/profiles/$profile"
    if [ ! -d "$PDIR" ]; then
        echo "!! Profil '$profile' tidak ada, skip."
        continue
    fi
    echo "    -> Profil: $profile"

    if [ -f "$PDIR/packages.txt" ]; then
        sudo pacman -S --needed --noconfirm - < "$PDIR/packages.txt"
    fi

    if [ -f "$PDIR/packages-aur.txt" ]; then
        # baca ke array dulu -- JANGAN "done < file", itu membajak stdin
        # dan bikin prompt [Y/n] makepkg gagal otomatis
        mapfile -t AUR_PKGS < <(grep -v '^[[:space:]]*$' "$PDIR/packages-aur.txt")
        aur sync --noview "${AUR_PKGS[@]}"
        sudo pacman -Sy
        sudo pacman -S --needed --noconfirm - < "$PDIR/packages-aur.txt"
    fi

    if [ -f "$PDIR/config/sway-$profile.conf" ]; then
        ln -sf "$PDIR/config/sway-$profile.conf" ~/.config/sway/conf.d/10-"$profile".conf
    fi

    if [ "$profile" = "daily" ]; then
        DAVINCI_ZIP=$(find "$PDIR/files/davinci" -maxdepth 1 -iname "DaVinci_Resolve_*_Linux.zip" 2>/dev/null | head -n1)
        if [ -n "$DAVINCI_ZIP" ]; then
            echo "    DaVinci installer ketemu: $DAVINCI_ZIP"
            mkdir -p ~/aur-manual && cd ~/aur-manual
            [ -d davinci-resolve ] || git clone https://aur.archlinux.org/davinci-resolve.git
            cd davinci-resolve
            cp "$DAVINCI_ZIP" .
            makepkg -si --noconfirm
            cd "$DOTFILES_DIR"
        else
            echo "    DaVinci installer tidak ada di $PDIR/files/davinci/ -- skip"
        fi
    fi
done

echo ""
echo "==> SELESAI."
echo "   - Dari tty1 (Sway belum jalan): logout, login lagi -> Sway start otomatis"
echo "   - Dari dalam Sway: swaymsg reload"
echo "!! Langkah manual: lihat docs/INSTALL.md bagian 5"
