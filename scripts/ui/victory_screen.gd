## VictoryScreen — shown when the player completes a level and there is a next
## level to proceed to.
##
## Displays the score achieved so far and waves survived, then lets the player
## continue to the next level or return to the main menu.
class_name VictoryScreen
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var score_label: Label = $Center/Panel/Margin/VBox/StatsBox/ScoreLabel
@onready var waves_label: Label = $Center/Panel/Margin/VBox/StatsBox/WavesLabel
@onready var continue_button: Button = $Center/Panel/Margin/VBox/Buttons/ContinueButton
@onready var main_menu_button: Button = $Center/Panel/Margin/VBox/Buttons/MainMenuButton


func _ready() -> void:
	GameStateManager.change_state(GameStateManager.State.VICTORY)
	AudioManager.play_music("victory_theme")

	score_label.text = "SCORE  //  %d" % GameStateManager.final_score
	waves_label.text = "WAVES CLEARED  //  %d" % GameStateManager.final_waves_survived

	continue_button.pressed.connect(_on_continue_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	continue_button.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	main_menu_button.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	continue_button.focus_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	main_menu_button.focus_entered.connect(func() -> void: AudioManager.play_ui("button_select"))

	continue_button.grab_focus()


func _on_continue_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	var next_path: String = GameStateManager.next_level_scene_path
	GameStateManager.next_level_scene_path = ""
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	get_tree().change_scene_to_file(next_path)


func _on_main_menu_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	GameStateManager.next_level_scene_path = ""
	GameStateManager.change_state(GameStateManager.State.MAIN_MENU)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
