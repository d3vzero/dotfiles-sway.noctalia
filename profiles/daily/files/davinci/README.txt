Taruh file installer DaVinci Resolve for Linux (.zip) di folder ini,
persis nama file aslinya dari Blackmagic (contoh:
DaVinci_Resolve_20.3.1_Linux.zip) — TIDAK di-rename.

install-daily.sh otomatis DETEKSI file ini (glob "DaVinci_Resolve_*_Linux.zip")
dan build+install lewat AUR kalau ada. Kalau folder ini kosong,
install-daily.sh cuma skip step DaVinci dengan pesan info, tidak error.
