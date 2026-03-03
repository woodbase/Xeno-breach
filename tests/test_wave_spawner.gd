## Unit tests for WaveSpawner wave data and spawn safety helpers.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("WaveSpawner tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_wave_data_overrides_total_waves()
	test_wave_enemy_count_negative_is_clamped()
	test_spawn_point_respects_min_distance()
	test_missing_spawn_point_returns_null()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


func _make_wave(enemy_count: int, spawn_delay: float) -> WaveData:
	var wave := WaveData.new()
	wave.enemy_count = enemy_count
	wave.spawn_delay = spawn_delay
	return wave


func test_wave_data_overrides_total_waves() -> void:
	var spawner := WaveSpawner.new()
	spawner.total_waves = 99
	spawner.wave_data_list = [_make_wave(3, 0.2), _make_wave(4, 0.3)]
	_assert(spawner._get_total_waves() == 2, "wave_data_list size controls total waves")


func test_wave_enemy_count_negative_is_clamped() -> void:
	var spawner := WaveSpawner.new()
	spawner.wave_data_list = [_make_wave(-5, 0.3)]
	_assert(spawner._get_wave_enemy_count(0) == 0, "negative wave enemy count is clamped to zero")


func test_spawn_point_respects_min_distance() -> void:
	var spawner := WaveSpawner.new()
	var player := Node2D.new()
	player.global_position = Vector2.ZERO
	spawner._player = player
	spawner.min_spawn_distance_from_player = 200.0
	spawner.spawn_retry_count = 1

	var near := Marker2D.new()
	near.global_position = Vector2(100.0, 0.0)
	var far := Marker2D.new()
	far.global_position = Vector2(400.0, 0.0)
	spawner.spawn_points = [near, far]

	var selected := spawner._select_spawn_point()
	_assert(selected == far, "spawn selection returns a valid far point via fallback")


func test_missing_spawn_point_returns_null() -> void:
	var spawner := WaveSpawner.new()
	spawner.spawn_points = []
	_assert(spawner._select_spawn_point() == null, "empty spawn list returns null")
