# =============================================================================
# scripts/ui/battle_arena_ui.gd
# Logika utama Battle Arena — sistem turn-based 1v1.
#
# CHANGELOG (Iterasi 4 — FINAL):
#   [NEW FITUR 1] Sistem progresi 13 stage via PlayerData.ENEMY_DATA
#   [NEW FITUR 2] Set PlayerData.last_defeated_was_boss sebelum ke RewardScreen
#   [NEW FITUR 3] Enemy Intent System — musuh deklarasi aksi sebelum pemain
#   [NEW FITUR 4] Bounded RNG damage + enemy miss bias 35% flat
#   [NEW FITUR 5] Passive buff: Vampiric Strike, Retaliation, Second Wind
#   [NEW FITUR 5] Temporary Shield menggantikan defense pasif
#   [BG] Background dinamis berdasarkan kelompok stage musuh
# =============================================================================
extends Control

# --- Referensi Node ----------------------------------------------------------
@onready var stage_label:      Label       = $MarginContainer/BattleContainer/StageLabel
@onready var enemy_name_label: Label       = $MarginContainer/BattleContainer/EnemySection/EnemyNameLabel
@onready var enemy_sprite:     ColorRect   = $MarginContainer/BattleContainer/EnemySection/EnemySprite
@onready var enemy_hp_label:   Label       = $MarginContainer/BattleContainer/EnemySection/EnemyHPLabel
@onready var battle_log:       Label       = $MarginContainer/BattleContainer/BattleLog
@onready var player_sprite:    ColorRect   = $MarginContainer/BattleContainer/PlayerSection/PlayerSprite
@onready var player_hp_label:  Label       = $MarginContainer/BattleContainer/PlayerSection/PlayerHPLabel
@onready var attack_btn:       Button      = $MarginContainer/BattleContainer/ActionButtons/AttackButton
@onready var defend_btn:       Button      = $MarginContainer/BattleContainer/ActionButtons/DefendButton
@onready var heal_btn:         Button      = $MarginContainer/BattleContainer/ActionButtons/HealButton
@onready var enemy_turn_timer: Timer       = $EnemyTurnTimer
@onready var background_rect:  TextureRect = $Background

# [NEW FITUR 3] IntentLabel — deklarasi aksi musuh sebelum pemain memilih
@onready var intent_label:     Label       = $MarginContainer/BattleContainer/EnemySection/IntentLabel

# Node Opening & Encounter
@onready var opening_panel:    Panel         = $OpeningPanel
@onready var encounter_label:  Label         = $EncounterLabel

# [OPTION] Tombol Pengaturan & Modal
@onready var settings_button:  TextureButton = $SettingsButton
@onready var options_modal:    Control       = $OptionsModal

# --- [BG] Mapping background per kelompok stage ------------------------------
# Stage 1-4  (index 0-3)  : Slime
# Stage 5-8  (index 4-7)  : Goblin
# Stage 9-12 (index 8-11) : Skeleton
# Stage 13   (index 12)   : Dragon
const STAGE_BG_MAP: Dictionary = {
	0:  "res://assets/backgrounds/slime_area.jpg",
	1:  "res://assets/backgrounds/slime_area.jpg",
	2:  "res://assets/backgrounds/slime_area.jpg",
	3:  "res://assets/backgrounds/slime_area.jpg",
	4:  "res://assets/backgrounds/goblin_area.jpg",
	5:  "res://assets/backgrounds/goblin_area.jpg",
	6:  "res://assets/backgrounds/goblin_area.jpg",
	7:  "res://assets/backgrounds/goblin_area.jpg",
	8:  "res://assets/backgrounds/skeleton_area.jpg",
	9:  "res://assets/backgrounds/skeleton_area.jpg",
	10: "res://assets/backgrounds/skeleton_area.jpg",
	11: "res://assets/backgrounds/skeleton_area.jpg",
	12: "res://assets/backgrounds/dragon_area.jpg",
}

# --- State lokal pertempuran -------------------------------------------------
var enemy_max_hp:     int  = 0
var enemy_current_hp: int  = 0

# [NEW FITUR 3] Menyimpan damage yang sudah dideklarasikan musuh di awal giliran
var enemy_declared_dmg: int = 0

# [NEW FITUR 4] Peluang mutlak musuh untuk miss sebelum kalkulasi damage
# [ASUMSI] 35% flat miss chance khusus serangan musuh
const ENEMY_MISS_CHANCE: float = 0.35

# Flag agar encounter text hanya tampil sekali per stage
var _encounter_shown: bool = false

# =============================================================================
# INISIALISASI
# =============================================================================
func _ready() -> void:
	_load_background()   # [BG] Load background sesuai stage
	_load_enemy_data()
	_update_music()      # [OST] Mainkan musik sesuai tipe musuh
	_update_ui()

	attack_btn.pressed.connect(_on_attack_pressed)
	defend_btn.pressed.connect(_on_defend_pressed)
	heal_btn.pressed.connect(_on_heal_pressed)
	enemy_turn_timer.timeout.connect(_execute_enemy_turn)
	settings_button.pressed.connect(options_modal.open)

	# Hubungkan tombol Continue di OpeningPanel
	var continue_btn: Button = $OpeningPanel/CenterContainer/VBoxContainer/ContinueButton
	continue_btn.pressed.connect(_on_opening_continue_pressed)

	if PlayerData.current_stage == 0:
		_show_opening_panel()
	else:
		_show_encounter_text()
		_start_player_turn()

# [BG] Load texture background berdasarkan stage saat ini
func _load_background() -> void:
	var idx: int = PlayerData.current_stage
	if STAGE_BG_MAP.has(idx):
		var tex: Texture2D = load(STAGE_BG_MAP[idx])
		if tex:
			background_rect.texture = tex
			# Sesuaikan ukuran child Sprite2D jika masih ada di scene
			for child in background_rect.get_children():
				if child is Sprite2D:
					child.texture = tex
					var tw: float = float(tex.get_width())
					var th: float = float(tex.get_height())
					if tw > 0 and th > 0:
						child.position = Vector2(640, 360)
						child.scale = Vector2(1280.0 / tw, 720.0 / th)

# [OST] Mainkan musik berdasarkan stage/musuh
func _update_music() -> void:
	if PlayerData.is_final_boss():
		AudioManager.play_final_boss()
	elif PlayerData.is_current_enemy_boss():
		AudioManager.play_boss()
	else:
		AudioManager.play_battle()

func _load_enemy_data() -> void:
	var idx:  int        = PlayerData.current_stage
	var data: Dictionary = PlayerData.ENEMY_DATA[idx]

	enemy_max_hp     = int(data["hp"])
	enemy_current_hp = int(data["hp"])

	# [NEW FITUR 1] Tampilkan nama musuh + indikator Boss / Keroco
	var is_boss: bool = bool(data["is_boss"])
	if is_boss:
		# [NEW FITUR 1] Warna emas untuk boss
		enemy_name_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1, 1.0))
		enemy_name_label.text = "👑 " + str(data["name"])
		stage_label.text = "Stage %d / %d  👑 BOSS" % [idx + 1, PlayerData.ENEMY_DATA.size()]
	else:
		enemy_name_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		enemy_name_label.text = str(data["name"])
		stage_label.text = "Stage %d / %d" % [idx + 1, PlayerData.ENEMY_DATA.size()]

	enemy_sprite.color  = data["color"]
	player_sprite.color = Color(0.25, 0.45, 0.85, 1.0)

func _update_ui() -> void:
	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]
	enemy_hp_label.text = "%s  HP: %d / %d" % [str(edata["name"]), enemy_current_hp, enemy_max_hp]

	# [NEW FITUR 5] Tampilkan shield di label HP pemain jika aktif
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
# OPENING PANEL (hanya stage 0)
# =============================================================================
func _show_opening_panel() -> void:
	opening_panel.visible = true
	_set_buttons_disabled(true)
	intent_label.visible = false

func _on_opening_continue_pressed() -> void:
	opening_panel.visible = false
	_show_encounter_text()
	_start_player_turn()

# =============================================================================
# [NEW FITUR 3] ENEMY INTENT — Musuh deklarasikan aksi sebelum pemain memilih
# =============================================================================
func _start_player_turn() -> void:
	# [NEW FITUR 5] Reset shield pemain di awal gilirannya
	PlayerData.current_shield = 0
	_update_ui()

	# [NEW FITUR 3] Hitung dan tampilkan intent musuh SEBELUM pemain memilih
	_declare_enemy_intent()
	_set_buttons_disabled(false)

func _declare_enemy_intent() -> void:
	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]

	# [NEW FITUR 4] Hitung preview damage yang akan dilakukan musuh
	enemy_declared_dmg = PlayerData.calculate_damage(int(edata["attack"]), PlayerData.defense_value)

	# [NEW FITUR 3] Tampilkan ke IntentLabel
	if enemy_declared_dmg <= 0:
		intent_label.text = "⚡ %s bersiap menyerang..." % str(edata["name"])
	else:
		intent_label.text = "⚡ %s akan menyerang: %d DMG" % [str(edata["name"]), enemy_declared_dmg]
	intent_label.visible = true

# =============================================================================
# AKSI PEMAIN
# =============================================================================
func _on_attack_pressed() -> void:
	_set_buttons_disabled(true)
	intent_label.visible = false

	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]

	# [NEW FITUR 4] Kalkulasi damage pemain dengan bounded RNG
	var dmg: int = PlayerData.calculate_damage(PlayerData.attack_damage, int(edata["defense"]))

	if dmg <= 0:
		# [NEW FITUR 4] Miss — damage 0 setelah kalkulasi
		battle_log.text = "⚔️  Kamu menyerang... MISS! Serangan meleset!"
	else:
		enemy_current_hp = max(0, enemy_current_hp - dmg)
		battle_log.text  = "⚔️  Kamu menyerang %s! %d damage!" % [str(edata["name"]), dmg]

		# [NEW FITUR 5] Vampiric Strike: heal 25% dari damage yang diberikan
		if PlayerData.buff_vampiric:
			var leech: int = max(1, int(dmg * 0.25))
			PlayerData.current_hp = min(PlayerData.max_hp, PlayerData.current_hp + leech)
			battle_log.text += "\n🧛 Vampiric! Pulih %d HP." % leech

	_update_ui()

	if enemy_current_hp <= 0:
		_handle_enemy_death()
		return

	enemy_turn_timer.start(1.2)

func _on_defend_pressed() -> void:
	_set_buttons_disabled(true)
	intent_label.visible = false

	# [NEW FITUR 5] Temporary Shield = 10
	# [ASUMSI] Nilai shield flat 10 per aksi Bertahan
	PlayerData.current_shield = 10
	battle_log.text = "🛡️  Kamu bersiap! Shield +10 aktif."
	_update_ui()
	enemy_turn_timer.start(1.2)

func _on_heal_pressed() -> void:
	_set_buttons_disabled(true)
	intent_label.visible = false

	# [ASUMSI] Heal = 15 HP per aksi
	const HEAL_AMOUNT: int = 15
	var healed: int = min(HEAL_AMOUNT, PlayerData.max_hp - PlayerData.current_hp)
	PlayerData.current_hp += healed
	battle_log.text = "💊  Kamu memulihkan %d HP!" % healed
	_update_ui()
	enemy_turn_timer.start(1.2)

# =============================================================================
# [NEW FITUR 3 & 4] GILIRAN MUSUH — Eksekusi setelah delay Timer
# =============================================================================
func _execute_enemy_turn() -> void:
	var edata: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]

	# [NEW FITUR 4] Bias probabilitas musuh: 35% flat miss SEBELUM kalkulasi damage
	# [ASUMSI] Peluang mutlak 35% agar musuh miss, membuat game lebih winnable
	if randf() < ENEMY_MISS_CHANCE:
		battle_log.text = "⚡  %s menyerang... MISS! Serangan meleset!" % str(edata["name"])
		_start_player_turn()
		return

	# [NEW FITUR 3] Gunakan damage yang sudah dideklarasikan sebelumnya
	var actual_dmg: int = enemy_declared_dmg

	if actual_dmg <= 0:
		# [NEW FITUR 4] Miss karena kalkulasi damage = 0
		battle_log.text = "⚡  %s menyerang... MISS!" % str(edata["name"])
		_start_player_turn()
		return

	# [NEW FITUR 5] Proses Temporary Shield terlebih dahulu sebelum HP
	var shield_before: int = PlayerData.current_shield
	if PlayerData.current_shield > 0:
		var absorbed: int = min(PlayerData.current_shield, actual_dmg)
		PlayerData.current_shield -= absorbed
		actual_dmg -= absorbed
		battle_log.text = "🛡️  %s menyerang! Shield menyerap %d. " % [str(edata["name"]), absorbed]

		# [NEW FITUR 5] Retaliation: pantul 50% dari total damage ke musuh saat shield aktif
		if PlayerData.buff_retaliation and shield_before > 0:
			var retaliation_dmg: int = max(1, int(enemy_declared_dmg * 0.5))
			enemy_current_hp = max(0, enemy_current_hp - retaliation_dmg)
			battle_log.text += "\n⚡ Retaliation! %s menerima %d damage balik!" % [str(edata["name"]), retaliation_dmg]
			_update_ui()
			if enemy_current_hp <= 0:
				_handle_enemy_death()
				return
	else:
		battle_log.text = "💥  %s menyerang! " % str(edata["name"])

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
	var ename: String = str(PlayerData.ENEMY_DATA[PlayerData.current_stage]["name"])

	# [NEW FITUR 2] Set flag tier reward SEBELUM pindah scene
	PlayerData.last_defeated_was_boss = PlayerData.is_current_enemy_boss()

	# [NEW FITUR 1] Cek apakah ini final boss (Dragon, stage terakhir)
	if PlayerData.is_final_boss():
		AudioManager.play_win()
		battle_log.text = "🎉  %s dikalahkan! Kamu berhasil melarikan diri dari jurang!" % ename
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu/win_screen.tscn")
	else:
		battle_log.text = "✨  %s dikalahkan! Ambil rewardmu!" % ename
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/gameplay/reward_screen.tscn")

func _handle_player_death() -> void:
	_set_buttons_disabled(true)
	AudioManager.play_lose()
	battle_log.text = "💀  Kamu telah dikalahkan... GAME OVER."
	await get_tree().create_timer(2.5).timeout
	PlayerData.reset_player()
	# [BG] Pindah ke scene Game Over khusus
	get_tree().change_scene_to_file("res://scenes/main_menu/game_over_screen.tscn")

# =============================================================================
# [NEW FITUR 1 & 3] UI HELPER — Encounter text (dipanggil sekali per stage)
# =============================================================================
func _show_encounter_text() -> void:
	if _encounter_shown:
		return
	_encounter_shown = true

	var enemy_name: String   = str(PlayerData.ENEMY_DATA[PlayerData.current_stage]["name"])
	encounter_label.text     = "Kamu dihadang oleh %s." % enemy_name
	encounter_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	encounter_label.visible  = true
	battle_log.text = "⚔️  Kamu dihadang oleh %s!" % enemy_name

	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(encounter_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	tween.tween_callback(func(): encounter_label.visible = false)
