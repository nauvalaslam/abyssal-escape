# =============================================================================
# scripts/ui/reward_screen_ui.gd
# Layar Roguelike Reward: pemain memilih 1 dari 3 buff setelah musuh mati.
# Setelah dipilih, stage diincrement dan game lanjut ke BattleArena berikutnya.
# Dipasang pada node root scene res://scenes/gameplay/reward_screen.tscn
# =============================================================================
extends Control

@onready var title_label:      Label  = $CenterContainer/VBoxContainer/TitleLabel
@onready var next_enemy_label: Label  = $CenterContainer/VBoxContainer/NextEnemyLabel
@onready var buff1_btn:        Button = $CenterContainer/VBoxContainer/Buff1Button
@onready var buff2_btn:        Button = $CenterContainer/VBoxContainer/Buff2Button
@onready var buff3_btn:        Button = $CenterContainer/VBoxContainer/Buff3Button

func _ready() -> void:
	var next_stage: int    = PlayerData.current_stage + 1
	var next_name:  String = PlayerData.ENEMY_DATA[next_stage]["name"]

	title_label.text      = "PILIH REWARD"
	next_enemy_label.text = "Musuh berikutnya: %s" % next_name

	# [ASUMSI] Daftar dan teks buff roguelike. Tambah opsi baru cukup di sini
	# dan tambahkan entri match baru di PlayerData.apply_buff().
	buff1_btn.text = "+30 Max HP  &  Pulihkan 30 HP"
	buff2_btn.text = "+10 Attack Damage"
	buff3_btn.text = "Pulihkan HP Penuh"

	buff1_btn.pressed.connect(func(): _apply_and_next("hp_up"))
	buff2_btn.pressed.connect(func(): _apply_and_next("dmg_up"))
	buff3_btn.pressed.connect(func(): _apply_and_next("heal_full"))

func _apply_and_next(buff_type: String) -> void:
	# Nonaktifkan semua tombol agar tidak bisa diklik dua kali
	buff1_btn.disabled = true
	buff2_btn.disabled = true
	buff3_btn.disabled = true

	PlayerData.apply_buff(buff_type)
	PlayerData.current_stage += 1
	get_tree().change_scene_to_file("res://scenes/gameplay/battle_arena.tscn")
