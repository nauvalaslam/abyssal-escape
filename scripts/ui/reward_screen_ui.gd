# =============================================================================
# scripts/ui/reward_screen_ui.gd
# Layar Roguelike Reward — 3 passive buff unik (Iterasi 3).
#
# [NEW FITUR 5] Buff dirombak menjadi kemampuan pasif sinergis:
#   - Vampiric Strike: heal 25% dari damage diberikan
#   - Retaliation: pantul 50% dmg ke musuh saat shield aktif
#   - Second Wind: bangkit 1x saat HP = 0 (pulih 30% Max HP)
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

	title_label.text      = "PILIH PASSIVE BUFF"
	next_enemy_label.text = "Musuh berikutnya: %s" % next_name

	# [NEW FITUR 5] Teks buff pasif unik — tandai jika sudah dimiliki
	buff1_btn.text = _buff_label(
		"🩸 Vampiric Strike",
		"Heal 25% dari setiap damage yang diberikan",
		PlayerData.buff_vampiric
	)
	buff2_btn.text = _buff_label(
		"⚡ Retaliation",
		"Pantul 50% damage ke musuh saat Shield aktif",
		PlayerData.buff_retaliation
	)
	buff3_btn.text = _buff_label(
		"💨 Second Wind",
		"Bangkit 1x saat HP = 0, pulih 30% Max HP",
		PlayerData.buff_second_wind
	)

	buff1_btn.pressed.connect(func(): _apply_and_next("vampiric"))
	buff2_btn.pressed.connect(func(): _apply_and_next("retaliation"))
	buff3_btn.pressed.connect(func(): _apply_and_next("second_wind"))

# Helper: format label tombol buff + tanda [AKTIF] jika sudah dimiliki
func _buff_label(name: String, desc: String, already_owned: bool) -> String:
	if already_owned:
		return "%s\n%s\n[SUDAH AKTIF]" % [name, desc]
	return "%s\n%s" % [name, desc]

func _apply_and_next(buff_type: String) -> void:
	buff1_btn.disabled = true
	buff2_btn.disabled = true
	buff3_btn.disabled = true

	PlayerData.apply_buff(buff_type)
	PlayerData.current_stage += 1
	get_tree().change_scene_to_file("res://scenes/gameplay/battle_arena.tscn")
