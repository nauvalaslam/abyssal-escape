# =============================================================================
# scripts/globals/audio_manager.gd
# AUTOLOAD SINGLETON — Pengelola Musik Latar (BGM) untuk Abyssal Escape.
#
# Memuat dan memainkan 6 OST:
#   1. main_menu  : 1. trapped inside the dungeon (main menu ost)
#   2. battle     : 2. fight your way out (battle ost - keroco)
#   3. boss       : 3. Shadow of the Cavern (boss ost)
#   4. final_boss : 4. Apex of the Abyss (final boss ost - dragon)
#   5. win        : 5. Escaped (win ost)
#   6. lose       : 6. Forgotten (lose ost)
# =============================================================================
extends Node

const TRACKS: Dictionary = {
	"main_menu":  "res://assets/audio/main_menu_ost.mp3",
	"battle":     "res://assets/audio/battle_ost.mp3",
	"boss":       "res://assets/audio/boss_ost.mp3",
	"final_boss": "res://assets/audio/final_boss_ost.mp3",
	"win":        "res://assets/audio/win_ost.mp3",
	"lose":       "res://assets/audio/lose_ost.mp3",
}

var current_track: String = ""
var bgm_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

func play_track(track_name: String) -> void:
	# Jika track yang sama sedang berputar, jangan restart dari detik ke-0
	if track_name == current_track and bgm_player.playing:
		return

	if not TRACKS.has(track_name):
		push_warning("AudioManager: Track '%s' tidak ditemukan!" % track_name)
		return

	var path: String = TRACKS[track_name]
	var stream: AudioStream = null

	# Metode 1: Muat byte MP3 langsung via FileAccess (tanpa perlu ketergantungan import editor)
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var mp3_stream = AudioStreamMP3.new()
			mp3_stream.data = file.get_buffer(file.get_length())
			mp3_stream.loop = true
			stream = mp3_stream

	# Metode 2: Fallback standar jika metode 1 tidak aktif
	if not stream and ResourceLoader.exists(path):
		stream = load(path)
		if stream and stream is AudioStreamMP3:
			stream.loop = true

	if stream:
		bgm_player.stream = stream
		bgm_player.play()
		current_track = track_name

# --- Helper functions untuk kemudahan pemanggilan ---
func play_main_menu() -> void:
	play_track("main_menu")

func play_battle() -> void:
	play_track("battle")

func play_boss() -> void:
	play_track("boss")

func play_final_boss() -> void:
	play_track("final_boss")

func play_win() -> void:
	play_track("win")

func play_lose() -> void:
	play_track("lose")

func stop() -> void:
	if bgm_player:
		bgm_player.stop()
	current_track = ""
