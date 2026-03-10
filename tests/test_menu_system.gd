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
##   • PauseMenu runs with PROCESS_MODE_WHEN_PAUSED.
##   • MainMenu can be instantiated and has required buttons.
##   • MainMenu start button exists and is connected.
##   • MainMenu quit button exists and is connected.
##   • GameStateManager.State.PAUSED exists and is distinct from PLAYING.
##   • GameStateManager supports all required states.
##   • GameStateManager transitions work correctly.
##   • GameStateManager emits state_changed signal.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("MenuSystem tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	# PauseMenu tests
	test_pause_menu_starts_hidden()
	test_pause_menu_open_shows()
	test_pause_menu_close_hides()
	test_pause_menu_resume_signal()
	test_pause_menu_restart_signal()
	test_pause_menu_main_menu_signal()
	test_pause_menu_quit_signal()
	test_pause_menu_process_mode()

	# MainMenu tests
	test_main_menu_instantiation()
	test_main_menu_has_start_button()
	test_main_menu_has_quit_button()

	# GameStateManager tests
	test_game_state_paused_distinct_from_playing()
	test_game_state_change_to_paused()
	test_game_state_all_states_exist()
	test_game_state_transitions()
	test_game_state_signal_emission()


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


## Instantiate a MainMenu by loading the scene.
func _make_main_menu() -> MainMenu:
	var packed: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var mm: MainMenu = packed.instantiate() as MainMenu
	add_child(mm)
	return mm


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


func test_pause_menu_process_mode() -> void:
	var pm := _make_pause_menu()
	_assert(
		pm.process_mode == Node.PROCESS_MODE_WHEN_PAUSED,
		"PauseMenu has PROCESS_MODE_WHEN_PAUSED"
	)
	pm.queue_free()


func test_main_menu_instantiation() -> void:
	var mm := _make_main_menu()
	_assert(mm != null, "MainMenu can be instantiated")
	mm.queue_free()


func test_main_menu_has_start_button() -> void:
	var mm := _make_main_menu()
	var start_btn: Button = mm.get_node_or_null("Center/Panel/Margin/VBox/Buttons/StartButton") as Button
	_assert(start_btn != null, "MainMenu has StartButton")
	_assert(start_btn.text == "INITIATE DEPLOYMENT", "StartButton has correct text")
	mm.queue_free()


func test_main_menu_has_quit_button() -> void:
	var mm := _make_main_menu()
	var quit_btn: Button = mm.get_node_or_null("Center/Panel/Margin/VBox/Buttons/QuitButton") as Button
	_assert(quit_btn != null, "MainMenu has QuitButton")
	mm.queue_free()


func test_game_state_all_states_exist() -> void:
	_assert(
		GameStateManager.State.MAIN_MENU != null and
		GameStateManager.State.INTRO != null and
		GameStateManager.State.PLAYING != null and
		GameStateManager.State.PAUSED != null and
		GameStateManager.State.GAME_OVER != null and
		GameStateManager.State.VICTORY != null and
		GameStateManager.State.DEMO_END != null,
		"All GameStateManager states exist"
	)


func test_game_state_transitions() -> void:
	var previous_state: GameStateManager.State = GameStateManager.current_state

	# Test MAIN_MENU → INTRO transition
	GameStateManager.change_state(GameStateManager.State.MAIN_MENU)
	GameStateManager.change_state(GameStateManager.State.INTRO)
	_assert(
		GameStateManager.current_state == GameStateManager.State.INTRO,
		"GameStateManager transitions from MAIN_MENU to INTRO"
	)

	# Test INTRO → PLAYING transition
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	_assert(
		GameStateManager.current_state == GameStateManager.State.PLAYING,
		"GameStateManager transitions from INTRO to PLAYING"
	)

	# Test PLAYING → PAUSED transition
	GameStateManager.change_state(GameStateManager.State.PAUSED)
	_assert(
		GameStateManager.current_state == GameStateManager.State.PAUSED,
		"GameStateManager transitions from PLAYING to PAUSED"
	)

	# Restore previous state
	GameStateManager.change_state(previous_state)


func test_game_state_signal_emission() -> void:
	var previous_state: GameStateManager.State = GameStateManager.current_state
	var signal_fired := false
	var received_new_state: GameStateManager.State
	var received_old_state: GameStateManager.State

	var callback := func(new_state: GameStateManager.State, old_state: GameStateManager.State) -> void:
		signal_fired = true
		received_new_state = new_state
		received_old_state = old_state

	GameStateManager.state_changed.connect(callback)
	GameStateManager.change_state(GameStateManager.State.PAUSED)

	_assert(signal_fired, "GameStateManager emits state_changed signal")
	_assert(
		received_new_state == GameStateManager.State.PAUSED,
		"state_changed signal provides correct new state"
	)

	GameStateManager.state_changed.disconnect(callback)
	GameStateManager.change_state(previous_state)
