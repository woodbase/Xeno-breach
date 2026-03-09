## FPSPlayerController — first-person 3D player controller.
##
## Requires a [HealthComponent] child node named "HealthComponent".
## Requires a [Camera3D] child node named "Camera3D" positioned at head height.
##
## Input actions used: move_left, move_right, move_up, move_down, sprint, jump.
class_name FPSPlayerController
extends CharacterBody3D

## Re-emitted from HealthComponent for external listeners.
signal damaged(amount: float)

## Re-emitted from HealthComponent for external listeners.
signal died

## Walking speed in m/s.
@export var walk_speed: float = 5.0

## Running speed in m/s, applied while the sprint action is held.
@export var sprint_speed: float = 9.0

## Initial vertical velocity applied on jump.
@export var jump_velocity: float = 4.5

## Mouse sensitivity in radians per pixel of cursor movement.
@export var mouse_sensitivity: float = 0.002

## Minimum (most downward) camera pitch in radians.
@export var pitch_min: float = -1.5

## Maximum (most upward) camera pitch in radians.
@export var pitch_max: float = 1.5

## When true, the mouse cursor is captured on [method _ready]. Set to false
## when instancing the player outside of active gameplay (e.g. tests, menus).
@export var capture_mouse: bool = true

@onready var health_component: HealthComponent = $HealthComponent
@onready var camera: Camera3D = $Camera3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _damage_feedback_duration: float = 0.2
var _damage_feedback_timer: SceneTreeTimer = null
var _damage_overlay: ColorRect = null


func _ready() -> void:
	if capture_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	health_component.damaged.connect(func(amount: float) -> void:
		damaged.emit(amount)
		_play_damage_feedback()
	)
	health_component.died.connect(_on_health_died)
	_damage_overlay = get_tree().root.find_child("DamageOverlay", true, false) as ColorRect


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_look(event as InputEventMouseMotion)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	move_and_slide()


## Rotate the body (yaw) and camera (pitch) based on mouse movement.
func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * mouse_sensitivity)
	camera.rotate_x(-event.relative.y * mouse_sensitivity)
	camera.rotation.x = clampf(camera.rotation.x, pitch_min, pitch_max)


## Apply gravity when airborne.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


## Apply jump impulse when the player is on the floor.
func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


## Handle WASD movement, with optional sprint.
func _handle_movement(delta: float) -> void:
	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Map 2-D input to 3-D direction relative to the player's facing (yaw only).
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta)


## Delegate incoming damage to the HealthComponent.
func take_damage(amount: float) -> void:
	health_component.take_damage(amount)


## Briefly flash the damage overlay red to give visual hit feedback.
func _play_damage_feedback() -> void:
	if _damage_overlay == null:
		return
	_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.5)
	var timer := get_tree().create_timer(_damage_feedback_duration)
	_damage_feedback_timer = timer
	await timer.timeout
	if _damage_feedback_timer == timer and is_instance_valid(_damage_overlay):
		_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)


## Freeze the player in place on death and emit [signal died].
func _on_health_died() -> void:
	set_physics_process(false)
	set_process_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_instance_valid(_damage_overlay):
		_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	_damage_feedback_timer = null
	died.emit()
