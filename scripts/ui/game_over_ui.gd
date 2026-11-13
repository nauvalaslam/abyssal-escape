# =============================================================================
# scripts/ui/game_over_ui.gd
# Layar Game Over — tampil saat pemain kalah di pertempuran.
# Background: game_over.jpg
# =============================================================================
extends Control

@onready var retry_btn:       Button      = $CenterContainer/VBoxContainer/RetryButton
@onready var main_menu_btn:   Button      = $CenterContainer/VBoxContainer/MainMenuButton
@onready var background_rect: TextureRect = $Background

func _ready() -> void:
	AudioManager.play_lose()

	# Load background via GDScript
	var tex: Texture2D = load("res://assets/backgrounds/game_over.jpg")
	if tex:
		background_rect.texture = tex

	# Fade in dari hitam
	modulate = Color(0.0, 0.0, 0.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 1.5)

	retry_btn.pressed.connect(_on_retry_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _on_retry_pressed() -> void:
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/gameplay/battle_arena.tscn")

func _on_main_menu_pressed() -> void:
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
