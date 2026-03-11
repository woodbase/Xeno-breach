## Unit tests for Enemy Expansion — elite enemies and boss encounters.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("Enemy Expansion tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_enemy_data_has_is_elite_flag()
	test_enemy_data_has_score_value()
	test_is_elite_false_by_default()
	test_score_value_default()
	test_elite_data_applies_is_elite()
	test_elite_visual_tint_applied_on_ready()
	test_elite_visual_tint_updates_base_modulate()
	test_elite_apply_data_after_ready_updates_base_modulate()
	test_non_elite_data_does_not_change_modulate()
	test_boss_starts_in_phase_one()
	test_boss_phase_two_triggered_below_half_hp()
	test_boss_phase_two_increases_speed()
	test_boss_phase_two_reduces_attack_cooldown()
	test_boss_phase_two_emits_signal()
	test_boss_phase_two_triggers_once()
	test_boss_get_current_phase_returns_one_initially()
	test_boss_get_current_phase_returns_two_after_threshold()
	test_boss_above_half_hp_stays_phase_one()


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
	add_child(enemy)
	return enemy


func _make_boss() -> BossEnemy:
	var scene: PackedScene = load("res://scenes/enemies/boss.tscn")
	var boss := scene.instantiate() as BossEnemy
	add_child(boss)
	return boss


# ── EnemyData field tests ─────────────────────────────────────────────────────

func test_enemy_data_has_is_elite_flag() -> void:
	var d := EnemyData.new()
	_assert("is_elite" in d, "EnemyData has is_elite property")


func test_enemy_data_has_score_value() -> void:
	var d := EnemyData.new()
	_assert("score_value" in d, "EnemyData has score_value property")


func test_is_elite_false_by_default() -> void:
	var d := EnemyData.new()
	_assert(d.is_elite == false, "EnemyData.is_elite defaults to false")


func test_score_value_default() -> void:
	var d := EnemyData.new()
	_assert(d.score_value == 10, "EnemyData.score_value defaults to 10")


func test_elite_data_applies_is_elite() -> void:
	var d := EnemyData.new()
	d.is_elite = true
	_assert(d.is_elite == true, "EnemyData.is_elite can be set to true")


# ── Elite visual tint tests ───────────────────────────────────────────────────

func test_elite_visual_tint_applied_on_ready() -> void:
	var enemy := _make_enemy()
	var d := EnemyData.new()
	d.is_elite = true
	d.max_health = enemy.health_component.max_health
	enemy.data = d
	# _init_hit_flash has already run (add_child triggers _ready).
	# Calling apply_data should update the body tint.
	enemy.apply_data()
	var body := enemy.get_node("Body") as CanvasItem
	_assert(body.modulate == Color(1.0, 0.85, 0.2, 1.0),
			"elite enemy body modulate set to golden tint after apply_data")


func test_elite_visual_tint_updates_base_modulate() -> void:
	var enemy := _make_enemy()
	var d := EnemyData.new()
	d.is_elite = true
	d.max_health = enemy.health_component.max_health
	enemy.data = d
	enemy.apply_data()
	_assert(enemy._base_modulate == Color(1.0, 0.85, 0.2, 1.0),
			"elite apply_data sets _base_modulate to golden tint")


func test_elite_apply_data_after_ready_updates_base_modulate() -> void:
	var enemy := _make_enemy()
	var d := EnemyData.new()
	d.is_elite = true
	d.max_health = 50.0
	enemy.data = d
	enemy.apply_data()
	# After apply_data the hit-flash timer has already been created.
	_assert(enemy._hit_flash_timer != null,
			"_hit_flash_timer exists when apply_data called after _ready")
	_assert(enemy._base_modulate == Color(1.0, 0.85, 0.2, 1.0),
			"_base_modulate updated to elite tint when apply_data runs post-_ready")


func test_non_elite_data_does_not_change_modulate() -> void:
	var enemy := _make_enemy()
	var original_modulate: Color = (enemy.get_node("Body") as CanvasItem).modulate
	var d := EnemyData.new()
	d.is_elite = false
	d.max_health = enemy.health_component.max_health
	enemy.data = d
	enemy.apply_data()
	var body := enemy.get_node("Body") as CanvasItem
	_assert(body.modulate == original_modulate,
			"non-elite apply_data leaves body modulate unchanged")


# ── BossEnemy phase tests ─────────────────────────────────────────────────────

func test_boss_starts_in_phase_one() -> void:
	var boss := _make_boss()
	_assert(boss._current_phase == 1, "boss starts in phase 1")


func test_boss_phase_two_triggered_below_half_hp() -> void:
	var boss := _make_boss()
	# Deliver enough damage to drop below 50 % HP without killing (boss HP = 500).
	boss.health_component.take_damage(260.0)
	_assert(boss._phase_2_triggered, "phase 2 triggered when HP falls below 50 %")


func test_boss_phase_two_increases_speed() -> void:
	var boss := _make_boss()
	var speed_before: float = boss.move_speed
	boss.health_component.take_damage(260.0)
	_assert(boss.move_speed > speed_before,
			"boss move_speed increases after phase 2 transition")


func test_boss_phase_two_reduces_attack_cooldown() -> void:
	var boss := _make_boss()
	var cooldown_before: float = boss.attack_cooldown
	boss.health_component.take_damage(260.0)
	_assert(boss.attack_cooldown < cooldown_before,
			"boss attack_cooldown decreases (faster attacks) after phase 2 transition")


func test_boss_phase_two_emits_signal() -> void:
	var boss := _make_boss()
	var received_phase: int = -1
	boss.phase_changed.connect(func(p: int) -> void: received_phase = p)
	boss.health_component.take_damage(260.0)
	_assert(received_phase == 2,
			"phase_changed signal emitted with value 2 on phase 2 transition")


func test_boss_phase_two_triggers_once() -> void:
	var boss := _make_boss()
	var signal_count: int = 0
	boss.phase_changed.connect(func(_p: int) -> void: signal_count += 1)
	boss.health_component.take_damage(260.0)
	boss.health_component.take_damage(50.0)
	_assert(signal_count == 1,
			"phase_changed signal emitted exactly once even after multiple damage events")


func test_boss_get_current_phase_returns_one_initially() -> void:
	var boss := _make_boss()
	_assert(boss.get_current_phase() == 1,
			"get_current_phase returns 1 before threshold is crossed")


func test_boss_get_current_phase_returns_two_after_threshold() -> void:
	var boss := _make_boss()
	boss.health_component.take_damage(260.0)
	_assert(boss.get_current_phase() == 2,
			"get_current_phase returns 2 after HP falls below 50 %")


func test_boss_above_half_hp_stays_phase_one() -> void:
	var boss := _make_boss()
	# Take exactly 50 % damage (still exactly at boundary — no phase change).
	boss.health_component.take_damage(250.0)
	_assert(boss._current_phase == 1,
			"boss stays in phase 1 when HP is exactly at 50 % threshold")
