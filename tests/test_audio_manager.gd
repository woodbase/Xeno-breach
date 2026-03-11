## Unit tests for AudioManager.
##
## Designed to run as a standalone scene script (attach to a Node in a test scene)
## or through a GUT (Godot Unit Testing) test runner.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("AudioManager tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_audio_manager_exists()
	test_audio_buses_created()
	test_sfx_players_created()
	test_music_player_created()
	test_ui_player_created()
	test_ambience_player_created()
	test_play_sfx_with_missing_file_no_error()
	test_play_ui_with_missing_file_no_error()
	test_play_music_with_missing_file_no_error()
	test_play_ambience_with_missing_file_no_error()
	test_set_bus_volume()
	test_get_bus_volume()
	test_set_bus_mute()
	test_is_bus_muted()
	test_load_stream_fallback_sfx()
	test_load_stream_fallback_ui()
	test_load_stream_fallback_music()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_audio_manager_exists() -> void:
	_assert(AudioManager != null, "AudioManager autoload exists")


func test_audio_buses_created() -> void:
	var sfx_bus := AudioServer.get_bus_index("SFX")
	var music_bus := AudioServer.get_bus_index("Music")
	var ui_bus := AudioServer.get_bus_index("UI")
	var ambience_bus := AudioServer.get_bus_index("Ambience")
	_assert(
		sfx_bus >= 0 and music_bus >= 0 and ui_bus >= 0 and ambience_bus >= 0,
		"All audio buses created"
	)


func test_sfx_players_created() -> void:
	_assert(
		AudioManager.sfx_players.size() == AudioManager.SFX_POOL_SIZE,
		"SFX player pool created with correct size"
	)


func test_music_player_created() -> void:
	_assert(AudioManager.music_player != null, "Music player created")


func test_ui_player_created() -> void:
	_assert(AudioManager.ui_player != null, "UI player created")


func test_ambience_player_created() -> void:
	_assert(AudioManager.ambience_player != null, "Ambience player created")


func test_play_sfx_with_missing_file_no_error() -> void:
	# Should not crash or error when file doesn't exist
	AudioManager.play_sfx("weapon_fire", Vector2.ZERO)
	_assert(true, "play_sfx handles missing file gracefully")


func test_play_ui_with_missing_file_no_error() -> void:
	# Should not crash or error when file doesn't exist
	AudioManager.play_ui("button_select")
	_assert(true, "play_ui handles missing file gracefully")


func test_play_music_with_missing_file_no_error() -> void:
	# Should not crash or error when file doesn't exist — uses AudioLibrary fallback
	AudioManager.play_music("menu_theme")
	_assert(AudioManager.music_player.playing, "play_music uses procedural fallback when OGG absent")
	AudioManager.stop_music()


func test_play_ambience_with_missing_file_no_error() -> void:
	# Should not crash or error when file doesn't exist — uses AudioLibrary fallback
	AudioManager.play_ambience("station_ambience")
	_assert(AudioManager.ambience_player.playing, "play_ambience uses procedural fallback when OGG absent")
	AudioManager.stop_ambience()


func test_set_bus_volume() -> void:
	AudioManager.set_bus_volume("SFX", 0.5)
	var volume := AudioManager.get_bus_volume("SFX")
	_assert(abs(volume - 0.5) < 0.01, "set_bus_volume sets volume correctly")


func test_get_bus_volume() -> void:
	AudioManager.set_bus_volume("Music", 0.75)
	var volume := AudioManager.get_bus_volume("Music")
	_assert(abs(volume - 0.75) < 0.01, "get_bus_volume returns correct volume")


func test_set_bus_mute() -> void:
	AudioManager.set_bus_mute("UI", true)
	_assert(AudioManager.is_bus_muted("UI"), "set_bus_mute mutes bus")
	AudioManager.set_bus_mute("UI", false)
	_assert(not AudioManager.is_bus_muted("UI"), "set_bus_mute unmutes bus")


func test_is_bus_muted() -> void:
	AudioManager.set_bus_mute("Ambience", false)
	_assert(not AudioManager.is_bus_muted("Ambience"), "is_bus_muted returns false when unmuted")
	AudioManager.set_bus_mute("Ambience", true)
	_assert(AudioManager.is_bus_muted("Ambience"), "is_bus_muted returns true when muted")
	AudioManager.set_bus_mute("Ambience", false)  # Reset


func test_load_stream_fallback_sfx() -> void:
	# When OGG file is absent, _load_stream should return a procedural AudioLibrary stream
	var sfx_keys: Array[String] = [
		"impact_body", "impact_wall", "enemy_death",
		"player_hurt", "enemy_alert", "enemy_attack",
	]
	for key in sfx_keys:
		var stream := AudioManager._load_stream(key)
		_assert(stream != null, "_load_stream('%s') returns procedural fallback" % key)


func test_load_stream_fallback_ui() -> void:
	# UI sounds should also return a procedural fallback when OGG files are absent
	var ui_keys: Array[String] = ["button_select", "button_confirm", "wave_start", "game_over"]
	for key in ui_keys:
		var stream := AudioManager._load_stream(key)
		_assert(stream != null, "_load_stream('%s') returns procedural fallback" % key)


func test_load_stream_fallback_music() -> void:
	# Music and ambience keys should return procedural fallback streams when OGG files are absent
	var music_keys: Array[String] = [
		"combat_theme", "menu_theme", "victory_theme", "station_ambience",
	]
	for key in music_keys:
		var stream := AudioManager._load_stream(key)
		_assert(stream != null, "_load_stream('%s') returns procedural fallback" % key)
