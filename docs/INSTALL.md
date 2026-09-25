# Instalasi dari Nol — Artix runit + Sway + Noctalia

Satu panduan dari USB live sampai desktop jadi. Yang manual cuma yang
memang harus manual (partisi, password, login GUI). Sisanya 2 script:

| Script | Kapan | Sebagai | Cakupan |
|---|---|---|---|
| `bootstrap/install-chroot.sh` | Di dalam chroot, sekali | root | Level sistem: locale, repo, paket core, NVIDIA, GRUB, tmpfs, runit, user |
| `install.sh <profil...>` | Setelah reboot, kapan saja | user | Level user: config, aurutils, jmtpfs, Omafiles, ble.sh, profil |

**Hardware:** NVMe1 256GB (EFI + root) + NVMe2 1TB (`/home` penuh).
**Yang dibutuhkan:** 1 USB berisi ISO Artix runit + koneksi internet.
Tidak perlu flashdisk kedua — semua file diambil langsung dari GitHub.

---

## 1. Boot & partisi

1. Boot USB live Artix (F8 = boot menu ASUS).
2. Cek internet: `ping -c3 artixlinux.org` (kalau belum: `dhcpcd`).
3. Identifikasi disk — **jangan asumsi dari nama**, cocokkan ukuran:
   ```
   lsblk
   ```
   `$NVME1` = yang 256GB, `$NVME2` = yang 1TB.
4. NVMe1 — 2 partisi:
   ```
   cfdisk /dev/$NVME1
   ```
   `gpt` → p1 **500M EFI System** → p2 **sisa, Linux filesystem** →
   `Write` → `yes` → `Quit`.
5. NVMe2 — 1 partisi penuh:
   ```
   cfdisk /dev/$NVME2
   ```
   `gpt` → 1 partisi penuh **Linux filesystem** → `Write` → `yes` → `Quit`.
6. Format & mount (semua, termasuk `/home`):
   ```
   mkfs.vfat -F 32 /dev/${NVME1}p1
   mkfs.ext4 /dev/${NVME1}p2
   mkfs.ext4 /dev/${NVME2}p1

   mount /dev/${NVME1}p2 /mnt
   mkdir -p /mnt/boot/efi /mnt/home
   mount /dev/${NVME1}p1 /mnt/boot/efi
   mount /dev/${NVME2}p1 /mnt/home
   ```

## 2. Basestrap

```
basestrap /mnt base base-devel linux linux-firmware runit elogind-runit linux-headers neovim git
fstabgen -U /mnt >> /mnt/etc/fstab
```

## 3. Chroot, clone repo, jalankan bootstrap

```
artix-chroot /mnt
git clone https://github.com/d3vzero/dotfiles-sway.noctalia /opt/dotfiles
bash /opt/dotfiles/bootstrap/install-chroot.sh
```
Isi password root lalu `DrDDrake` saat diminta. Setelah selesai:
```
exit
umount -R /mnt
reboot
```
Cabut USB live saat restart.

> Clone via HTTPS tanpa login hanya bisa kalau repo **public**. Kalau
> repo private, pakai Personal Access Token sebagai password saat
> diminta.

## 4. Login pertama (tty1, masih mode teks)

Login `DrDDrake`. Karena config Sway belum ada, kamu mendarat di shell
biasa — ini normal. Jalankan:
```
cd ~/dotfiles-sway.noctalia
./install.sh daily work ai
```
Isi password sudo saat diminta, tekan Enter di setiap prompt `[Y/n]`.
Setelah selesai:
```
sudo rm -rf /opt/dotfiles
logout
```
Login lagi di tty1 → **Sway start otomatis**.

> Profil bisa dipilih sesuai kebutuhan: `daily` (Steam, OBS, DaVinci),
> `work` (OnlyOffice, FreeCAD, KiCad), `ai` (CUDA, llama.cpp).

## 5. Langkah manual (GUI / butuh akun)

- **Firefox tmpfs** — buka Firefox sekali, tutup total
  (`pgrep firefox` kosong), lalu jalankan sekali:
  `~/.local/bin/firefox-tmpfs-setup.sh`
- **Plugin MPD Tools** — Settings Noctalia → Plugins → pastikan source
  `d3vzero` ada → Browse → **MPD Tools** → Enable. Kalau widget belum
  muncul di bar: Bar → Add Widget → `mpd_output`, `mpd_shuffle`,
  `mpd_category_album`, `mpd_category_single`, `mpd_category_cover`.
- **SSH key GitHub** (supaya bisa push dari mesin ini):
  ```
  ssh-keygen -t ed25519 -C "DracoAtom-PC" -f ~/.ssh/id_ed25519
  cat ~/.ssh/id_ed25519.pub     # paste ke GitHub -> Settings -> SSH keys
  cd ~/dotfiles-sway.noctalia
  git remote set-url origin git@github.com:d3vzero/dotfiles-sway.noctalia.git
  ```
- **SFTP dari HP (X-plore)** — `ip -4 -brief addr` untuk IP, lalu di
  X-plore: Add storage → FTP/SFTP → IP, port 22, user `DrDDrake`.

**Profil daily**
- **Steam** — login saja. Library default (`~/.local/share/Steam`)
  sudah di NVMe `/home`; **jangan** Add Drive ke folder lain di
  partisi yang sama (bikin entri dobel tanpa manfaat).
- **Proton-GE** — `profiles/daily/scripts/install-proton-ge.sh`, restart
  Steam, lalu per game: Properties → Compatibility → pilih GE-Proton.
- **OBS** — source **Screen Capture (PipeWire)** → Open Selector →
  pilih monitor. Multi-track: Desktop → Track 1+2, Mic → Track 1+3.
- **DaVinci Resolve** — download `.zip` Linux dari situs Blackmagic
  (butuh akun), taruh apa adanya di `profiles/daily/files/davinci/`,
  lalu `./install.sh daily`. File `.zip` tidak ikut git (`.gitignore`).

**Profil ai**
- Buka terminal baru dulu (biar `nvcc` dari CUDA masuk `PATH`), lalu
  `profiles/ai/scripts/build-llamacpp.sh`.
- Download model GGUF manual ke `~/models/`, jalankan tanpa `-ngl`
  (auto-fit) dan dengan `--cache-type-k q8_0 --cache-type-v q8_0`.

## 6. Update di kemudian hari

```
cd ~/dotfiles-sway.noctalia
git pull
./install.sh daily work ai
swaymsg reload
```
Setting Noctalia yang diubah lewat GUI **tidak** otomatis masuk repo
(file-nya di-copy, bukan symlink). Simpan manual:
```
cp ~/.local/state/noctalia/settings.toml core/noctalia-state/
git add -A && git commit -m "noctalia: update settings" && git push
```

## Checklist

- [ ] `Mod+Return` / `Mod+F` / `Mod+D` / `Mod+W` / `Mod+S` / `Mod+Escape` / `Mod+L`
- [ ] `Mod+E` buka Omafiles
- [ ] 5 widget MPD Tools muncul & bisa di-toggle
- [ ] `zathura` buka PDF (tidak blank)
- [ ] SFTP dari X-plore
- [ ] (daily) Steam login, Storage cuma 1 entri `/home`
- [ ] (daily) OBS Open Selector memunculkan dialog fuzzel
- [ ] (ai) `llama-server` jalan tanpa OOM
