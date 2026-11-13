# =============================================================================
# scripts/ui/main_menu_ui.gd
# Logika Main Menu: Start Game, Credits, Quit.
# =============================================================================
extends Control

@onready var start_button:    Button      = $CenterContainer/VBoxContainer/StartButton
@onready var options_button:  Button      = $CenterContainer/VBoxContainer/OptionsButton
@onready var credits_button:  Button      = $CenterContainer/VBoxContainer/CreditsButton
@onready var quit_button:     Button      = $CenterContainer/VBoxContainer/QuitButton
@onready var background_rect: TextureRect = $Background
@onready var options_modal:   Control     = $OptionsModal

func _ready() -> void:
	AudioManager.play_main_menu()

	# Load background via GDScript agar tidak butuh .import file di .tscn
	var tex: Texture2D = load("res://assets/backgrounds/main_menu.jpg")
	if tex:
		background_rect.texture = tex

	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_options_pressed() -> void:
	options_modal.open()

func _on_start_pressed() -> void:
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/gameplay/battle_arena.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
