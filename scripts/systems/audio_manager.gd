## AudioManager — autoload singleton that manages all game audio (SFX, music, ambience).
##
## Access via the global [code]AudioManager[/code] singleton.
## Handles sound effect playback, background music, and audio bus management.
## When an OGG audio file is absent, the manager falls back to a synthesized stream
## from [AudioLibrary] so that all sound cues work out-of-the-box.

extends Node

const AudioLibrary = preload("res://scripts/systems/audio_library.gd")


## Audio bus names
const BUS_MASTER: String = "Master"
const BUS_SFX: String = "SFX"
const BUS_MUSIC: String = "Music"
const BUS_UI: String = "UI"
const BUS_AMBIENCE: String = "Ambience"

## Audio stream players for different categories
var sfx_players: Array[AudioStreamPlayer2D] = []
var ui_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var music_loop_enabled: bool = false
var ambience_loop_enabled: bool = false

## Current music track
var current_music: AudioStream = null

## Number of pooled SFX players for positional audio
const SFX_POOL_SIZE: int = 10

## Audio file paths
const SOUNDS := {
	"weapon_fire": "res://assets/audio/sfx/weapons/blaster_fire.ogg",
	"impact_body": "res://assets/audio/sfx/impacts/impact_body.ogg",
	"impact_wall": "res://assets/audio/sfx/impacts/impact_wall.ogg",
	"enemy_death": "res://assets/audio/sfx/impacts/enemy_death.ogg",
	"player_hurt": "res://assets/audio/sfx/impacts/player_hurt.ogg",
	"enemy_alert": "res://assets/audio/sfx/enemies/enemy_alert.ogg",
	"enemy_attack": "res://assets/audio/sfx/enemies/enemy_attack.ogg",
	"button_select": "res://assets/audio/sfx/ui/button_select.ogg",
	"button_confirm": "res://assets/audio/sfx/ui/button_confirm.ogg",
	"wave_start": "res://assets/audio/sfx/ui/wave_start.ogg",
	"game_over": "res://assets/audio/sfx/ui/game_over.ogg",
	"menu_theme": "res://assets/audio/music/menu_theme.ogg",
	"combat_theme": "res://assets/audio/music/combat_theme.ogg",
	"victory_theme": "res://assets/audio/music/victory_theme.ogg",
	"station_ambience": "res://assets/audio/ambience/station_hum.ogg",
}


func _ready() -> void:
	_setup_audio_players()
	_setup_audio_buses()


## Setup audio player nodes for different categories
func _setup_audio_players() -> void:
	# Create pooled AudioStreamPlayer2D nodes for positional SFX
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer2D.new()
		player.bus = BUS_SFX
		player.max_distance = 1000.0
		add_child(player)
		sfx_players.append(player)

	# Create UI sound player (non-positional)
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = BUS_UI
	add_child(ui_player)

	# Create music player (non-positional, looping)
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	# Create ambience player (non-positional, looping)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = BUS_AMBIENCE
	ambience_player.finished.connect(_on_ambience_finished)
	add_child(ambience_player)


## Setup audio buses if they don't exist
func _setup_audio_buses() -> void:
	# Create audio buses if they don't exist
	_create_bus_if_missing(BUS_SFX)
	_create_bus_if_missing(BUS_MUSIC)
	_create_bus_if_missing(BUS_UI)
	_create_bus_if_missing(BUS_AMBIENCE)


## Create audio bus if it doesn't exist
func _create_bus_if_missing(bus_name: String) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


## Get next available SFX player from pool
func _get_available_sfx_player() -> AudioStreamPlayer2D:
	for player in sfx_players:
		if not player.playing:
			return player
	# If all players are busy, return the first one (it will be interrupted)
	return sfx_players[0]


## Return an AudioStream for [param sound_name].
## Tries to load the OGG file defined in SOUNDS first.
## Falls back to a procedural stream from AudioLibrary when the file is absent.
func _load_stream(sound_name: String) -> AudioStream:
	var sound_path: String = SOUNDS[sound_name]
	if ResourceLoader.exists(sound_path):
		var file_stream := load(sound_path) as AudioStream
		if file_stream != null:
			return file_stream
	# No asset file — use procedural fallback if available
	return AudioLibrary.get_stream(sound_name)


## Play a sound effect at a specific position in the world
func play_sfx(sound_name: String, position: Vector2 = Vector2.ZERO) -> void:
	if not SOUNDS.has(sound_name):
		push_warning("AudioManager: Sound '%s' not found in SOUNDS dictionary" % sound_name)
		return

	var stream: AudioStream = _load_stream(sound_name)
	if stream == null:
		return

	var player := _get_available_sfx_player()
	player.stream = stream
	player.global_position = position
	player.play()


## Play a UI sound (non-positional)
func play_ui(sound_name: String) -> void:
	if not SOUNDS.has(sound_name):
		push_warning("AudioManager: Sound '%s' not found in SOUNDS dictionary" % sound_name)
		return

	var stream: AudioStream = _load_stream(sound_name)
	if stream == null:
		return

	ui_player.stream = stream
	ui_player.play()


## Play background music (looping)
func play_music(music_name: String, fade_duration: float = 1.0) -> void:
	if not SOUNDS.has(music_name):
		push_warning("AudioManager: Music '%s' not found in SOUNDS dictionary" % music_name)
		return

	var music_path: String = SOUNDS[music_name]
	if not ResourceLoader.exists(music_path):
		return

	var stream := load(music_path) as AudioStream
	if stream == null:
		return

	# Don't restart if already playing the same track
	if current_music == stream and music_player.playing:
		return

	current_music = stream

	# Simple fade by stopping current and starting new
	# (Advanced fade would use Tween to interpolate volume)
	if music_player.playing:
		music_player.stop()

	music_loop_enabled = true
	music_player.stream = stream
	music_player.play()


## Stop background music
func stop_music(fade_duration: float = 1.0) -> void:
	if music_player.playing:
		music_player.stop()
	music_loop_enabled = false
	current_music = null


## Play ambient sound (looping)
func play_ambience(ambience_name: String) -> void:
	if not SOUNDS.has(ambience_name):
		push_warning("AudioManager: Ambience '%s' not found in SOUNDS dictionary" % ambience_name)
		return

	var ambience_path: String = SOUNDS[ambience_name]
	if not ResourceLoader.exists(ambience_path):
		return

	var stream := load(ambience_path) as AudioStream
	if stream == null:
		return

	ambience_loop_enabled = true
	ambience_player.stream = stream
	ambience_player.play()


## Stop ambient sound
func stop_ambience() -> void:
	if ambience_player.playing:
		ambience_player.stop()
	ambience_loop_enabled = false


func _on_music_finished() -> void:
	if music_loop_enabled and music_player.stream != null:
		music_player.play()


func _on_ambience_finished() -> void:
	if ambience_loop_enabled and ambience_player.stream != null:
		ambience_player.play()


## Set volume for a specific audio bus (0.0 to 1.0)
func set_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager: Bus '%s' not found" % bus_name)
		return

	var volume_db := linear_to_db(clamp(volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_index, volume_db)


## Get volume for a specific audio bus (0.0 to 1.0)
func get_bus_volume(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return 0.0

	var volume_db := AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(volume_db)


## Mute/unmute a specific audio bus
func set_bus_mute(bus_name: String, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("AudioManager: Bus '%s' not found" % bus_name)
		return

	AudioServer.set_bus_mute(bus_index, muted)


## Check if a bus is muted
func is_bus_muted(bus_name: String) -> bool:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return false

	return AudioServer.is_bus_mute(bus_index)
