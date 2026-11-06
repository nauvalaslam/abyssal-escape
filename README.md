# Abyssal Escape

> Turn-based roguelike dungeon escape — Godot Engine 4.7

## Cara Menjalankan
1. Buka Godot 4.7 → **Import** → pilih folder `abyssal-escape/`
2. Pastikan `project.godot` terbaca
3. Tekan **F5** atau klik tombol ▶ untuk menjalankan game

## Struktur Proyek
```
abyssal-escape/
├── project.godot
├── icon.svg
├── scenes/
│   ├── main_menu/      ← main_menu.tscn, credits.tscn, win_screen.tscn
│   └── gameplay/       ← battle_arena.tscn, reward_screen.tscn
├── scripts/
│   ├── globals/        ← player_data.gd  (Autoload Singleton)
│   └── ui/             ← 1 script per scene
└── assets/             ← folder siap untuk aset final
```

## Alur Game
```
Main Menu → Battle Arena (Slime)
		 → Reward Screen → Battle Arena (Goblin)
		 → Reward Screen → Battle Arena (Skeleton)
		 → Reward Screen → Battle Arena (Dragon)
		 → WIN SCREEN ✓
```

## Tim
| Peran | Nama | NIM |
|---|---|---|
| Ketua | Nauval Rusdi Aslam | 235150207111030 |
| Anggota | Ahmad Muzaki Ulumuddin | 235150207111040 |
| Anggota | Bimaelsa Wahyu Kurnia | 215150207111015 |

## Konvensi Git
- Branch per fitur: `feat/nama-fitur`
- 1 scene = 1 file `.tscn` (hindari merge conflict)
- Semua asumsi gameplay ditandai `# [ASUMSI]` di script
