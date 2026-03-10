## Exit trigger for level completion. Activated once all waves are cleared.
class_name ExitTrigger
extends Area2D

signal player_extracted

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var indicator: Label = $Indicator

var _active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_active(false)


func set_active(enabled: bool) -> void:
	_active = enabled
	monitoring = enabled
	monitorable = enabled
	visible = enabled
	if collision_shape != null:
		collision_shape.disabled = not enabled
	if indicator != null:
		indicator.visible = enabled


func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body is PlayerController:
		player_extracted.emit()
