# =============================================================================
# scripts/ui/win_screen_ui.gd
# Layar kemenangan — tampil setelah Dragon dikalahkan.
# Background: portal.jpg
# =============================================================================
extends Control

@onready var main_menu_btn:   Button      = $CenterContainer/VBoxContainer/MainMenuButton
@onready var background_rect: TextureRect = $Background

func _ready() -> void:
	AudioManager.play_win()

	# Load background via GDScript
	var tex: Texture2D = load("res://assets/backgrounds/portal.jpg")
	if tex:
		background_rect.texture = tex

	# Fade in dari hitam
	modulate = Color(0.0, 0.0, 0.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.5)

	main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _on_main_menu_pressed() -> void:
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
