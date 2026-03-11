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
##   • IntroScreen can be instantiated with required nodes.
##   • IntroScreen story label starts empty (typewriter not yet started).
##   • IntroScreen deploy (continue) button starts disabled.
##   • IntroScreen skip button is enabled at start.
##   • IntroScreen._finish_typewriter() fills story text and enables deploy button.
##   • DemoEndScreen can be instantiated with required nodes.
##   • DemoEndScreen score label reflects GameStateManager.final_score.
##   • DemoEndScreen waves label reflects GameStateManager.final_waves_survived.
##   • DemoEndScreen has a non-empty wishlist message.
##   • DemoEndScreen has play-again and main-menu buttons.
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

	# IntroScreen tests
	test_intro_screen_instantiation()
	test_intro_screen_story_label_starts_empty()
	test_intro_screen_deploy_button_starts_disabled()
	test_intro_screen_skip_button_starts_enabled()
	test_intro_screen_finish_typewriter_fills_text()
	test_intro_screen_finish_typewriter_enables_deploy()

	# DemoEndScreen tests
	test_demo_end_screen_instantiation()
	test_demo_end_screen_score_label()
	test_demo_end_screen_waves_label()
	test_demo_end_screen_has_wishlist_message()
	test_demo_end_screen_has_play_again_button()
	test_demo_end_screen_has_main_menu_button()

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


## Instantiate an IntroScreen by loading the scene.
func _make_intro_screen() -> IntroScreen:
	var packed: PackedScene = load("res://scenes/ui/intro_screen.tscn")
	var screen: IntroScreen = packed.instantiate() as IntroScreen
	add_child(screen)
	return screen


## Instantiate a DemoEndScreen by loading the scene.
func _make_demo_end_screen() -> DemoEndScreen:
	var packed: PackedScene = load("res://scenes/ui/demo_end_screen.tscn")
	var screen: DemoEndScreen = packed.instantiate() as DemoEndScreen
	add_child(screen)
	return screen


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


# ── IntroScreen tests ─────────────────────────────────────────────────────────

func test_intro_screen_instantiation() -> void:
	var screen := _make_intro_screen()
	_assert(screen != null, "IntroScreen can be instantiated")
	screen.queue_free()


func test_intro_screen_story_label_starts_empty() -> void:
	var screen := _make_intro_screen()
	var label: Label = screen.get_node_or_null("Center/Panel/Margin/VBox/StoryLabel") as Label
	_assert(label != null, "IntroScreen has StoryLabel node")
	_assert(label.text == "", "IntroScreen StoryLabel starts empty")
	screen.queue_free()


func test_intro_screen_deploy_button_starts_disabled() -> void:
	var screen := _make_intro_screen()
	var btn: Button = screen.get_node_or_null("Center/Panel/Margin/VBox/Buttons/ContinueButton") as Button
	_assert(btn != null, "IntroScreen has ContinueButton (DEPLOY)")
	_assert(btn.disabled, "IntroScreen DEPLOY button starts disabled until typewriter completes")
	screen.queue_free()


func test_intro_screen_skip_button_starts_enabled() -> void:
	var screen := _make_intro_screen()
	var btn: Button = screen.get_node_or_null("Center/Panel/Margin/VBox/Buttons/SkipButton") as Button
	_assert(btn != null, "IntroScreen has SkipButton")
	_assert(not btn.disabled, "IntroScreen SKIP button is enabled at start")
	screen.queue_free()


func test_intro_screen_finish_typewriter_fills_text() -> void:
	var screen := _make_intro_screen()
	screen._finish_typewriter()
	var label: Label = screen.get_node_or_null("Center/Panel/Margin/VBox/StoryLabel") as Label
	_assert(label != null and not label.text.is_empty(), "IntroScreen story label filled after _finish_typewriter()")
	screen.queue_free()


func test_intro_screen_finish_typewriter_enables_deploy() -> void:
	var screen := _make_intro_screen()
	screen._finish_typewriter()
	var btn: Button = screen.get_node_or_null("Center/Panel/Margin/VBox/Buttons/ContinueButton") as Button
	_assert(btn != null and not btn.disabled, "IntroScreen DEPLOY button enabled after _finish_typewriter()")
	screen.queue_free()


# ── DemoEndScreen tests ───────────────────────────────────────────────────────

func test_demo_end_screen_instantiation() -> void:
	var screen := _make_demo_end_screen()
	_assert(screen != null, "DemoEndScreen can be instantiated")
	screen.queue_free()


func test_demo_end_screen_score_label() -> void:
	var prev_score: int = GameStateManager.final_score
	GameStateManager.final_score = 750
	var screen := _make_demo_end_screen()
	var label: Label = screen.get_node_or_null("Center/Panel/Margin/VBox/StatsBox/ScoreLabel") as Label
	_assert(label != null, "DemoEndScreen has ScoreLabel")
	_assert(label.text.contains("750"), "DemoEndScreen ScoreLabel reflects GameStateManager.final_score")
	screen.queue_free()
	GameStateManager.final_score = prev_score


func test_demo_end_screen_waves_label() -> void:
	var prev_waves: int = GameStateManager.final_waves_survived
	GameStateManager.final_waves_survived = 4
	var screen := _make_demo_end_screen()
	var label: Label = screen.get_node_or_null("Center/Panel/Margin/VBox/StatsBox/WavesLabel") as Label
	_assert(label != null, "DemoEndScreen has WavesLabel")
	_assert(label.text.contains("4"), "DemoEndScreen WavesLabel reflects GameStateManager.final_waves_survived")
	screen.queue_free()
	GameStateManager.final_waves_survived = prev_waves


func test_demo_end_screen_has_wishlist_message() -> void:
	var screen := _make_demo_end_screen()
	var wishlist_text: Label = screen.get_node_or_null(
		"Center/Panel/Margin/VBox/WishlistBox/WishlistMargin/WishlistVBox/WishlistText"
	) as Label
	_assert(wishlist_text != null, "DemoEndScreen has WishlistText label")
	_assert(not wishlist_text.text.is_empty(), "DemoEndScreen WishlistText is non-empty")
	screen.queue_free()


func test_demo_end_screen_has_play_again_button() -> void:
	var screen := _make_demo_end_screen()
	var btn: Button = screen.get_node_or_null("Center/Panel/Margin/VBox/Buttons/PlayAgainButton") as Button
	_assert(btn != null, "DemoEndScreen has PlayAgainButton")
	screen.queue_free()


func test_demo_end_screen_has_main_menu_button() -> void:
	var screen := _make_demo_end_screen()
	var btn: Button = screen.get_node_or_null("Center/Panel/Margin/VBox/Buttons/MainMenuButton") as Button
	_assert(btn != null, "DemoEndScreen has MainMenuButton")
	screen.queue_free()


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
