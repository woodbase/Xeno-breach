## Unit tests for ExitTrigger activation, deactivation, and player detection,
## and for the GameStateManager data used by the victory screen.
##
## Tests cover:
##   • ExitTrigger starts inactive (hidden, monitoring disabled).
##   • set_active(true) enables visibility and monitoring.
##   • set_active(false) disables visibility and monitoring.
##   • player_extracted is NOT emitted while the trigger is inactive.
##   • player_extracted is NOT emitted for non-player bodies.
##   • player_extracted IS emitted when an active trigger detects a PlayerController.
##   • GameStateManager carries score/waves/next_level_path to the victory screen.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("LevelCompletion tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_exit_trigger_starts_inactive()
	test_exit_trigger_set_active_enables()
	test_exit_trigger_set_active_disables_after_enable()
	test_exit_trigger_no_signal_when_inactive()
	test_exit_trigger_no_signal_for_non_player_body()
	test_exit_trigger_emits_signal_for_player()
	test_game_state_manager_stores_victory_data()
	test_game_state_manager_next_level_scene_path()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


## Create a minimal ExitTrigger with the required child nodes and add it to the tree.
func _make_exit_trigger() -> ExitTrigger:
	var et := ExitTrigger.new()
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	et.add_child(shape)
	var label := Label.new()
	label.name = "Indicator"
	et.add_child(label)
	add_child(et)
	return et


# ── Tests ─────────────────────────────────────────────────────────────────────

func test_exit_trigger_starts_inactive() -> void:
	var et := _make_exit_trigger()
	_assert(not et.visible, "ExitTrigger starts hidden")
	_assert(not et.monitoring, "ExitTrigger starts with monitoring disabled")
	et.queue_free()


func test_exit_trigger_set_active_enables() -> void:
	var et := _make_exit_trigger()
	et.set_active(true)
	_assert(et.visible, "set_active(true) makes ExitTrigger visible")
	_assert(et.monitoring, "set_active(true) enables monitoring")
	et.queue_free()


func test_exit_trigger_set_active_disables_after_enable() -> void:
	var et := _make_exit_trigger()
	et.set_active(true)
	et.set_active(false)
	_assert(not et.visible, "set_active(false) hides ExitTrigger after activation")
	_assert(not et.monitoring, "set_active(false) disables monitoring after activation")
	et.queue_free()


func test_exit_trigger_no_signal_when_inactive() -> void:
	var et := _make_exit_trigger()
	var emitted := false
	et.player_extracted.connect(func() -> void: emitted = true)
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player := player_scene.instantiate() as PlayerController
	add_child(player)
	et._on_body_entered(player)
	_assert(not emitted, "player_extracted not emitted when trigger is inactive")
	player.queue_free()
	et.queue_free()


func test_exit_trigger_no_signal_for_non_player_body() -> void:
	var et := _make_exit_trigger()
	et.set_active(true)
	var emitted := false
	et.player_extracted.connect(func() -> void: emitted = true)
	var body := Node2D.new()
	add_child(body)
	et._on_body_entered(body)
	_assert(not emitted, "player_extracted not emitted for non-player body")
	body.queue_free()
	et.queue_free()


func test_exit_trigger_emits_signal_for_player() -> void:
	var et := _make_exit_trigger()
	et.set_active(true)
	var emitted := false
	et.player_extracted.connect(func() -> void: emitted = true)
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player := player_scene.instantiate() as PlayerController
	add_child(player)
	et._on_body_entered(player)
	_assert(emitted, "player_extracted emitted for PlayerController when trigger is active")
	player.queue_free()
	et.queue_free()


# ── Victory screen data tests ─────────────────────────────────────────────────

func test_game_state_manager_stores_victory_data() -> void:
	var prev_score: int = GameStateManager.final_score
	var prev_waves: int = GameStateManager.final_waves_survived
	GameStateManager.final_score = 1500
	GameStateManager.final_waves_survived = 3
	_assert(GameStateManager.final_score == 1500, "GameStateManager.final_score stores score for victory screen")
	_assert(GameStateManager.final_waves_survived == 3, "GameStateManager.final_waves_survived stores waves for victory screen")
	GameStateManager.final_score = prev_score
	GameStateManager.final_waves_survived = prev_waves


func test_game_state_manager_next_level_scene_path() -> void:
	var prev_path: String = GameStateManager.next_level_scene_path
	GameStateManager.next_level_scene_path = "res://scenes/levels/level_02.tscn"
	_assert(
		GameStateManager.next_level_scene_path == "res://scenes/levels/level_02.tscn",
		"GameStateManager.next_level_scene_path stores next level for victory screen"
	)
	GameStateManager.next_level_scene_path = ""
	_assert(
		GameStateManager.next_level_scene_path.is_empty(),
		"GameStateManager.next_level_scene_path can be cleared"
	)
	GameStateManager.next_level_scene_path = prev_path
