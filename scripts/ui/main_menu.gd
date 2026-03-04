## MainMenu — simple front-door flow to start or quit the game.
class_name MainMenu
extends Control

@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Center/Panel/Margin/VBox/SubTitle
@onready var start_button: Button = $Center/Panel/Margin/VBox/Buttons/StartButton
@onready var quit_button: Button = $Center/Panel/Margin/VBox/Buttons/QuitButton

var _player_count_buttons: Array[Button] = []


func _ready() -> void:
	GameStateManager.change_state(GameStateManager.State.MAIN_MENU)
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	title_label.text = "XENO BREACH // PROTOCOL"
	subtitle_label.text = "Industrial containment deployment // stay sharp"
	_setup_coop_selector()
	start_button.grab_focus()


func _setup_coop_selector() -> void:
	var buttons_container: VBoxContainer = start_button.get_parent() as VBoxContainer
	if buttons_container == null:
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "AGENTS:"
	label.add_theme_color_override("font_color", Color(0.847, 0.894, 0.929, 1))
	label.add_theme_font_size_override("font_size", 16)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	for i: int in range(1, CoopManager.MAX_PLAYERS + 1):
		var btn := Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(44, 0)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_player_count_selected.bind(i))
		row.add_child(btn)
		_player_count_buttons.append(btn)

	buttons_container.add_child(row)
	buttons_container.move_child(row, 0)
	_update_player_count_buttons()


func _on_player_count_selected(count: int) -> void:
	CoopManager.player_count = count
	_update_player_count_buttons()


func _update_player_count_buttons() -> void:
	for i: int in _player_count_buttons.size():
		_player_count_buttons[i].disabled = (i + 1 == CoopManager.player_count)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire") or event.is_action_pressed("ui_accept"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
