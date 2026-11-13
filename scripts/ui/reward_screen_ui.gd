# =============================================================================
# scripts/ui/reward_screen_ui.gd
# Layar Roguelike Reward — Dua-Tier Buff System (Iterasi 4 FINAL).
#
# [NEW FITUR 2] Pool reward dibedakan berdasarkan jenis musuh yang baru dikalahkan:
#   - Keroco/Minion → Normal Buff  (+10 HP, +2 Atk, Heal 50%)
#   - Boss          → Synergistic Passive Buff (Vampiric, Retaliation, Second Wind)
# =============================================================================
extends Control

@onready var title_label:      Label       = $CenterContainer/VBoxContainer/TitleLabel
@onready var next_enemy_label: Label       = $CenterContainer/VBoxContainer/NextEnemyHeader/NextEnemyLabel
@onready var next_boss_icon:   TextureRect = $CenterContainer/VBoxContainer/NextEnemyHeader/NextBossIcon
@onready var tier_label:       Label       = $CenterContainer/VBoxContainer/TierHeader/TierLabel
@onready var tier_boss_icon:   TextureRect = $CenterContainer/VBoxContainer/TierHeader/TierBossIcon
@onready var buff1_btn:        Button      = $CenterContainer/VBoxContainer/Buff1Button
@onready var buff2_btn:        Button      = $CenterContainer/VBoxContainer/Buff2Button
@onready var buff3_btn:        Button      = $CenterContainer/VBoxContainer/Buff3Button
@onready var background_rect:  TextureRect = $Background

# [BG] Mapping stage index → path background (sama dengan battle arena)
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

func _get_boss_icon_texture() -> Texture2D:
	if ResourceLoader.exists("res://assets/icons/boss_icon.png"):
		var res = load("res://assets/icons/boss_icon.png")
		if res is Texture2D:
			return res
	var full_path: String = ProjectSettings.globalize_path("res://assets/icons/boss_icon.png")
	if FileAccess.file_exists("res://assets/icons/boss_icon.png"):
		var img: Image = Image.load_from_file(full_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null

func _ready() -> void:
	var btex: Texture2D = _get_boss_icon_texture()
	if next_boss_icon and btex:
		next_boss_icon.texture = btex
	if tier_boss_icon and btex:
		tier_boss_icon.texture = btex

	# [BG] Load background dari stage yang baru saja diselesaikan
	var current_idx: int = PlayerData.current_stage
	if STAGE_BG_MAP.has(current_idx):
		var tex: Texture2D = load(STAGE_BG_MAP[current_idx])
		if tex:
			background_rect.texture = tex
			for child in background_rect.get_children():
				if child is Sprite2D:
					child.texture = tex
					var tw: float = float(tex.get_width())
					var th: float = float(tex.get_height())
					if tw > 0 and th > 0:
						child.position = Vector2(640, 360)
						child.scale = Vector2(1280.0 / tw, 720.0 / th)
	# [NEW FITUR 1] Tampilkan musuh berikutnya (stage + 1)
	var next_stage: int = PlayerData.current_stage + 1
	if next_stage < PlayerData.ENEMY_DATA.size():
		var next_data: Dictionary = PlayerData.ENEMY_DATA[next_stage]
		var next_name: String     = str(next_data["name"])
		var next_is_boss: bool    = bool(next_data["is_boss"])
		next_enemy_label.text = "Musuh berikutnya: %s%s" % [
			next_name,
			"  [BOSS]" if next_is_boss else ""
		]
		if next_boss_icon:
			next_boss_icon.visible = next_is_boss
	else:
		if next_boss_icon:
			next_boss_icon.visible = false
		next_enemy_label.text = "Ini adalah pertarungan terakhir!"

	# [NEW FITUR 2] Pilih tier reward berdasarkan jenis musuh yang baru dikalahkan
	if PlayerData.last_defeated_was_boss:
		_setup_synergistic_buffs()   # [NEW FITUR 2] Boss defeated → Passive buff
	else:
		_setup_normal_buffs()        # [NEW FITUR 2] Keroco defeated → Normal buff

# -----------------------------------------------------------------------------
# [NEW FITUR 2] TIER 1: Normal Buff (setelah mengalahkan Keroco)
# -----------------------------------------------------------------------------
func _setup_normal_buffs() -> void:
	if tier_boss_icon:
		tier_boss_icon.visible = false
	title_label.text = "PILIH REWARD"
	tier_label.text  = "Normal Buff"
	tier_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6, 1))

	buff1_btn.text = "+10 Max HP"
	buff2_btn.text = "+2 Attack"
	buff3_btn.text = "Heal 50% HP"

	buff1_btn.pressed.connect(func(): _apply_and_next("hp_up"))
	buff2_btn.pressed.connect(func(): _apply_and_next("atk_up"))
	buff3_btn.pressed.connect(func(): _apply_and_next("heal_half"))

# -----------------------------------------------------------------------------
# [NEW FITUR 2] TIER 2: Synergistic Passive Buff (setelah mengalahkan Boss)
# -----------------------------------------------------------------------------
func _setup_synergistic_buffs() -> void:
	if tier_boss_icon:
		tier_boss_icon.visible = true
	title_label.text = "PILIH PASSIVE BUFF"
	tier_label.text  = "Boss Reward"
	tier_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))

	# Data buff: [key, nama_tampil, deskripsi, sudah_dimiliki, tombol, signal_name]
	var buff_data: Array = [
		["vampiric",    "Vampiric Strike", "Heal 25% dari setiap damage yang diberikan",    PlayerData.buff_vampiric,    buff1_btn],
		["retaliation", "Retaliation",     "Pantul 50% damage ke musuh saat Shield aktif",  PlayerData.buff_retaliation, buff2_btn],
		["second_wind", "Second Wind",     "Bangkit 1x saat HP = 0, pulih 30% Max HP",      PlayerData.buff_second_wind, buff3_btn],
	]

	for entry in buff_data:
		var key:    String = entry[0]
		var bname:  String = entry[1]
		var desc:   String = entry[2]
		var owned:  bool   = entry[3]
		var btn:    Button = entry[4]

		btn.text = "%s\n%s" % [bname, desc]

		if owned:
			# Buff sudah aktif: kurangi opacity, nonaktifkan interaksi & hover cursor
			btn.modulate        = Color(1.0, 1.0, 1.0, 0.35)   # 35% opacity
			btn.disabled        = true
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW  # hilangkan cursor pointer
		else:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.pressed.connect(func(): _apply_and_next(key))

func _apply_and_next(buff_type: String) -> void:
	buff1_btn.disabled = true
	buff2_btn.disabled = true
	buff3_btn.disabled = true

	PlayerData.apply_buff(buff_type)
	PlayerData.current_stage += 1
	get_tree().change_scene_to_file("res://scenes/gameplay/battle_arena.tscn")
