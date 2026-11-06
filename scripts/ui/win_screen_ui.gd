# =============================================================================
# scripts/ui/win_screen_ui.gd
# Layar kemenangan yang muncul setelah Dragon (Boss) dikalahkan.
# Menampilkan teks "SURVIVED" dengan efek fade-in, lalu tombol kembali.
# Dipasang pada node root scene res://scenes/main_menu/win_screen.tscn
# =============================================================================
extends Control

@onready var main_menu_btn: Button = $CenterContainer/VBoxContainer/MainMenuButton

func _ready() -> void:
	# Mulai dari transparan lalu fade in ke opak
	modulate = Color(0.0, 0.0, 0.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.5)

	main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _on_main_menu_pressed() -> void:
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
