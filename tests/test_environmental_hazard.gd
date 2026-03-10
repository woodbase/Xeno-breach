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
