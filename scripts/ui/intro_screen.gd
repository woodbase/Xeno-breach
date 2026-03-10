## IntroScreen — typewriter-style story introduction shown before gameplay begins.
##
## Reveals lore text character by character.  The player can press Fire / Confirm
## to skip the animation; pressing again (or clicking [b]CONTINUE[/b]) starts the
## game.  The [b]SKIP[/b] button jumps straight to gameplay at any time.
class_name IntroScreen
extends Control

const GAME_SCENE: String = "res://scenes/levels/test_level.tscn"
const CHAR_DELAY: float = 0.022

const STORY_TEXT: String = \
"""YEAR 2187.

Station Horizon-8 — outer rim industrial sector.

A xenobiological research division reported a full containment
breach forty-seven minutes ago.  All communication has since
ceased.

Thermal imaging confirms multiple unidentified life-forms
throughout the facility.  Casualties: unknown.

You are ALPHA-7, rapid response unit.

Orders: neutralise the threat.  Restore containment.
Leave no breach survivors.

The clock is running, Agent.

— MISSION CONTROL OUT —"""

@onready var story_label: Label = $Center/Panel/Margin/VBox/StoryLabel
@onready var continue_button: Button = $Center/Panel/Margin/VBox/Buttons/ContinueButton
@onready var skip_button: Button = $Center/Panel/Margin/VBox/Buttons/SkipButton

var _char_index: int = 0
var _typewriter_timer: Timer = null
var _is_complete: bool = false


func _ready() -> void:
	GameStateManager.change_state(GameStateManager.State.INTRO)
	AudioManager.play_music("menu_theme")

	continue_button.pressed.connect(_on_continue_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	continue_button.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	skip_button.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	continue_button.focus_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	skip_button.focus_entered.connect(func() -> void: AudioManager.play_ui("button_select"))

	story_label.text = ""
	continue_button.disabled = true
	skip_button.grab_focus()

	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = CHAR_DELAY
	_typewriter_timer.timeout.connect(_advance_typewriter)
	add_child(_typewriter_timer)
	_typewriter_timer.start()


func _advance_typewriter() -> void:
	if _char_index >= STORY_TEXT.length():
		_typewriter_timer.stop()
		_is_complete = true
		continue_button.disabled = false
		continue_button.grab_focus()
		return
	_char_index += 1
	story_label.text = STORY_TEXT.substr(0, _char_index)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire") or event.is_action_pressed("ui_accept"):
		if not _is_complete:
			_finish_typewriter()
		else:
			_on_continue_pressed()
		get_viewport().set_input_as_handled()


func _finish_typewriter() -> void:
	_typewriter_timer.stop()
	_is_complete = true
	story_label.text = STORY_TEXT
	_char_index = STORY_TEXT.length()
	continue_button.disabled = false
	continue_button.grab_focus()


func _on_continue_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_skip_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	get_tree().change_scene_to_file(GAME_SCENE)
