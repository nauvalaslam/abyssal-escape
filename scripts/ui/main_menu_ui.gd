# =============================================================================
# scripts/ui/main_menu_ui.gd
# Logika Main Menu: Start Game, Credits, Quit.
# Dipasang pada node root scene res://scenes/main_menu/main_menu.tscn
# =============================================================================
extends Control

@onready var start_button:   Button = $CenterContainer/VBoxContainer/StartButton
@onready var credits_button: Button = $CenterContainer/VBoxContainer/CreditsButton
@onready var quit_button:    Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/gameplay/battle_arena.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
