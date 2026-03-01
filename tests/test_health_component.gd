## Unit tests for HealthComponent.
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
	print("HealthComponent tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_initial_health_equals_max()
	test_take_damage_reduces_health()
	test_health_cannot_go_below_zero()
	test_died_signal_on_lethal_damage()
	test_damaged_signal_carries_amount()
	test_health_changed_signal_emitted()
	test_heal_restores_health()
	test_heal_cannot_exceed_max()
	test_negative_damage_is_ignored()
	test_negative_heal_is_ignored()
	test_get_health_percent_full()
	test_get_health_percent_half()
	test_is_alive_true_when_healthy()
	test_is_alive_false_after_death()


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


func _make_hc(max_hp: float = 100.0) -> HealthComponent:
	var hc := HealthComponent.new()
	hc.max_health = max_hp
	add_child(hc)
	return hc


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_initial_health_equals_max() -> void:
	var hc := _make_hc(80.0)
	_assert(hc.current_health == 80.0, "initial health equals max_health")


func test_take_damage_reduces_health() -> void:
	var hc := _make_hc(100.0)
	hc.take_damage(30.0)
	_assert(hc.current_health == 70.0, "take_damage reduces health by exact amount")


func test_health_cannot_go_below_zero() -> void:
	var hc := _make_hc(100.0)
	hc.take_damage(200.0)
	_assert(hc.current_health == 0.0, "health clamped to 0 on overkill")


func test_died_signal_on_lethal_damage() -> void:
	var hc := _make_hc(100.0)
	var died := false
	hc.died.connect(func() -> void: died = true)
	hc.take_damage(100.0)
	_assert(died, "died signal emitted on lethal damage")


func test_damaged_signal_carries_amount() -> void:
	var hc := _make_hc(100.0)
	var received: float = 0.0
	hc.damaged.connect(func(a: float) -> void: received = a)
	hc.take_damage(42.0)
	_assert(received == 42.0, "damaged signal carries correct amount")


func test_health_changed_signal_emitted() -> void:
	var hc := _make_hc(100.0)
	var emitted := false
	hc.health_changed.connect(func(_c: float, _m: float) -> void: emitted = true)
	hc.take_damage(10.0)
	_assert(emitted, "health_changed signal emitted after damage")


func test_heal_restores_health() -> void:
	var hc := _make_hc(100.0)
	hc.take_damage(50.0)
	hc.heal(20.0)
	_assert(hc.current_health == 70.0, "heal restores correct amount")


func test_heal_cannot_exceed_max() -> void:
	var hc := _make_hc(100.0)
	hc.heal(50.0)
	_assert(hc.current_health == 100.0, "heal clamped to max_health")


func test_negative_damage_is_ignored() -> void:
	var hc := _make_hc(100.0)
	hc.take_damage(-25.0)
	_assert(hc.current_health == 100.0, "negative damage is ignored")


func test_negative_heal_is_ignored() -> void:
	var hc := _make_hc(100.0)
	hc.take_damage(40.0)
	hc.heal(-10.0)
	_assert(hc.current_health == 60.0, "negative heal is ignored")


func test_get_health_percent_full() -> void:
	var hc := _make_hc(100.0)
	_assert(hc.get_health_percent() == 1.0, "get_health_percent returns 1.0 at full health")


func test_get_health_percent_half() -> void:
	var hc := _make_hc(100.0)
	hc.take_damage(50.0)
	_assert(hc.get_health_percent() == 0.5, "get_health_percent returns 0.5 at half health")


func test_is_alive_true_when_healthy() -> void:
	var hc := _make_hc(100.0)
	_assert(hc.is_alive(), "is_alive returns true when health > 0")


func test_is_alive_false_after_death() -> void:
	var hc := _make_hc(100.0)
	hc.take_damage(100.0)
	_assert(not hc.is_alive(), "is_alive returns false when health == 0")
