#!/bin/bash
set -euo pipefail
mkdir -p ~/.local/share/Steam/compatibilitytools.d
cd ~/.local/share/Steam/compatibilitytools.d
RELEASE_JSON=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest)
TARBALL_URL=$(echo "$RELEASE_JSON" | grep browser_download_url | cut -d '"' -f4 | grep -E '\-x86_64\.tar\.gz$')
curl -L "$TARBALL_URL" -o proton-ge.tar.gz
tar -xzf proton-ge.tar.gz
rm proton-ge.tar.gz
echo "Proton-GE ter-extract. Restart Steam total biar kedeteksi."
