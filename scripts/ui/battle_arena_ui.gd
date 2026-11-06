# =============================================================================
# scripts/ui/battle_arena_ui.gd
# Logika utama Battle Arena — sistem turn-based 1v1.
#
# ALUR:
#   Giliran Pemain → pilih Serang / Bertahan / Heal
#   → EnemyTurnTimer (1.5 detik) → Giliran Musuh otomatis
#   → Cek kondisi menang/kalah → pindah scene
#
# Dipasang pada node root scene res://scenes/gameplay/battle_arena.tscn
# =============================================================================
extends Control

# --- Referensi Node (path harus sesuai struktur di battle_arena.tscn) --------
@onready var stage_label:      Label  = $MarginContainer/BattleContainer/StageLabel
@onready var enemy_name_label: Label  = $MarginContainer/BattleContainer/EnemySection/EnemyNameLabel
@onready var enemy_sprite:     ColorRect = $MarginContainer/BattleContainer/EnemySection/EnemySprite
@onready var enemy_hp_label:   Label  = $MarginContainer/BattleContainer/EnemySection/EnemyHPLabel
@onready var battle_log:       Label  = $MarginContainer/BattleContainer/BattleLog
@onready var player_sprite:    ColorRect = $MarginContainer/BattleContainer/PlayerSection/PlayerSprite
@onready var player_hp_label:  Label  = $MarginContainer/BattleContainer/PlayerSection/PlayerHPLabel
@onready var attack_btn:       Button = $MarginContainer/BattleContainer/ActionButtons/AttackButton
@onready var defend_btn:       Button = $MarginContainer/BattleContainer/ActionButtons/DefendButton
@onready var heal_btn:         Button = $MarginContainer/BattleContainer/ActionButtons/HealButton
@onready var enemy_turn_timer: Timer  = $EnemyTurnTimer

# --- State lokal pertempuran --------------------------------------------------
var enemy_max_hp:     int = 0
var enemy_current_hp: int = 0

# =============================================================================
# INISIALISASI
# =============================================================================
func _ready() -> void:
	_load_enemy_data()
	_update_ui()
	_set_buttons_disabled(false)

	attack_btn.pressed.connect(_on_attack_pressed)
	defend_btn.pressed.connect(_on_defend_pressed)
	heal_btn.pressed.connect(_on_heal_pressed)
	enemy_turn_timer.timeout.connect(_execute_enemy_turn)

func _load_enemy_data() -> void:
	var idx:  int        = PlayerData.current_stage
	var data: Dictionary = PlayerData.ENEMY_DATA[idx]

	enemy_name_label.text = data["name"]
	enemy_sprite.color    = data["color"]
	enemy_max_hp          = data["hp"]
	enemy_current_hp      = data["hp"]

	stage_label.text   = "Stage %d / %d" % [idx + 1, PlayerData.ENEMY_DATA.size()]
	player_sprite.color = Color(0.25, 0.45, 0.85, 1.0)   # warna placeholder hero

func _update_ui() -> void:
	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]
	enemy_hp_label.text  = "%s  HP: %d / %d" % [edata["name"], enemy_current_hp, enemy_max_hp]
	player_hp_label.text = "Hero  HP: %d / %d" % [PlayerData.current_hp, PlayerData.max_hp]

func _set_buttons_disabled(disabled: bool) -> void:
	attack_btn.disabled = disabled
	defend_btn.disabled = disabled
	heal_btn.disabled   = disabled

# =============================================================================
# GILIRAN PEMAIN
# =============================================================================

func _on_attack_pressed() -> void:
	_set_buttons_disabled(true)
	# [ASUMSI] Damage pemain = attack_damage tanpa variasi acak (deterministik).
	# Untuk menambahkan RNG, ganti baris berikut dengan range acak.
	var dmg: int = PlayerData.attack_damage

	enemy_current_hp = max(0, enemy_current_hp - dmg)
	battle_log.text = "⚔️  Kamu menyerang %s untuk %d damage!" % [
		PlayerData.ENEMY_DATA[PlayerData.current_stage]["name"], dmg
	]
	_update_ui()

	if enemy_current_hp <= 0:
		_handle_enemy_death()
	else:
		enemy_turn_timer.start(1.5)

func _on_defend_pressed() -> void:
	_set_buttons_disabled(true)
	PlayerData.defense_active = true
	battle_log.text = "🛡️  Kamu bersiap bertahan. Damage musuh akan berkurang 50%!"
	_update_ui()
	enemy_turn_timer.start(1.5)

func _on_heal_pressed() -> void:
	_set_buttons_disabled(true)
	# [ASUMSI] Jumlah HP yang dipulihkan saat aksi Heal = 20.
	# Ganti konstanta HEAL_AMOUNT untuk menyesuaikan keseimbangan.
	const HEAL_AMOUNT: int = 20
	var healed: int = min(HEAL_AMOUNT, PlayerData.max_hp - PlayerData.current_hp)
	PlayerData.current_hp += healed
	battle_log.text = "💚  Kamu memulihkan %d HP!" % healed
	_update_ui()
	enemy_turn_timer.start(1.5)

# =============================================================================
# GILIRAN MUSUH (dipanggil otomatis oleh EnemyTurnTimer)
# =============================================================================

func _execute_enemy_turn() -> void:
	var data:       Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]
	# [ASUMSI] Damage musuh = nilai "attack" di ENEMY_DATA, tanpa variasi acak.
	var raw_dmg:    int = data["attack"]
	var actual_dmg: int = raw_dmg

	if PlayerData.defense_active:
		# [ASUMSI] Bertahan mengurangi damage sebesar 50% (integer division).
		actual_dmg = raw_dmg / 2
		PlayerData.defense_active = false
		battle_log.text = (
			"🛡️  %s menyerang! Bertahan! Kamu menerima %d damage (dari %d)."
			% [data["name"], actual_dmg, raw_dmg]
		)
	else:
		battle_log.text = "💀  %s menyerang! Kamu menerima %d damage!" % [data["name"], actual_dmg]

	PlayerData.current_hp = max(0, PlayerData.current_hp - actual_dmg)
	_update_ui()

	if PlayerData.current_hp <= 0:
		_handle_player_death()
	else:
		_set_buttons_disabled(false)

# =============================================================================
# KONDISI AKHIR PERTEMPURAN
# =============================================================================

func _handle_enemy_death() -> void:
	_set_buttons_disabled(true)
	var ename: String = PlayerData.ENEMY_DATA[PlayerData.current_stage]["name"]

	if PlayerData.is_boss_stage():
		# Dragon (boss terakhir) mati → menuju Win Screen
		battle_log.text = "🏆  %s dikalahkan! Kamu berhasil melarikan diri dari jurang!" % ename
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu/win_screen.tscn")
	else:
		# Musuh biasa mati → menuju Reward Screen roguelike
		battle_log.text = "✅  %s dikalahkan! Ambil rewardmu!" % ename
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/gameplay/reward_screen.tscn")

func _handle_player_death() -> void:
	_set_buttons_disabled(true)
	battle_log.text = "💔  Kamu telah dikalahkan... GAME OVER."
	await get_tree().create_timer(2.5).timeout
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
