# =============================================================================
# scripts/ui/main_menu_ui.gd
# Logika Main Menu: Start Game, Options, Credits, Quit.
# =============================================================================
extends Control

@onready var start_button:    Button      = $CenterContainer/VBoxContainer/StartButton
@onready var options_button:  Button      = $CenterContainer/VBoxContainer/OptionsButton
@onready var credits_button:  Button      = $CenterContainer/VBoxContainer/CreditsButton
@onready var quit_button:     Button      = $CenterContainer/VBoxContainer/QuitButton
@onready var background_rect: TextureRect = $Background
@onready var title_logo:      TextureRect = $CenterContainer/VBoxContainer/TitleLogo
@onready var options_modal:   Control     = $OptionsModal

func _ready() -> void:
	AudioManager.play_main_menu()
	_load_background()
	_load_title_logo()

	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _load_background() -> void:
	var path: String = "res://assets/backgrounds/main_menu.jpg"
	var tex: Texture2D = null

	var img: Image = Image.load_from_file(path)
	if img:
		tex = ImageTexture.create_from_image(img)
	elif ResourceLoader.exists(path):
		tex = load(path)

	if tex and background_rect:
		background_rect.texture = tex

func _load_title_logo() -> void:
	var path: String = "res://assets/title/title_logo.png"
	var tex: Texture2D = null

	# Muat gambar PNG langsung dari file (bebas dari ketergantungan file .import)
	var img: Image = Image.load_from_file(path)
	if img:
		tex = ImageTexture.create_from_image(img)
	elif ResourceLoader.exists(path):
		tex = load(path)

	if tex and title_logo:
		title_logo.texture = tex

func _on_options_pressed() -> void:
	options_modal.open(false)

func _on_start_pressed() -> void:
	PlayerData.reset_player()
	get_tree().change_scene_to_file("res://scenes/gameplay/battle_arena.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/credits.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
