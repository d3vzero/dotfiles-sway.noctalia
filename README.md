# dotfiles-sway.noctalia

Dotfiles Artix Linux (runit) + Sway + Noctalia + NVIDIA.

- `core/`     : config & paket yang dipakai semua profil
- `profiles/daily/` : Steam, OBS, DaVinci Resolve
- `profiles/work/`  : CUDA, llama.cpp, OnlyOffice

## Pakai

    git clone git@github.com:d3vzero/dotfiles-sway.noctalia.git ~/dotfiles-sway.noctalia
    cd ~/dotfiles-sway.noctalia
    ./install.sh daily work

Prasyarat: sistem dasar sudah terpasang (usb-installer) + aurutils.

## Manual (tidak diotomasi)

- Enable plugin MPD Tools: Settings -> Plugins
- Steam: Settings -> Storage -> Add Drive -> ~/Games/Steam/SteamLibrary
- Proton-GE: profiles/daily/scripts/install-proton-ge.sh
- DaVinci: taruh .zip di profiles/daily/files/davinci/, jalankan ulang install.sh
- llama.cpp: profiles/work/scripts/build-llamacpp.sh, model GGUF download manual
