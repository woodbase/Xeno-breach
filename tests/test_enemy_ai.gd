## Unit tests for EnemyBase state transitions.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("Enemy AI tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_missing_target_stays_idle()
	test_target_in_detection_range_switches_to_chase()
	test_target_in_attack_range_switches_to_attack()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


func _make_enemy() -> EnemyBase:
	var enemy := EnemyBase.new()
	enemy.detection_range = 200.0
	enemy.attack_range = 40.0
	add_child(enemy)
	return enemy


func _make_target(pos: Vector2) -> Node2D:
	var target := Node2D.new()
	target.global_position = pos
	add_child(target)
	return target


func test_missing_target_stays_idle() -> void:
	var enemy := _make_enemy()
	enemy.global_position = Vector2.ZERO
	var changed := false
	enemy.state_changed.connect(func(_n: EnemyBase.State, _o: EnemyBase.State) -> void: changed = true)
	enemy._update_state()
	_assert(not changed, "enemy remains idle when target is missing")


func test_target_in_detection_range_switches_to_chase() -> void:
	var enemy := _make_enemy()
	enemy.global_position = Vector2.ZERO
	var target := _make_target(Vector2(100.0, 0.0))
	var saw_chase := false
	enemy.state_changed.connect(func(new_state: EnemyBase.State, _old: EnemyBase.State) -> void:
		if new_state == EnemyBase.State.CHASE:
			saw_chase = true
	)
	enemy.set_target(target)
	enemy._update_state()
	_assert(saw_chase, "enemy enters chase within detection range")


func test_target_in_attack_range_switches_to_attack() -> void:
	var enemy := _make_enemy()
	enemy.global_position = Vector2.ZERO
	var target := _make_target(Vector2(20.0, 0.0))
	var saw_attack := false
	enemy.state_changed.connect(func(new_state: EnemyBase.State, _old: EnemyBase.State) -> void:
		if new_state == EnemyBase.State.ATTACK:
			saw_attack = true
	)
	enemy.set_target(target)
	enemy._update_state()
	_assert(saw_attack, "enemy enters attack inside attack range")
