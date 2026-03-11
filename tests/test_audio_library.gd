## Unit tests for AudioLibrary procedural streams.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("AudioLibrary tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_blaster_shot_properties()
	test_ambient_loop_properties()
	test_streams_are_cached()
	test_impact_body_properties()
	test_impact_wall_properties()
	test_enemy_death_properties()
	test_player_hurt_properties()
	test_enemy_alert_properties()
	test_enemy_attack_properties()
	test_ui_select_properties()
	test_ui_confirm_properties()
	test_wave_start_properties()
	test_game_over_properties()
	test_get_stream_known_keys()
	test_get_stream_unknown_key()


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


func _assert_wav_valid(stream: AudioStreamWAV, label: String) -> void:
	_assert(stream != null, "%s stream is not null" % label)
	if stream == null:
		return
	_assert(stream.data.size() > 0, "%s has PCM data" % label)
	_assert(stream.mix_rate == AudioLibrary.SAMPLE_RATE, "%s mix_rate matches sample rate" % label)
	_assert(stream.format == AudioStreamWAV.FORMAT_16_BITS, "%s uses 16-bit format" % label)
	_assert(not stream.stereo, "%s is mono" % label)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_blaster_shot_properties() -> void:
	var stream := AudioLibrary.get_blaster_shot()
	_assert_wav_valid(stream, "blaster shot")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "blaster shot does not loop")


func test_ambient_loop_properties() -> void:
	var stream := AudioLibrary.get_ambient_loop()
	_assert_wav_valid(stream, "ambient loop")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "ambient loop is set to loop")


func test_streams_are_cached() -> void:
	var shot_a := AudioLibrary.get_blaster_shot()
	var shot_b := AudioLibrary.get_blaster_shot()
	var ambient_a := AudioLibrary.get_ambient_loop()
	var ambient_b := AudioLibrary.get_ambient_loop()
	_assert(shot_a == shot_b, "blaster shot stream is cached")
	_assert(ambient_a == ambient_b, "ambient loop stream is cached")


func test_impact_body_properties() -> void:
	var stream := AudioLibrary.get_impact_body()
	_assert_wav_valid(stream, "impact_body")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "impact_body does not loop")


func test_impact_wall_properties() -> void:
	var stream := AudioLibrary.get_impact_wall()
	_assert_wav_valid(stream, "impact_wall")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "impact_wall does not loop")


func test_enemy_death_properties() -> void:
	var stream := AudioLibrary.get_enemy_death()
	_assert_wav_valid(stream, "enemy_death")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "enemy_death does not loop")


func test_player_hurt_properties() -> void:
	var stream := AudioLibrary.get_player_hurt()
	_assert_wav_valid(stream, "player_hurt")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "player_hurt does not loop")


func test_enemy_alert_properties() -> void:
	var stream := AudioLibrary.get_enemy_alert()
	_assert_wav_valid(stream, "enemy_alert")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "enemy_alert does not loop")


func test_enemy_attack_properties() -> void:
	var stream := AudioLibrary.get_enemy_attack()
	_assert_wav_valid(stream, "enemy_attack")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "enemy_attack does not loop")


func test_ui_select_properties() -> void:
	var stream := AudioLibrary.get_ui_select()
	_assert_wav_valid(stream, "ui_select")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "ui_select does not loop")


func test_ui_confirm_properties() -> void:
	var stream := AudioLibrary.get_ui_confirm()
	_assert_wav_valid(stream, "ui_confirm")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "ui_confirm does not loop")


func test_wave_start_properties() -> void:
	var stream := AudioLibrary.get_wave_start()
	_assert_wav_valid(stream, "wave_start")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "wave_start does not loop")


func test_game_over_properties() -> void:
	var stream := AudioLibrary.get_game_over()
	_assert_wav_valid(stream, "game_over")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "game_over does not loop")


func test_get_stream_known_keys() -> void:
	var keys: Array[String] = [
		"weapon_fire", "station_ambience", "impact_body", "impact_wall",
		"enemy_death", "player_hurt", "enemy_alert", "enemy_attack",
		"button_select", "button_confirm", "wave_start", "game_over",
		"combat_theme", "menu_theme", "victory_theme",
	]
	for key in keys:
		var stream := AudioLibrary.get_stream(key)
		_assert(stream != null, "get_stream('%s') returns a stream" % key)


func test_get_stream_unknown_key() -> void:
	var stream := AudioLibrary.get_stream("nonexistent_sound")
	_assert(stream == null, "get_stream returns null for unknown key")
