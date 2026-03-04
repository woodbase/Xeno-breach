## SoundManager — autoload singleton for background music and sound-effect playback.
##
## Register as an autoload named "SoundManager" in Project Settings (already done in
## project.godot).  Assign [AudioStream] resources to the exported properties to
## activate each sound; all playback methods are safe to call with unassigned streams
## (missing audio is silently skipped so the game never crashes due to missing audio).
##
## Sound effect keys accepted by [method play_sfx]:
##   "shoot"        — player weapon fire
##   "player_hurt"  — player receives damage
##   "player_die"   — player death
##   "enemy_die"    — enemy death
##   "impact"       — projectile hits an entity
##
## Music keys accepted by [method play_music]:
##   "menu"         — main menu background loop
##   "gameplay"     — in-game background loop
extends Node

## Sound-effect streams — assign .ogg/.wav files via the SoundManager autoload
## settings in the Godot editor (Project → Project Settings → Autoload).
@export var sfx_shoot: AudioStream
@export var sfx_player_hurt: AudioStream
@export var sfx_player_die: AudioStream
@export var sfx_enemy_die: AudioStream
@export var sfx_impact: AudioStream

## Background music streams.
@export var music_menu: AudioStream
@export var music_gameplay: AudioStream

## Master volume for sound effects in decibels.
@export_range(-80.0, 24.0, 0.5) var sfx_volume_db: float = 0.0

## Master volume for background music in decibels.
@export_range(-80.0, 24.0, 0.5) var music_volume_db: float = -6.0

## Number of simultaneous SFX channels in the playback pool.
const SFX_POOL_SIZE: int = 8

var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null
var _sfx_map: Dictionary = {}


func _ready() -> void:
	_build_sfx_pool()
	_build_music_player()
	_build_sfx_map()
	GameStateManager.state_changed.connect(_on_game_state_changed)


func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)


func _build_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)


func _build_sfx_map() -> void:
	_sfx_map = {
		"shoot": sfx_shoot,
		"player_hurt": sfx_player_hurt,
		"player_die": sfx_player_die,
		"enemy_die": sfx_enemy_die,
		"impact": sfx_impact,
	}


## Play a one-shot sound effect identified by [param key].
## Silently no-ops when [param key] is unknown or its stream is not assigned.
func play_sfx(key: String) -> void:
	var stream: AudioStream = _sfx_map.get(key, null) as AudioStream
	if stream == null:
		return
	var player: AudioStreamPlayer = _get_free_sfx_player()
	player.stream = stream
	player.volume_db = sfx_volume_db
	player.play()


## Start looping background music identified by [param key].
## Silently no-ops when [param key] is unknown or its stream is not assigned.
## Does nothing if the requested track is already playing.
func play_music(key: String) -> void:
	var stream: AudioStream
	match key:
		"menu":
			stream = music_menu
		"gameplay":
			stream = music_gameplay
		_:
			return
	if stream == null:
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.volume_db = music_volume_db
	_music_player.play()


## Stop the currently playing background music.
func stop_music() -> void:
	_music_player.stop()
	_music_player.stream = null


## Returns [code]true[/code] if background music is currently playing.
func is_music_playing() -> bool:
	return _music_player.playing


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			return player
	# All channels busy — steal the oldest (index 0).
	return _sfx_pool[0]


## Restart the music track when it finishes, achieving seamless looping.
## Does nothing if [method stop_music] cleared the stream beforehand.
func _on_music_finished() -> void:
	if _music_player.stream != null:
		_music_player.play()


func _on_game_state_changed(
	new_state: GameStateManager.State,
	_old_state: GameStateManager.State
) -> void:
	match new_state:
		GameStateManager.State.MAIN_MENU:
			play_music("menu")
		GameStateManager.State.PLAYING:
			play_music("gameplay")
		GameStateManager.State.PAUSED:
			pass  # Keep current track playing through pause menus.
		GameStateManager.State.GAME_OVER, GameStateManager.State.VICTORY:
			stop_music()
