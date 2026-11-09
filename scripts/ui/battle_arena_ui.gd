# =============================================================================
# scripts/ui/battle_arena_ui.gd
# Logika utama Battle Arena — sistem turn-based 1v1.
#
# CHANGELOG (Iterasi 3):
#   [NEW FITUR 1] Bounded RNG damage formula + mekanik Miss
#   [NEW FITUR 2] Temporary Shield menggantikan defense pasif
#   [NEW FITUR 3] Enemy Intent System — musuh deklarasi aksi sebelum pemain
#   [NEW FITUR 4] Stat scaling terintegrasi via PlayerData
#   [NEW FITUR 5] Passive buff: Vampiric Strike, Retaliation, Second Wind
# =============================================================================
extends Control

# --- Referensi Node lama -----------------------------------------------------
@onready var stage_label:      Label     = $MarginContainer/BattleContainer/StageLabel
@onready var enemy_name_label: Label     = $MarginContainer/BattleContainer/EnemySection/EnemyNameLabel
@onready var enemy_sprite:     ColorRect = $MarginContainer/BattleContainer/EnemySection/EnemySprite
@onready var enemy_hp_label:   Label     = $MarginContainer/BattleContainer/EnemySection/EnemyHPLabel
@onready var battle_log:       Label     = $MarginContainer/BattleContainer/BattleLog
@onready var player_sprite:    ColorRect = $MarginContainer/BattleContainer/PlayerSection/PlayerSprite
@onready var player_hp_label:  Label     = $MarginContainer/BattleContainer/PlayerSection/PlayerHPLabel
@onready var attack_btn:       Button    = $MarginContainer/BattleContainer/ActionButtons/AttackButton
@onready var defend_btn:       Button    = $MarginContainer/BattleContainer/ActionButtons/DefendButton
@onready var heal_btn:         Button    = $MarginContainer/BattleContainer/ActionButtons/HealButton
@onready var enemy_turn_timer: Timer     = $EnemyTurnTimer

# --- [NEW FITUR 3] IntentLabel — Deklarasi aksi musuh sebelum pemain memilih
@onready var intent_label:     Label     = $MarginContainer/BattleContainer/EnemySection/IntentLabel

# --- Referensi Node Opening & Encounter (dari iterasi sebelumnya) ------------
@onready var opening_panel:    Panel     = $OpeningPanel
@onready var opening_continue: Button    = $OpeningPanel/CenterContainer/VBoxContainer/ContinueButton
@onready var encounter_label:  Label     = $EncounterLabel

# --- State lokal pertempuran -------------------------------------------------
var enemy_max_hp:     int = 0
var enemy_current_hp: int = 0

# [NEW FITUR 3] Menyimpan damage yang sudah dideklarasikan musuh di awal giliran
var enemy_declared_dmg: int = 0

# =============================================================================
# INISIALISASI
# =============================================================================
func _ready() -> void:
	_load_enemy_data()
	_update_ui()

	attack_btn.pressed.connect(_on_attack_pressed)
	defend_btn.pressed.connect(_on_defend_pressed)
	heal_btn.pressed.connect(_on_heal_pressed)
	enemy_turn_timer.timeout.connect(_execute_enemy_turn)

	if PlayerData.current_stage == 0:
		_show_opening_panel()
	else:
		_start_player_turn()

func _load_enemy_data() -> void:
	var idx:  int        = PlayerData.current_stage
	var data: Dictionary = PlayerData.ENEMY_DATA[idx]

	enemy_name_label.text = data["name"]
	enemy_sprite.color    = data["color"]
	enemy_max_hp          = data["hp"]
	enemy_current_hp      = data["hp"]

	stage_label.text    = "Stage %d / %d" % [idx + 1, PlayerData.ENEMY_DATA.size()]
	player_sprite.color = Color(0.25, 0.45, 0.85, 1.0)

func _update_ui() -> void:
	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]
	enemy_hp_label.text  = "%s  HP: %d / %d" % [edata["name"], enemy_current_hp, enemy_max_hp]

	# [NEW FITUR 2] Tampilkan shield di label HP pemain jika aktif
	if PlayerData.current_shield > 0:
		player_hp_label.text = "Hero  HP: %d / %d  🛡 %d" % [
			PlayerData.current_hp, PlayerData.max_hp, PlayerData.current_shield
		]
	else:
		player_hp_label.text = "Hero  HP: %d / %d" % [PlayerData.current_hp, PlayerData.max_hp]

func _set_buttons_disabled(disabled: bool) -> void:
	attack_btn.disabled = disabled
	defend_btn.disabled = disabled
	heal_btn.disabled   = disabled

# =============================================================================
# [NEW FITUR 3] ENEMY INTENT — Musuh mendeklarasikan aksi di awal giliran
# =============================================================================

func _start_player_turn() -> void:
	# [NEW FITUR 2] Reset shield pemain di awal gilirannya
	PlayerData.current_shield = 0
	_update_ui()

	# [NEW FITUR 3] Hitung dan tampilkan intent musuh SEBELUM pemain memilih
	_declare_enemy_intent()
	_set_buttons_disabled(false)
	_show_encounter_text()

func _declare_enemy_intent() -> void:
	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]
	# [NEW FITUR 1 & 3] Hitung damage yang akan dilakukan musuh menggunakan rumus baru
	# [ASUMSI] Defense pemain ikut diperhitungkan saat menentukan intent
	enemy_declared_dmg = PlayerData.calculate_damage(
		int(edata["attack"]),
		PlayerData.defense_value
	)

	# [NEW FITUR 3] Tampilkan intent di IntentLabel
	if enemy_declared_dmg <= 0:
		intent_label.text = "⚡ %s akan menyerang: MISS?" % edata["name"]
	else:
		intent_label.text = "⚠️ %s akan menyerang: %d DMG" % [edata["name"], enemy_declared_dmg]
	intent_label.visible = true

# =============================================================================
# GILIRAN PEMAIN
# =============================================================================

func _on_attack_pressed() -> void:
	_set_buttons_disabled(true)
	intent_label.visible = false   # Sembunyikan intent saat aksi dimulai

	# [NEW FITUR 1] Hitung damage pemain dengan rumus bounded RNG
	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]
	var dmg: int = PlayerData.calculate_damage(
		PlayerData.attack_damage,
		int(edata["defense"])
	)

	if dmg <= 0:
		# [NEW FITUR 1] Mekanik Miss — HP musuh TIDAK dikurangi
		battle_log.text = "⚡  Kamu menyerang... MISS! Serangan meleset!"
	else:
		enemy_current_hp = max(0, enemy_current_hp - dmg)
		battle_log.text = "⚔️  Kamu menyerang %s untuk %d damage!" % [edata["name"], dmg]

		# [NEW FITUR 5] Vampiric Strike: heal 25% dari damage yang diberikan
		if PlayerData.buff_vampiric:
			var heal_amount: int = max(1, int(dmg * 0.25))
			PlayerData.current_hp = min(PlayerData.current_hp + heal_amount, PlayerData.max_hp)
			battle_log.text += "\n🩸 Vampiric! +%d HP" % heal_amount

	_update_ui()

	if enemy_current_hp <= 0:
		_handle_enemy_death()
	else:
		enemy_turn_timer.start(1.2)

func _on_defend_pressed() -> void:
	_set_buttons_disabled(true)
	intent_label.visible = false

	# [NEW FITUR 2] Berikan Temporary Shield — menggantikan defense pasif
	# [ASUMSI] Nilai shield = 10. Sesuaikan jika perlu.
	const SHIELD_AMOUNT: int = 10
	PlayerData.current_shield = SHIELD_AMOUNT
	battle_log.text = "🛡️  Kamu memasang perisai! Shield: %d" % SHIELD_AMOUNT
	_update_ui()
	enemy_turn_timer.start(1.2)

func _on_heal_pressed() -> void:
	_set_buttons_disabled(true)
	intent_label.visible = false

	# [ASUMSI] Heal = 15 HP per aksi (disesuaikan dengan stat scaling baru)
	const HEAL_AMOUNT: int = 15
	var healed: int = min(HEAL_AMOUNT, PlayerData.max_hp - PlayerData.current_hp)
	PlayerData.current_hp += healed
	battle_log.text = "💚  Kamu memulihkan %d HP!" % healed
	_update_ui()
	enemy_turn_timer.start(1.2)

# =============================================================================
# [NEW FITUR 3] GILIRAN MUSUH — Eksekusi damage yang sudah dideklarasikan
# =============================================================================

func _execute_enemy_turn() -> void:
	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]
	# [NEW FITUR 3] Gunakan damage yang sudah dideklarasikan sebelumnya
	var actual_dmg: int   = enemy_declared_dmg

	if actual_dmg <= 0:
		# [NEW FITUR 1] Miss musuh
		battle_log.text = "⚡  %s menyerang... MISS! Serangan meleset!" % edata["name"]
		_start_player_turn()
		return

	# [NEW FITUR 2] Proses Temporary Shield terlebih dahulu
	var shield_before: int = PlayerData.current_shield
	if PlayerData.current_shield > 0:
		var absorbed: int = min(PlayerData.current_shield, actual_dmg)
		PlayerData.current_shield -= absorbed
		actual_dmg -= absorbed
		battle_log.text = "🛡️  %s menyerang! Shield menyerap %d. " % [edata["name"], absorbed]

		# [NEW FITUR 5] Retaliation: pantul 50% dari total damage ke musuh saat shield aktif
		if PlayerData.buff_retaliation and shield_before > 0:
			var retaliation_dmg: int = max(1, int(enemy_declared_dmg * 0.5))
			enemy_current_hp = max(0, enemy_current_hp - retaliation_dmg)
			battle_log.text += "\n⚡ Retaliation! %s menerima %d damage balik!" % [edata["name"], retaliation_dmg]
			_update_ui()
			if enemy_current_hp <= 0:
				_handle_enemy_death()
				return
	else:
		battle_log.text = "💀  %s menyerang! " % edata["name"]

	# Kurangi HP pemain dengan sisa damage setelah shield
	if actual_dmg > 0:
		PlayerData.current_hp = max(0, PlayerData.current_hp - actual_dmg)
		battle_log.text += "Kamu menerima %d damage!" % actual_dmg
	else:
		battle_log.text += "Shield memblok semua damage!"

	_update_ui()

	# [NEW FITUR 5] Second Wind: bangkit 1x saat HP = 0
	if PlayerData.current_hp <= 0 and PlayerData.buff_second_wind and not PlayerData.second_wind_used:
		PlayerData.second_wind_used = true
		var revive_hp: int = max(1, int(PlayerData.max_hp * 0.30))
		PlayerData.current_hp = revive_hp
		battle_log.text += "\n💨 Second Wind! HP pulih ke %d!" % revive_hp
		_update_ui()
		_start_player_turn()
		return

	if PlayerData.current_hp <= 0:
		_handle_player_death()
	else:
		_start_player_turn()

# =============================================================================
# KONDISI AKHIR PERTEMPURAN
# =============================================================================

func _handle_enemy_death() -> void:
	_set_buttons_disabled(true)
	intent_label.visible = false
	var ename: String = PlayerData.ENEMY_DATA[PlayerData.current_stage]["name"]

	if PlayerData.is_boss_stage():
		battle_log.text = "🏆  %s dikalahkan! Kamu berhasil melarikan diri dari jurang!" % ename
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu/win_screen.tscn")
	else:
		battle_log.text = "✅  %s dikalahkan! Ambil rewardmu!" % ename
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/gameplay/reward_screen.tscn")

func _handle_player_death() -> void:
	_set_buttons_disabled(true)
	battle_log.text = "💔  Kamu telah dikalahkan... GAME OVER."
	await get_tree().create_timer(2.5).timeout
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# =============================================================================
# UI HELPER (Opening & Encounter — dari iterasi sebelumnya)
# =============================================================================

func _show_opening_panel() -> void:
	opening_panel.visible = true
	_set_buttons_disabled(true)
	opening_continue.pressed.connect(_on_opening_continue_pressed)

func _on_opening_continue_pressed() -> void:
	opening_panel.visible = false
	_start_player_turn()

func _show_encounter_text() -> void:
	var enemy_name: String = PlayerData.ENEMY_DATA[PlayerData.current_stage]["name"]
	encounter_label.text     = "Kamu dihadang oleh %s." % enemy_name
	encounter_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	encounter_label.visible  = true
	battle_log.text = "⚠️  Kamu dihadang oleh %s!" % enemy_name

	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(encounter_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	tween.tween_callback(func(): encounter_label.visible = false)
