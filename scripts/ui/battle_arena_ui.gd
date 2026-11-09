# =============================================================================
# scripts/ui/battle_arena_ui.gd
# Logika utama Battle Arena — sistem turn-based 1v1.
#
# CHANGELOG (Iterasi 2):
#   [BARU] Fitur 1 — Randomisasi damage + mekanik "Miss"
#   [BARU] Fitur 2 — Opening Screen (panel narasi awal, hanya stage 0)
#   [BARU] Fitur 3 — Dynamic Encounter Text (teks fade-out nama musuh)
#
# Dipasang pada node root scene res://scenes/gameplay/battle_arena.tscn
# =============================================================================
extends Control

# --- Referensi Node lama (tidak berubah) -------------------------------------
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

# --- [BARU] Referensi Node tambahan (harus ditambahkan di .tscn) -------------
@onready var opening_panel:    Panel     = $OpeningPanel             # Fitur 2: Panel narasi awal
@onready var opening_continue: Button    = $OpeningPanel/ContinueButton  # Fitur 2: Tombol lanjutkan
@onready var encounter_label:  Label     = $EncounterLabel           # Fitur 3: Teks fade-out

# --- State lokal pertempuran (tidak berubah) ---------------------------------
var enemy_max_hp:     int = 0
var enemy_current_hp: int = 0

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

	# [BARU - Fitur 2] Cek apakah ini stage pertama (stage 0 = awal game).
	# Jika ya, tampilkan panel narasi pembuka dan kunci tombol aksi dulu.
	if PlayerData.current_stage == 0:
		_show_opening_panel()
	else:
		# Stage selanjutnya (dari Reward Screen): langsung tampilkan encounter text
		_set_buttons_disabled(false)
		_show_encounter_text()   # [BARU - Fitur 3]

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
	player_hp_label.text = "Hero  HP: %d / %d" % [PlayerData.current_hp, PlayerData.max_hp]

func _set_buttons_disabled(disabled: bool) -> void:
	attack_btn.disabled = disabled
	defend_btn.disabled = disabled
	heal_btn.disabled   = disabled

# =============================================================================
# [BARU - Fitur 2] OPENING PANEL — Narasi Awal
# =============================================================================

func _show_opening_panel() -> void:
	# Tampilkan panel narasi dan kunci semua tombol aksi sampai pemain klik lanjutkan
	opening_panel.visible = true
	_set_buttons_disabled(true)
	opening_continue.pressed.connect(_on_opening_continue_pressed)

func _on_opening_continue_pressed() -> void:
	# Sembunyikan panel lalu mulai pertempuran dengan encounter text
	opening_panel.visible = false
	_set_buttons_disabled(false)
	_show_encounter_text()   # [BARU - Fitur 3] Tampilkan teks musuh pertama

# =============================================================================
# [BARU - Fitur 3] DYNAMIC ENCOUNTER TEXT — Teks Nama Musuh Fade-Out
# =============================================================================

func _show_encounter_text() -> void:
	var enemy_name: String = PlayerData.ENEMY_DATA[PlayerData.current_stage]["name"]

	# Set teks sesuai format yang diminta
	encounter_label.text    = "Kamu dihadang oleh %s." % enemy_name
	encounter_label.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Mulai dari opak penuh
	encounter_label.visible  = true

	# Juga tampilkan di battle log sebagai baris pertama sebelum aksi
	battle_log.text = "⚠️  Kamu dihadang oleh %s!" % enemy_name

	# Jalankan animasi fade-out menggunakan Tween bawaan Godot 4
	var tween: Tween = create_tween()
	# Tunggu 1.5 detik, lalu fade out selama 1 detik
	tween.tween_interval(1.5)
	tween.tween_property(encounter_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	tween.tween_callback(func(): encounter_label.visible = false)

# =============================================================================
# [DIMODIFIKASI - Fitur 1] GILIRAN PEMAIN — Damage Random + Mekanik Miss
# =============================================================================

func _on_attack_pressed() -> void:
	_set_buttons_disabled(true)

	# [DIMODIFIKASI - Fitur 1] Hitung damage dengan variasi acak.
	# Formula: Base Attack + randi_range(-2, +3)
	# [ASUMSI] Rentang variasi: -2 hingga +3. Sesuaikan jika diperlukan.
	var variance: int = randi_range(-2, 3)
	var dmg: int = PlayerData.attack_damage + variance

	# [BARU - Fitur 1] Mekanik "Miss": jika damage <= 0, serangan meleset.
	if dmg <= 0:
		battle_log.text = "⚡  Kamu menyerang... MISS! Serangan meleset!"
		_update_ui()
		enemy_turn_timer.start(1.5)
		return   # Hentikan eksekusi — HP musuh TIDAK dikurangi

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
	const HEAL_AMOUNT: int = 20
	var healed: int = min(HEAL_AMOUNT, PlayerData.max_hp - PlayerData.current_hp)
	PlayerData.current_hp += healed
	battle_log.text = "💚  Kamu memulihkan %d HP!" % healed
	_update_ui()
	enemy_turn_timer.start(1.5)

# =============================================================================
# [DIMODIFIKASI - Fitur 1] GILIRAN MUSUH — Damage Random + Mekanik Miss
# =============================================================================

func _execute_enemy_turn() -> void:
	var data: Dictionary = PlayerData.ENEMY_DATA[PlayerData.current_stage]

	# [DIMODIFIKASI - Fitur 1] Damage musuh juga memiliki variasi acak.
	# Formula: Base Attack musuh + randi_range(-2, +3)
	# [ASUMSI] Rentang variasi sama dengan pemain. Sesuaikan jika diperlukan.
	var variance:   int = randi_range(-2, 3)
	var raw_dmg:    int = data["attack"] + variance
	var actual_dmg: int = raw_dmg

	if PlayerData.defense_active:
		# [ASUMSI] Bertahan mengurangi damage sebesar 50% (integer division).
		actual_dmg = raw_dmg / 2
		PlayerData.defense_active = false

		# [BARU - Fitur 1] Cek Miss setelah pertahanan diterapkan
		if actual_dmg <= 0:
			battle_log.text = "🛡️  %s menyerang! Pertahananmu memblok penuh — MISS!" % data["name"]
			_set_buttons_disabled(false)
			return

		battle_log.text = (
			"🛡️  %s menyerang! Bertahan! Kamu menerima %d damage (dari %d)."
			% [data["name"], actual_dmg, raw_dmg]
		)
	else:
		# [BARU - Fitur 1] Cek Miss tanpa pertahanan
		if actual_dmg <= 0:
			battle_log.text = "⚡  %s menyerang... MISS! Serangan meleset!" % data["name"]
			_set_buttons_disabled(false)
			return

		battle_log.text = "💀  %s menyerang! Kamu menerima %d damage!" % [data["name"], actual_dmg]

	PlayerData.current_hp = max(0, PlayerData.current_hp - actual_dmg)
	_update_ui()

	if PlayerData.current_hp <= 0:
		_handle_player_death()
	else:
		_set_buttons_disabled(false)

# =============================================================================
# KONDISI AKHIR PERTEMPURAN (tidak berubah)
# =============================================================================

func _handle_enemy_death() -> void:
	_set_buttons_disabled(true)
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
