# =============================================================================
# scripts/globals/player_data.gd
# AUTOLOAD SINGLETON — State pemain antar scene.
#
# CHANGELOG (Iterasi 4):
#   [NEW FITUR 1] 13-stage ENEMY_DATA: 3 Keroco + 1 Boss per tipe + Dragon Final
#   [NEW FITUR 2] Reward tier tracking: last_defeated_was_boss
#   [NEW FITUR 3] Stat scaling Pemain & seluruh musuh sesuai spesifikasi
#   [NEW FITUR 4] Bounded RNG damage formula + helper is_final_boss()
#   [NEW FITUR 5] Dua-tier buff: Normal (hp_up, atk_up, heal_half) + Synergistic
# =============================================================================
extends Node

# -----------------------------------------------------------------------------
# [NEW FITUR 3] Stat dasar pemain: Max HP 50, Atk 10, Def 2
# -----------------------------------------------------------------------------
const BASE_MAX_HP:  int = 50
const BASE_ATTACK:  int = 10
const BASE_DEFENSE: int = 2

var max_hp:         int  = BASE_MAX_HP
var current_hp:     int  = BASE_MAX_HP
var attack_damage:  int  = BASE_ATTACK
var defense_value:  int  = BASE_DEFENSE
var current_shield: int  = 0
var current_stage:  int  = 0

# [NEW FITUR 2] Flag reward tier — di-set oleh BattleArena sebelum ke RewardScreen
var last_defeated_was_boss: bool = false

# [NEW FITUR 5] Passive buff flags
var buff_vampiric:    bool = false
var buff_retaliation: bool = false
var buff_second_wind: bool = false
var second_wind_used: bool = false   # Guard: hanya berlaku 1x per run

# -----------------------------------------------------------------------------
# [NEW FITUR 1] Data 13 stage musuh.
# Urutan: Slime Keroco x3 → Slime Boss → Goblin Keroco x3 → Goblin Boss →
#         Skeleton Keroco x3 → Skeleton Boss → Dragon (Final Boss)
#
# Field: name, hp, attack, defense, color, is_boss
# [NEW FITUR 3] Semua nilai stat sesuai spesifikasi kurva balancing.
# -----------------------------------------------------------------------------
const ENEMY_DATA: Array[Dictionary] = [
	# --- Stage 1–3: Slime Keroco (index 0–2) ---
	{
		"name": "Slime Keroco", "hp": 25, "attack": 5, "defense": 0,
		"color": Color(0.30, 0.90, 0.30, 1.0),
		"is_boss": false   # [NEW FITUR 1]
	},
	{
		"name": "Slime Keroco", "hp": 25, "attack": 5, "defense": 0,
		"color": Color(0.30, 0.90, 0.30, 1.0),
		"is_boss": false
	},
	{
		"name": "Slime Keroco", "hp": 25, "attack": 5, "defense": 0,
		"color": Color(0.30, 0.90, 0.30, 1.0),
		"is_boss": false
	},
	# --- Stage 4: Slime Boss (index 3) ---
	{
		"name": "Slime Boss", "hp": 60, "attack": 8, "defense": 1,  # [NEW FITUR 3]
		"color": Color(0.00, 0.55, 0.10, 1.0),
		"is_boss": true    # [NEW FITUR 1]
	},
	# --- Stage 5–7: Goblin Keroco (index 4–6) ---
	{
		"name": "Goblin Keroco", "hp": 40, "attack": 8, "defense": 1,
		"color": Color(0.70, 0.50, 0.10, 1.0),
		"is_boss": false
	},
	{
		"name": "Goblin Keroco", "hp": 40, "attack": 8, "defense": 1,
		"color": Color(0.70, 0.50, 0.10, 1.0),
		"is_boss": false
	},
	{
		"name": "Goblin Keroco", "hp": 40, "attack": 8, "defense": 1,
		"color": Color(0.70, 0.50, 0.10, 1.0),
		"is_boss": false
	},
	# --- Stage 8: Goblin Boss (index 7) ---
	{
		"name": "Goblin Boss", "hp": 90, "attack": 12, "defense": 2,  # [NEW FITUR 3]
		"color": Color(0.45, 0.25, 0.00, 1.0),
		"is_boss": true
	},
	# --- Stage 9–11: Skeleton Keroco (index 8–10) ---
	{
		"name": "Skeleton Keroco", "hp": 60, "attack": 11, "defense": 3,
		"color": Color(0.80, 0.80, 0.80, 1.0),
		"is_boss": false
	},
	{
		"name": "Skeleton Keroco", "hp": 60, "attack": 11, "defense": 3,
		"color": Color(0.80, 0.80, 0.80, 1.0),
		"is_boss": false
	},
	{
		"name": "Skeleton Keroco", "hp": 60, "attack": 11, "defense": 3,
		"color": Color(0.80, 0.80, 0.80, 1.0),
		"is_boss": false
	},
	# --- Stage 12: Skeleton Boss (index 11) ---
	{
		"name": "Skeleton Boss", "hp": 130, "attack": 15, "defense": 4,  # [NEW FITUR 3]
		"color": Color(1.00, 1.00, 1.00, 1.0),
		"is_boss": true
	},
	# --- Stage 13: Dragon — Final Boss (index 12) ---
	{
		"name": "Dragon", "hp": 250, "attack": 20, "defense": 5,  # [NEW FITUR 3]
		"color": Color(0.80, 0.10, 0.10, 1.0),
		"is_boss": true
	},
]

# -----------------------------------------------------------------------------
# Reset seluruh state pemain ke kondisi awal
# -----------------------------------------------------------------------------
func reset_player() -> void:
	max_hp               = BASE_MAX_HP
	current_hp           = BASE_MAX_HP
	attack_damage        = BASE_ATTACK
	defense_value        = BASE_DEFENSE
	current_shield       = 0
	current_stage        = 0
	last_defeated_was_boss = false
	buff_vampiric        = false
	buff_retaliation     = false
	buff_second_wind     = false
	second_wind_used     = false

# -----------------------------------------------------------------------------
# [NEW FITUR 4] Rumus damage bounded RNG dengan pertimbangan Defense.
# Damage = int(max(0, Attack - Defense/2.0) * randf_range(0.85, 1.15))
# Hasil selalu >= 0.
# -----------------------------------------------------------------------------
func calculate_damage(attacker_atk: int, target_def: int) -> int:
	var base: float = float(attacker_atk) - (float(target_def) / 2.0)
	base = max(0.0, base)
	var result: int = int(base * randf_range(0.85, 1.15))
	return max(0, result)

# -----------------------------------------------------------------------------
# [NEW FITUR 5] Terapkan buff dari dua tier berbeda:
#   Normal: "hp_up", "atk_up", "heal_half"
#   Synergistic: "vampiric", "retaliation", "second_wind"
# -----------------------------------------------------------------------------
func apply_buff(buff_type: String) -> void:
	match buff_type:
		# [NEW FITUR 5] Normal buffs (dari Keroco)
		"hp_up":
			max_hp    += 10
			# Pastikan current_hp tidak melebihi max_hp baru
			current_hp = min(current_hp, max_hp)
		"atk_up":
			attack_damage += 2
		"heal_half":
			var restore: int = int(max_hp * 0.5)
			current_hp = min(current_hp + restore, max_hp)
		# [NEW FITUR 5] Synergistic buffs (dari Boss)
		"vampiric":
			buff_vampiric = true
		"retaliation":
			buff_retaliation = true
		"second_wind":
			buff_second_wind = true
		_:
			push_warning("PlayerData.apply_buff(): Unknown buff type '%s'" % buff_type)

# -----------------------------------------------------------------------------
# [NEW FITUR 1 & 4] Helper — cek jenis musuh di stage saat ini
# -----------------------------------------------------------------------------

## True jika stage saat ini adalah Dragon (stage terakhir dari 13)
func is_final_boss() -> bool:
	return current_stage >= ENEMY_DATA.size() - 1

## True jika musuh di stage saat ini bertipe Boss (is_boss = true)
func is_current_enemy_boss() -> bool:
	if current_stage >= ENEMY_DATA.size():
		return false
	return bool(ENEMY_DATA[current_stage]["is_boss"])
