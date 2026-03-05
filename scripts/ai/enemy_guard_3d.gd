class_name EnemyGuard3D
extends CharacterBody3D

@export var move_speed: float = 2.4
@export var max_health: float = 40.0

@onready var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
@onready var body_mesh: MeshInstance3D = $Body

var _health: float = max_health


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() < 0.2:
		velocity = Vector3.ZERO
	else:
		velocity = to_player.normalized() * move_speed
	look_at(player.global_position, Vector3.UP)
	rotation.x = 0.0
	rotation.z = 0.0
	move_and_slide()


func apply_damage(amount: float) -> void:
	_health -= amount
	body_mesh.modulate = Color(1.0, 0.35, 0.35)
	var tween := create_tween()
	tween.tween_property(body_mesh, "modulate", Color(0.82, 0.88, 0.94), 0.12)
	if _health <= 0.0:
		queue_free()
