# =============================================================================
# scripts/globals/player_data.gd
# AUTOLOAD SINGLETON — Menyimpan & mengelola seluruh state pemain antar scene.
# Didaftarkan sebagai Autoload dengan nama "PlayerData" di Project Settings.
# =============================================================================
extends Node

# -----------------------------------------------------------------------------
# [ASUMSI] Stat dasar pemain saat game dimulai.
# Sesuaikan nilai berikut setelah playtesting untuk menyeimbangkan gameplay.
# -----------------------------------------------------------------------------
const BASE_MAX_HP:      int = 100
const BASE_ATTACK:      int = 25

var max_hp:          int = BASE_MAX_HP
var current_hp:      int = BASE_MAX_HP
var attack_damage:   int = BASE_ATTACK
var defense_active:  bool = false   # Aktif hanya selama 1 giliran musuh
var current_stage:   int = 0        # 0 = Slime … 3 = Dragon

# -----------------------------------------------------------------------------
# [ASUMSI] Data seluruh musuh per stage.
# Tambah musuh baru cukup dengan menambah Dictionary di array ini;
# tidak perlu mengubah logika di scene lain.
# -----------------------------------------------------------------------------
const ENEMY_DATA: Array[Dictionary] = [
	{
		"name":   "Slime",
		# [ASUMSI] HP Slime = 50
		"hp":     50,
		# [ASUMSI] Attack Slime = 10
		"attack": 10,
		"color":  Color(0.20, 0.80, 0.20, 1.0)
	},
	{
		"name":   "Goblin",
		# [ASUMSI] HP Goblin = 80
		"hp":     80,
		# [ASUMSI] Attack Goblin = 18
		"attack": 18,
		"color":  Color(0.60, 0.40, 0.10, 1.0)
	},
	{
		"name":   "Skeleton",
		# [ASUMSI] HP Skeleton = 110
		"hp":     110,
		# [ASUMSI] Attack Skeleton = 25
		"attack": 25,
		"color":  Color(0.85, 0.85, 0.85, 1.0)
	},
	{
		"name":   "Dragon",
		# [ASUMSI] HP Dragon (Boss) = 200
		"hp":     200,
		# [ASUMSI] Attack Dragon = 40
		"attack": 40,
		"color":  Color(0.80, 0.10, 0.10, 1.0)
	},
]

# -----------------------------------------------------------------------------
# Mereset semua stat ke nilai awal (dipanggil saat Game Over atau Main Menu)
# -----------------------------------------------------------------------------
func reset_player() -> void:
	max_hp         = BASE_MAX_HP
	current_hp     = BASE_MAX_HP
	attack_damage  = BASE_ATTACK
	defense_active = false
	current_stage  = 0

# -----------------------------------------------------------------------------
# Menerapkan buff roguelike yang dipilih di Reward Screen
# -----------------------------------------------------------------------------
func apply_buff(buff_type: String) -> void:
	match buff_type:
		"hp_up":
			# [ASUMSI] Buff HP: +30 Max HP dan pulihkan 30 HP
			max_hp    += 30
			current_hp = min(current_hp + 30, max_hp)
		"dmg_up":
			# [ASUMSI] Buff Damage: +10 attack damage
			attack_damage += 10
		"heal_full":
			current_hp = max_hp
		_:
			push_warning("PlayerData.apply_buff(): Unknown buff type '%s'" % buff_type)

# -----------------------------------------------------------------------------
# Helper — true jika stage sekarang adalah stage Boss (stage terakhir)
# -----------------------------------------------------------------------------
func is_boss_stage() -> bool:
	return current_stage >= ENEMY_DATA.size() - 1
