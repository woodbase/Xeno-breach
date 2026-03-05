extends Node3D

@onready var status_label: Label = $HUD/Control/VBox/Status
@onready var enemies_root: Node3D = $Enemies


func _ready() -> void:
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_status()


func _process(_delta: float) -> void:
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _update_status() -> void:
	status_label.text = "Kvarvarande vakter: %d" % enemies_root.get_child_count()
