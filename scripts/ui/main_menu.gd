## MainMenu — simple front-door flow to start or quit the game.
class_name MainMenu
extends Control

@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Center/Panel/Margin/VBox/SubTitle
@onready var start_button: Button = $Center/Panel/Margin/VBox/Buttons/StartButton
@onready var quit_button: Button = $Center/Panel/Margin/VBox/Buttons/QuitButton


func _ready() -> void:
	GameStateManager.change_state(GameStateManager.State.MAIN_MENU)
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()
	title_label.text = "Xeno Breach"
	subtitle_label.text = "Twin-stick survival prototype"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire") or event.is_action_pressed("ui_accept"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
