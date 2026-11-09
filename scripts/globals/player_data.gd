# =============================================================================
# scripts/globals/player_data.gd
# AUTOLOAD SINGLETON — State pemain antar scene.
#
# CHANGELOG (Iterasi 3):
#   [NEW FITUR 4] Stat scaling — nilai HP/Atk/Def direvisi ke angka seimbang
#   [NEW FITUR 2] Tambah variabel current_shield & defense_value
#   [NEW FITUR 5] Tambah variabel flag passive buff (vampiric, retaliation, second_wind)
# =============================================================================
extends Node

# -----------------------------------------------------------------------------
# [NEW FITUR 4] Stat dasar pemain — disesuaikan untuk kurva balancing baru.
# Pemain: Max HP 50, Atk 10, Def 2
# -----------------------------------------------------------------------------
const BASE_MAX_HP:    int = 50
const BASE_ATTACK:    int = 10
const BASE_DEFENSE:   int = 2   # [NEW FITUR 4] Defense mengurangi damage masuk

var max_hp:         int  = BASE_MAX_HP
var current_hp:     int  = BASE_MAX_HP
var attack_damage:  int  = BASE_ATTACK
var defense_value:  int  = BASE_DEFENSE  # [NEW FITUR 2 & 4] Stat defense permanen
var current_shield: int  = 0             # [NEW FITUR 2] Shield sementara dari aksi Bertahan
var current_stage:  int  = 0

# [NEW FITUR 5] Flag passive buff — false = belum aktif, true = sudah dipilih
var buff_vampiric:    bool = false  # Vampiric Strike: heal 25% dari damage diberikan
var buff_retaliation: bool = false  # Retaliation: pantul 50% dmg saat shield aktif
var buff_second_wind: bool = false  # Second Wind: bangkit 1x saat HP = 0
var second_wind_used: bool = false  # [NEW FITUR 5] Guard — hanya berlaku 1x per run

# -----------------------------------------------------------------------------
# [NEW FITUR 4] Data musuh — stat disesuaikan kurva balancing baru.
# Format: name, hp, attack, defense, color
# -----------------------------------------------------------------------------
const ENEMY_DATA: Array[Dictionary] = [
	{
		"name":    "Slime",
		"hp":      30,    # [NEW FITUR 4]
		"attack":  6,     # [NEW FITUR 4]
		"defense": 0,     # [NEW FITUR 4]
		"color":   Color(0.20, 0.80, 0.20, 1.0)
	},
	{
		"name":    "Goblin",
		"hp":      45,    # [NEW FITUR 4]
		"attack":  9,     # [NEW FITUR 4]
		"defense": 1,     # [NEW FITUR 4]
		"color":   Color(0.60, 0.40, 0.10, 1.0)
	},
	{
		"name":    "Skeleton",
		"hp":      70,    # [NEW FITUR 4]
		"attack":  12,    # [NEW FITUR 4]
		"defense": 3,     # [NEW FITUR 4]
		"color":   Color(0.85, 0.85, 0.85, 1.0)
	},
	{
		"name":    "Dragon",
		"hp":      120,   # [NEW FITUR 4]
		"attack":  15,    # [NEW FITUR 4]
		"defense": 4,     # [NEW FITUR 4]
		"color":   Color(0.80, 0.10, 0.10, 1.0)
	},
]

# -----------------------------------------------------------------------------
# Reset seluruh state pemain ke kondisi awal
# -----------------------------------------------------------------------------
func reset_player() -> void:
	max_hp          = BASE_MAX_HP
	current_hp      = BASE_MAX_HP
	attack_damage   = BASE_ATTACK
	defense_value   = BASE_DEFENSE
	current_shield  = 0
	current_stage   = 0
	buff_vampiric    = false
	buff_retaliation = false
	buff_second_wind = false
	second_wind_used = false

# -----------------------------------------------------------------------------
# [NEW FITUR 1] Rumus damage bounded RNG dengan pertimbangan Defense.
# Damage = int((Attack - Defense/2.0) * randf_range(0.85, 1.15))
# Hasil selalu >= 0.
# -----------------------------------------------------------------------------
static func calculate_damage(attacker_atk: int, target_def: int) -> int:
	var base: float = attacker_atk - (target_def / 2.0)
	# Pastikan base tidak negatif sebelum dikalikan RNG
	base = max(0.0, base)
	var result: int = int(base * randf_range(0.85, 1.15))
	return max(0, result)

# -----------------------------------------------------------------------------
# [NEW FITUR 5] Terapkan passive buff roguelike
# -----------------------------------------------------------------------------
func apply_buff(buff_type: String) -> void:
	match buff_type:
		"vampiric":
			buff_vampiric = true       # [NEW FITUR 5]
		"retaliation":
			buff_retaliation = true    # [NEW FITUR 5]
		"second_wind":
			buff_second_wind = true    # [NEW FITUR 5]
		_:
			push_warning("PlayerData.apply_buff(): Unknown buff type '%s'" % buff_type)

# -----------------------------------------------------------------------------
# Helper — true jika stage sekarang adalah stage Boss (stage terakhir)
# -----------------------------------------------------------------------------
func is_boss_stage() -> bool:
	return current_stage >= ENEMY_DATA.size() - 1
