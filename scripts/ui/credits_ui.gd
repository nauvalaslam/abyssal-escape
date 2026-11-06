# =============================================================================
# scripts/ui/credits_ui.gd
# Menampilkan teks credits tim dan tombol kembali ke Main Menu.
# Dipasang pada node root scene res://scenes/main_menu/credits.tscn
# =============================================================================
extends Control

@onready var credits_label: Label  = $CenterContainer/VBoxContainer/CreditsLabel
@onready var back_button:   Button = $CenterContainer/VBoxContainer/BackButton

func _ready() -> void:
	credits_label.text = _get_credits_text()
	back_button.pressed.connect(_on_back_pressed)

# Teks credits final — JANGAN ubah nama/NIM di bawah ini.
func _get_credits_text() -> String:
	return (
		"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
		+ "\n"
		+ "Ketua: Nauval Rusdi Aslam - 235150207111030\n"
		+ "\n"
		+ "Anggota: Ahmad Muzaki Ulumuddin - 235150207111040\n"
		+ "\n"
		+ "Anggota: Bimaelsa Wahyu Kurnia - 215150207111015\n"
		+ "\n"
		+ "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
		+ "\n"
		+ "Dibuat dengan Godot Engine 4.x"
	)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
