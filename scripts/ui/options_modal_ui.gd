# =============================================================================
# scripts/ui/options_modal_ui.gd
# Dialog popup Pengaturan (Options) untuk mengatur volume musik BGM & navigasi.
# =============================================================================
extends Control

@onready var volume_slider:      HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeSection/VolumeSlider
@onready var volume_value_label: Label   = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeSection/Header/VolumeValueLabel
@onready var close_button:       Button  = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton
@onready var main_menu_button:   Button  = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MainMenuButton

func _ready() -> void:
	var initial_vol: float = AudioManager.get_volume() * 100.0
	volume_slider.value = initial_vol
	volume_value_label.text = "%d%%" % int(initial_vol)

	volume_slider.value_changed.connect(_on_volume_changed)
	close_button.pressed.connect(_on_close_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func open(is_in_game: bool = false) -> void:
	var current_vol: float = AudioManager.get_volume() * 100.0
	volume_slider.value = current_vol
	volume_value_label.text = "%d%%" % int(current_vol)

	# Tombol Kembali ke Main Menu hanya muncul saat di dalam game/pertarungan
	main_menu_button.visible = is_in_game
	if is_in_game:
		close_button.text = "Lanjutkan Permainan"
	else:
		close_button.text = "Tutup"

	visible = true

func close() -> void:
	visible = false

func _on_volume_changed(val: float) -> void:
	volume_value_label.text = "%d%%" % int(val)
	AudioManager.set_volume(val / 100.0)

func _on_close_pressed() -> void:
	close()

func _on_main_menu_pressed() -> void:
	close()
	PlayerData.reset_player()
	AudioManager.play_main_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
