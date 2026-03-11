## PauseMenu — overlay panel shown when the player pauses the game.
##
## Add this as a child of the HUD CanvasLayer.  Call [method open] to display
## and [method close] to dismiss.  The node runs with
## [constant Node.PROCESS_MODE_WHEN_PAUSED] so it stays interactive while
## the scene tree is paused.
class_name PauseMenu
extends Control

signal resume_pressed
signal restart_pressed
signal main_menu_pressed
signal quit_pressed

@onready var resume_button: Button = $Center/Panel/Margin/VBox/Buttons/ResumeButton
@onready var restart_button: Button = $Center/Panel/Margin/VBox/Buttons/RestartButton
@onready var main_menu_button: Button = $Center/Panel/Margin/VBox/Buttons/MainMenuButton
@onready var quit_button: Button = $Center/Panel/Margin/VBox/Buttons/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	for btn: Button in [resume_button, restart_button, main_menu_button, quit_button]:
		btn.mouse_entered.connect(_play_hover_sound)
		btn.focus_entered.connect(_play_hover_sound)


func _play_hover_sound() -> void:
	AudioManager.play_ui("button_select")


## Show the pause menu and focus the Resume button.
func open() -> void:
	visible = true
	resume_button.grab_focus()


## Hide the pause menu.
func close() -> void:
	visible = false


func _on_resume_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	resume_pressed.emit()


func _on_restart_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	restart_pressed.emit()


func _on_main_menu_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	main_menu_pressed.emit()


func _on_quit_pressed() -> void:
	AudioManager.play_ui("button_confirm")
	quit_pressed.emit()
