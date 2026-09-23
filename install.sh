#!/bin/bash
# install.sh — apply dotfiles. Jalan sebagai user biasa di sesi Sway.
# Usage: ./install.sh daily [work ...]
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES=("$@")

if [ "${#PROFILES[@]}" -eq 0 ]; then
    echo "Usage: $0 <profile> [profile2 ...]"
    echo "Contoh: $0 daily work"
    exit 1
fi

echo "==> [1/6] Repo Arch (core+extra+multilib)"
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
sudo pacman -S --needed --noconfirm core/expat

echo "==> [2/6] Symlink config core"
mkdir -p ~/.config ~/.local/bin ~/.local/state
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
for f in "$DOTFILES_DIR"/core/local-bin/*; do
    [ -e "$f" ] || continue
    ln -sf "$f" ~/.local/bin/
    chmod +x ~/.local/bin/"$(basename "$f")"
done

echo "==> [3/6] Copy /etc + state Noctalia + wallpaper + plugin"
if [ -f "$DOTFILES_DIR/core/etc/mpd.conf" ]; then
    sudo cp "$DOTFILES_DIR/core/etc/mpd.conf" /etc/mpd.conf
    sudo sv restart mpd 2>/dev/null || true
fi
mkdir -p ~/.local/state/noctalia
if [ -f "$DOTFILES_DIR/core/noctalia-state/settings.toml" ] && [ ! -f ~/.local/state/noctalia/settings.toml ]; then
    cp "$DOTFILES_DIR/core/noctalia-state/settings.toml" ~/.local/state/noctalia/settings.toml
fi
mkdir -p ~/Pictures/Wallpapers
cp -n "$DOTFILES_DIR"/core/assets/* ~/Pictures/Wallpapers/ 2>/dev/null || true
mkdir -p ~/.config/noctalia/plugins/d3vzero/mpd-tools
cp -r "$DOTFILES_DIR"/core/noctalia-plugins/mpd-tools/. ~/.config/noctalia/plugins/d3vzero/mpd-tools/

echo "==> [4/6] Paket core + jmtpfs (AUR)"
sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR"/core/packages.txt
aur sync --noview jmtpfs
sudo pacman -Sy
sudo pacman -S --needed --noconfirm jmtpfs

echo "==> [5/6] Build manual: Omafiles + ble.sh"
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

echo "==> [6/6] Profil tambahan"
for profile in "${PROFILES[@]}"; do
    PDIR="$DOTFILES_DIR/profiles/$profile"
    if [ ! -d "$PDIR" ]; then
        echo "!! Profile '$profile' tidak ada, skip."
        continue
    fi
    echo "    -> Profile: $profile"

    [ -f "$PDIR/packages.txt" ] && sudo pacman -S --needed --noconfirm - < "$PDIR/packages.txt"

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
echo "==> SELESAI. Reload Sway: swaymsg reload"
echo "!! Manual: plugin MPD Tools (Settings -> Plugins), Steam Storage,"
echo "   Proton-GE (profiles/daily/scripts/install-proton-ge.sh),"
echo "   llama.cpp (profiles/work/scripts/build-llamacpp.sh) + model GGUF"
