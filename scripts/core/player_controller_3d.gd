## First-person controller for corridor-combat prototype.
class_name PlayerController3D
extends CharacterBody3D

signal fired

@export var move_speed: float = 7.5
@export var mouse_sensitivity: float = 0.0025
@export var acceleration: float = 14.0
@export var gravity: float = 18.0
@export var look_limit_radians: float = deg_to_rad(80.0)
@export var weapon_range: float = 40.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var muzzle_flash: OmniLight3D = $Head/WeaponPivot/MuzzleFlash
@onready var hit_scan: RayCast3D = $Head/Camera3D/HitScan

var _target_velocity: Vector3 = Vector3.ZERO
var _pitch: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	muzzle_flash.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var mode := Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
		return

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			_rotate_camera(event.relative)
			return
		if event.is_action_pressed("fire"):
			_fire_weapon()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward := -transform.basis.z
	var right := transform.basis.x
	# Input.get_vector returns -1 for "move_up" and +1 for "move_down",
	# so invert Y to keep W = forward and S = backward.
	_target_velocity = (forward * -input_vector.y + right * input_vector.x) * move_speed

	velocity.x = move_toward(velocity.x, _target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, _target_velocity.z, acceleration * delta)
	velocity.y -= gravity * delta

	move_and_slide()


func _rotate_camera(mouse_delta: Vector2) -> void:
	rotate_y(-mouse_delta.x * mouse_sensitivity)
	_pitch = clamp(_pitch - mouse_delta.y * mouse_sensitivity, -look_limit_radians, look_limit_radians)
	head.rotation.x = _pitch


func _fire_weapon() -> void:
	fired.emit()
	muzzle_flash.visible = true
	muzzle_flash.light_energy = 2.0

	hit_scan.force_raycast_update()
	if hit_scan.is_colliding():
		var collider := hit_scan.get_collider()
		if collider != null and collider.has_method("apply_damage"):
			collider.apply_damage(20.0)

	var tween := create_tween()
	tween.tween_property(muzzle_flash, "light_energy", 0.0, 0.08)
	tween.finished.connect(func() -> void: muzzle_flash.visible = false)
