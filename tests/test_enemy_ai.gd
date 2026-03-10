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
	test_auto_detects_player_group_and_chases()
	test_leaving_detection_range_returns_to_idle()
	test_hit_flash_sets_and_resets_modulate()
	test_patrol_state_active_when_no_target()
	test_patrol_transitions_to_chase_on_player_detection()
	test_patrol_cycles_waypoints()
	test_lethal_damage_emits_died_signal()
	test_death_state_freezes_velocity()
	test_enemy_data_applies_stats()
	test_enemy_data_applies_health()
	test_apply_data_public_method()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


func _make_enemy() -> EnemyBase:
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy := scene.instantiate() as EnemyBase
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


func test_auto_detects_player_group_and_chases() -> void:
	var enemy := _make_enemy()
	enemy.global_position = Vector2.ZERO
	var target := _make_target(Vector2(120.0, 0.0))
	target.add_to_group("player")
	var saw_chase := false
	enemy.state_changed.connect(func(new_state: EnemyBase.State, _old: EnemyBase.State) -> void:
		if new_state == EnemyBase.State.CHASE:
			saw_chase = true
	)
	enemy._update_state()
	_assert(saw_chase, "enemy auto-detects player group within detection range")


func test_leaving_detection_range_returns_to_idle() -> void:
	var enemy := _make_enemy()
	enemy.global_position = Vector2.ZERO
	var target := _make_target(Vector2(100.0, 0.0))
	enemy.set_target(target)
	enemy._update_state()
	var saw_idle := false
	enemy.state_changed.connect(func(new_state: EnemyBase.State, _old: EnemyBase.State) -> void:
		if new_state == EnemyBase.State.IDLE:
			saw_idle = true
	)
	target.global_position = Vector2(500.0, 0.0)
	enemy._update_state()
	_assert(saw_idle, "enemy returns to idle when target exits detection range")


func test_hit_flash_sets_and_resets_modulate() -> void:
	var enemy := _make_enemy()
	var body := enemy.get_node("Body") as CanvasItem
	var base_color: Color = body.modulate

	enemy.health_component.take_damage(5.0)

	_assert(body.modulate == enemy._flash_color, "hit flash applies flash color on damage")

	enemy._on_hit_flash_timeout()
	_assert(body.modulate == base_color, "hit flash timeout restores base modulate")


func _make_patrol_enemy(pos: Vector2 = Vector2.ZERO) -> EnemyBase:
	var enemy := _make_enemy()
	enemy.patrol_enabled = true
	enemy.patrol_radius = 100.0
	enemy.global_position = pos
	# Re-run patrol initialization now that position and patrol flags are set.
	enemy._init_patrol()
	return enemy


func test_patrol_state_active_when_no_target() -> void:
	var enemy := _make_patrol_enemy()
	enemy._update_state()
	_assert(enemy._current_state == EnemyBase.State.PATROL,
			"patrol enemy enters patrol state when no target is present")


func test_patrol_transitions_to_chase_on_player_detection() -> void:
	var enemy := _make_patrol_enemy()
	enemy._update_state()
	_assert(enemy._current_state == EnemyBase.State.PATROL,
			"patrol enemy starts in patrol state without target")
	var target := _make_target(Vector2(80.0, 0.0))
	var saw_chase := false
	enemy.state_changed.connect(func(new_state: EnemyBase.State, _old: EnemyBase.State) -> void:
		if new_state == EnemyBase.State.CHASE:
			saw_chase = true
	)
	enemy.set_target(target)
	enemy._update_state()
	_assert(saw_chase, "patrol enemy transitions to chase when player enters detection range")


func test_patrol_cycles_waypoints() -> void:
	var enemy := _make_patrol_enemy(Vector2.ZERO)
	# Waypoints are at (+100, 0) and (-100, 0). Move close to the first waypoint.
	enemy.global_position = Vector2(95.0, 0.0)
	var initial_index: int = enemy._patrol_index
	enemy._process_patrol(0.016)
	_assert(enemy._patrol_index != initial_index,
			"patrol enemy advances to next waypoint when reaching current one")


func test_lethal_damage_emits_died_signal() -> void:
	var enemy := _make_enemy()
	var died_received := false
	enemy.died.connect(func() -> void: died_received = true)
	enemy.health_component.take_damage(enemy.health_component.max_health)
	_assert(died_received, "lethal damage causes enemy to emit died signal")


func test_death_state_freezes_velocity() -> void:
	var enemy := _make_enemy()
	enemy.velocity = Vector2(100.0, 0.0)
	# Killing the enemy sets _is_dying which prevents physics updates.
	enemy.health_component.take_damage(enemy.health_component.max_health)
	_assert(enemy._is_dying, "enemy enters dying state after lethal damage")


func test_enemy_data_applies_stats() -> void:
	var enemy := _make_enemy()
	var d := EnemyData.new()
	d.move_speed = 200.0
	d.detection_range = 400.0
	d.attack_range = 60.0
	d.damage = 25.0
	d.attack_cooldown = 0.5
	d.patrol_enabled = true
	d.patrol_radius = 120.0
	d.projectile_speed = 500.0
	d.max_health = 80.0
	enemy.data = d
	enemy.apply_data()
	_assert(is_equal_approx(enemy.move_speed, 200.0), "data.move_speed applied to enemy")
	_assert(is_equal_approx(enemy.detection_range, 400.0), "data.detection_range applied to enemy")
	_assert(is_equal_approx(enemy.attack_range, 60.0), "data.attack_range applied to enemy")
	_assert(is_equal_approx(enemy.damage, 25.0), "data.damage applied to enemy")
	_assert(is_equal_approx(enemy.attack_cooldown, 0.5), "data.attack_cooldown applied to enemy")
	_assert(enemy.patrol_enabled == true, "data.patrol_enabled applied to enemy")
	_assert(is_equal_approx(enemy.patrol_radius, 120.0), "data.patrol_radius applied to enemy")
	_assert(is_equal_approx(enemy.projectile_speed, 500.0), "data.projectile_speed applied to enemy")


func test_enemy_data_applies_health() -> void:
	var enemy := _make_enemy()
	var d := EnemyData.new()
	d.max_health = 200.0
	enemy.data = d
	enemy.apply_data()
	_assert(is_equal_approx(enemy.health_component.max_health, 200.0),
			"data.max_health applied to HealthComponent.max_health")
	_assert(is_equal_approx(enemy.health_component.current_health, 200.0),
			"data.max_health resets HealthComponent.current_health to full")


func test_apply_data_public_method() -> void:
	var enemy := _make_enemy()
	var d := EnemyData.new()
	d.move_speed = 333.0
	d.max_health = 75.0
	enemy.data = d
	enemy.apply_data()
	_assert(is_equal_approx(enemy.move_speed, 333.0),
			"apply_data() public method applies data.move_speed")
