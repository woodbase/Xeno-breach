## Unit tests for the menu system.
##
## Covers:
##   • PauseMenu starts hidden.
##   • PauseMenu.open() makes it visible.
##   • PauseMenu.close() hides it after open().
##   • PauseMenu emits resume_pressed when Resume is pressed.
##   • PauseMenu emits restart_pressed when Restart is pressed.
##   • PauseMenu emits main_menu_pressed when Main Menu is pressed.
##   • PauseMenu emits quit_pressed when Quit is pressed.
##   • GameStateManager.State.PAUSED exists and is distinct from PLAYING.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("MenuSystem tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_pause_menu_starts_hidden()
	test_pause_menu_open_shows()
	test_pause_menu_close_hides()
	test_pause_menu_resume_signal()
	test_pause_menu_restart_signal()
	test_pause_menu_main_menu_signal()
	test_pause_menu_quit_signal()
	test_game_state_paused_distinct_from_playing()
	test_game_state_change_to_paused()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


## Instantiate a PauseMenu by loading the scene.
func _make_pause_menu() -> PauseMenu:
	var packed: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	var pm: PauseMenu = packed.instantiate() as PauseMenu
	add_child(pm)
	return pm


# ── Tests ─────────────────────────────────────────────────────────────────────

func test_pause_menu_starts_hidden() -> void:
	var pm := _make_pause_menu()
	_assert(not pm.visible, "PauseMenu starts hidden")
	pm.queue_free()


func test_pause_menu_open_shows() -> void:
	var pm := _make_pause_menu()
	pm.open()
	_assert(pm.visible, "PauseMenu.open() makes it visible")
	pm.queue_free()


func test_pause_menu_close_hides() -> void:
	var pm := _make_pause_menu()
	pm.open()
	pm.close()
	_assert(not pm.visible, "PauseMenu.close() hides it after open()")
	pm.queue_free()


func test_pause_menu_resume_signal() -> void:
	var pm := _make_pause_menu()
	var fired := false
	pm.resume_pressed.connect(func() -> void: fired = true)
	pm.open()
	pm._on_resume_pressed()
	_assert(fired, "PauseMenu emits resume_pressed")
	pm.queue_free()


func test_pause_menu_restart_signal() -> void:
	var pm := _make_pause_menu()
	var fired := false
	pm.restart_pressed.connect(func() -> void: fired = true)
	pm.open()
	pm._on_restart_pressed()
	_assert(fired, "PauseMenu emits restart_pressed")
	pm.queue_free()


func test_pause_menu_main_menu_signal() -> void:
	var pm := _make_pause_menu()
	var fired := false
	pm.main_menu_pressed.connect(func() -> void: fired = true)
	pm.open()
	pm._on_main_menu_pressed()
	_assert(fired, "PauseMenu emits main_menu_pressed")
	pm.queue_free()


func test_pause_menu_quit_signal() -> void:
	var pm := _make_pause_menu()
	var fired := false
	pm.quit_pressed.connect(func() -> void: fired = true)
	pm.open()
	pm._on_quit_pressed()
	_assert(fired, "PauseMenu emits quit_pressed")
	pm.queue_free()


func test_game_state_paused_distinct_from_playing() -> void:
	_assert(
		GameStateManager.State.PAUSED != GameStateManager.State.PLAYING,
		"GameStateManager.State.PAUSED is distinct from PLAYING"
	)


func test_game_state_change_to_paused() -> void:
	var previous_state: GameStateManager.State = GameStateManager.current_state
	GameStateManager.change_state(GameStateManager.State.PAUSED)
	_assert(
		GameStateManager.current_state == GameStateManager.State.PAUSED,
		"GameStateManager transitions to PAUSED state"
	)
	GameStateManager.change_state(previous_state)
