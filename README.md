# dotfiles-sway.noctalia

Artix Linux (runit) + Sway + Noctalia + NVIDIA — dari partisi kosong
sampai desktop jadi, dalam 1 repo.

**Panduan lengkap: [`docs/INSTALL.md`](docs/INSTALL.md)**

## Isi

- `bootstrap/install-chroot.sh` — level sistem, jalan sekali di dalam chroot (root)
- `install.sh` — level user, jalan setelah reboot, aman di-run ulang
- `core/` — config, script, plugin Noctalia, paket yang dipakai semua profil
- `profiles/daily/` — Steam, OBS, DaVinci Resolve, Proton-GE
- `profiles/work/` — OnlyOffice, FreeCAD, KiCad
- `profiles/ai/` — CUDA, llama.cpp

## Ringkas

Dari USB live, setelah partisi + mount + basestrap:

    artix-chroot /mnt
    git clone https://github.com/d3vzero/dotfiles-sway.noctalia /opt/dotfiles
    bash /opt/dotfiles/bootstrap/install-chroot.sh

Setelah reboot, login di tty1:

    cd ~/dotfiles-sway.noctalia
    ./install.sh daily work ai

Update:

    git pull && ./install.sh daily work ai && swaymsg reload
