## Unit tests for EnvironmentalHazard damage application.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("EnvironmentalHazard tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_hazard_ticks_damage_over_time()
	test_hazard_respects_affects_players_flag()
	test_hazard_physics_process_starts_disabled()
	test_hazard_physics_process_enabled_on_body_enter()
	test_hazard_physics_process_disabled_on_last_body_exit()
	test_hazard_physics_process_disabled_after_invalid_body_cleanup()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


func _make_hazard(dps: float, tick: float) -> EnvironmentalHazard:
	var hazard := EnvironmentalHazard.new()
	hazard.damage_per_second = dps
	hazard.tick_interval = tick
	add_child(hazard)
	return hazard


func _make_player(max_hp: float = 100.0) -> Dictionary:
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	var health := HealthComponent.new()
	health.max_health = max_hp
	player.add_child(health)
	add_child(player)
	return {"player": player, "health": health}


func test_hazard_ticks_damage_over_time() -> void:
	var hazard := _make_hazard(20.0, 0.2)
	var obj := _make_player(50.0)
	var player := obj["player"] as Node
	var health := obj["health"] as HealthComponent
	hazard._on_body_entered(player)
	hazard._physics_process(0.2)
	hazard._physics_process(0.2)
	_assert(health.current_health < 50.0,
		"hazard applies damage on scheduled ticks")
	hazard.queue_free()
	player.queue_free()


func test_hazard_respects_affects_players_flag() -> void:
	var hazard := _make_hazard(30.0, 0.1)
	hazard.affects_players = false
	var obj := _make_player(40.0)
	var player := obj["player"] as Node
	var health := obj["health"] as HealthComponent
	hazard._on_body_entered(player)
	hazard._physics_process(0.3)
	_assert(health.current_health == 40.0,
		"hazard does not damage players when affects_players is false")
	hazard.queue_free()
	player.queue_free()


# ── Performance: idle-pause tests ────────────────────────────────────────────

func test_hazard_physics_process_starts_disabled() -> void:
	var hazard := _make_hazard(10.0, 0.5)
	_assert(not hazard.is_physics_processing(),
		"hazard physics_process is disabled at startup when no bodies overlap")
	hazard.queue_free()


func test_hazard_physics_process_enabled_on_body_enter() -> void:
	var hazard := _make_hazard(10.0, 0.5)
	var obj := _make_player(50.0)
	var player := obj["player"] as Node
	hazard._on_body_entered(player)
	_assert(hazard.is_physics_processing(),
		"hazard physics_process is enabled when the first body enters")
	hazard.queue_free()
	player.queue_free()


func test_hazard_physics_process_disabled_on_last_body_exit() -> void:
	var hazard := _make_hazard(10.0, 0.5)
	var obj := _make_player(50.0)
	var player := obj["player"] as Node
	hazard._on_body_entered(player)
	hazard._on_body_exited(player)
	_assert(not hazard.is_physics_processing(),
		"hazard physics_process is disabled again when the last body exits")
	hazard.queue_free()
	player.queue_free()


func test_hazard_physics_process_disabled_after_invalid_body_cleanup() -> void:
	var hazard := _make_hazard(10.0, 0.5)
	var obj := _make_player(50.0)
	var player := obj["player"] as Node
	hazard._on_body_entered(player)
	# Immediately free the body so is_instance_valid returns false on the
	# next _physics_process tick, exercising the stale-body cleanup path.
	player.free()
	hazard._physics_process(0.016)
	_assert(not hazard.is_physics_processing(),
		"hazard physics_process is disabled after invalid body is cleaned up")
	hazard.queue_free()
