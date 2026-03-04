## Unit tests for CoopManager difficulty scaling.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("CoopManager tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_default_player_count_is_one()
	test_player_count_clamps_to_max()
	test_player_count_clamps_to_min()
	test_single_player_enemy_count_multiplier_is_one()
	test_two_player_enemy_count_multiplier()
	test_three_player_enemy_count_multiplier()
	test_four_player_enemy_count_multiplier()
	test_single_player_health_multiplier_is_one()
	test_two_player_health_multiplier()
	test_three_player_health_multiplier()
	test_four_player_health_multiplier()
	test_player_count_changed_signal()
	test_setting_same_count_does_not_emit_signal()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


func _make_coop() -> CoopManager:
	var cm := CoopManager.new()
	add_child(cm)
	return cm


func test_default_player_count_is_one() -> void:
	var cm := _make_coop()
	_assert(cm.player_count == 1, "default player_count is 1")


func test_player_count_clamps_to_max() -> void:
	var cm := _make_coop()
	cm.player_count = 99
	_assert(cm.player_count == CoopManager.MAX_PLAYERS, "player_count clamped to MAX_PLAYERS")


func test_player_count_clamps_to_min() -> void:
	var cm := _make_coop()
	cm.player_count = -5
	_assert(cm.player_count == 1, "player_count clamped to minimum of 1")


func test_single_player_enemy_count_multiplier_is_one() -> void:
	var cm := _make_coop()
	cm.player_count = 1
	_assert(is_equal_approx(cm.get_enemy_count_multiplier(), 1.0),
		"1 player: enemy count multiplier is 1.0")


func test_two_player_enemy_count_multiplier() -> void:
	var cm := _make_coop()
	cm.player_count = 2
	_assert(is_equal_approx(cm.get_enemy_count_multiplier(), 1.5),
		"2 players: enemy count multiplier is 1.5")


func test_three_player_enemy_count_multiplier() -> void:
	var cm := _make_coop()
	cm.player_count = 3
	_assert(is_equal_approx(cm.get_enemy_count_multiplier(), 2.0),
		"3 players: enemy count multiplier is 2.0")


func test_four_player_enemy_count_multiplier() -> void:
	var cm := _make_coop()
	cm.player_count = 4
	_assert(is_equal_approx(cm.get_enemy_count_multiplier(), 2.5),
		"4 players: enemy count multiplier is 2.5")


func test_single_player_health_multiplier_is_one() -> void:
	var cm := _make_coop()
	cm.player_count = 1
	_assert(is_equal_approx(cm.get_enemy_health_multiplier(), 1.0),
		"1 player: enemy health multiplier is 1.0")


func test_two_player_health_multiplier() -> void:
	var cm := _make_coop()
	cm.player_count = 2
	_assert(is_equal_approx(cm.get_enemy_health_multiplier(), 1.25),
		"2 players: enemy health multiplier is 1.25")


func test_three_player_health_multiplier() -> void:
	var cm := _make_coop()
	cm.player_count = 3
	_assert(is_equal_approx(cm.get_enemy_health_multiplier(), 1.5),
		"3 players: enemy health multiplier is 1.5")


func test_four_player_health_multiplier() -> void:
	var cm := _make_coop()
	cm.player_count = 4
	_assert(is_equal_approx(cm.get_enemy_health_multiplier(), 1.75),
		"4 players: enemy health multiplier is 1.75")


func test_player_count_changed_signal() -> void:
	var cm := _make_coop()
	var received: int = 0
	cm.player_count_changed.connect(func(n: int) -> void: received = n)
	cm.player_count = 3
	_assert(received == 3, "player_count_changed signal carries the new count")


func test_setting_same_count_does_not_emit_signal() -> void:
	var cm := _make_coop()
	cm.player_count = 2
	var signal_count: int = 0
	cm.player_count_changed.connect(func(_n: int) -> void: signal_count += 1)
	cm.player_count = 2  # same value — should not emit
	_assert(signal_count == 0, "signal not emitted when player_count unchanged")
