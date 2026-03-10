## DemoEndScreen — shown when the player finishes all waves of the demo.
##
## Displays the final score, a thank-you message, and a call to action
## to wishlist or follow the game's development.
class_name DemoEndScreen
extends Control

const GAME_SCENE: String = "res://scenes/levels/test_level.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var score_label: Label = $Center/Panel/Margin/VBox/StatsBox/ScoreLabel
@onready var waves_label: Label = $Center/Panel/Margin/VBox/StatsBox/WavesLabel
@onready var play_again_button: Button = $Center/Panel/Margin/VBox/Buttons/PlayAgainButton
@onready var main_menu_button: Button = $Center/Panel/Margin/VBox/Buttons/MainMenuButton


func _ready() -> void:
	GameStateManager.change_state(GameStateManager.State.DEMO_END)
	AudioManager.play_music("victory_theme")

	score_label.text = "SCORE  //  %d" % GameStateManager.final_score
	waves_label.text = "WAVES CLEARED  //  %d" % GameStateManager.final_waves_survived

	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	play_again_button.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	main_menu_button.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	play_again_button.focus_entered.connect(func() -> void: AudioManager.play_ui("button_select"))
	main_menu_button.focus_entered.connect(func() -> void: AudioManager.play_ui("button_select"))

	play_again_button.grab_focus()


func _on_play_again_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_main_menu_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	GameStateManager.change_state(GameStateManager.State.MAIN_MENU)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
