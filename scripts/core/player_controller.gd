## PlayerController — acceleration-based twin-stick movement with weapon firing.
##
## Requires a [HealthComponent] child node named "HealthComponent".
## Set [member weapon_path] in the inspector to point to a [BaseWeapon] child.
class_name PlayerController
extends CharacterBody2D

## Emitted when the player fires. Carries the normalised fire direction.
signal fired(direction: Vector2)

## Re-emitted from HealthComponent for external listeners.
signal damaged(amount: float)

## Re-emitted from HealthComponent for external listeners.
signal died

@export var move_speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var clamp_to_playfield: bool = true
@export var playfield_bounds: Rect2 = Rect2(Vector2(-620.0, -340.0), Vector2(1240.0, 680.0))

## NodePath to the active [BaseWeapon] child. Set in the inspector.
@export var weapon_path: NodePath = NodePath("WeaponMount/BasicBlaster")

@onready var health_component: HealthComponent = $HealthComponent

var _weapon: BaseWeapon = null
var _fire_cooldown: float = 0.0
var _normalized_bounds: Rect2
var _damage_feedback_duration: float = 0.2
var _damage_feedback_timer: SceneTreeTimer = null
var _is_showing_damage_feedback: bool = false
var _damage_overlay: ColorRect = null


func _ready() -> void:
	_normalized_bounds = playfield_bounds.abs()
	health_component.damaged.connect(func(amount: float) -> void: damaged.emit(amount))
	health_component.died.connect(_on_health_died)
	health_component.invulnerability_changed.connect(_on_invulnerability_changed)
	if not weapon_path.is_empty():
		_weapon = get_node_or_null(weapon_path) as BaseWeapon
	_damage_overlay = get_tree().root.find_child("DamageOverlay", true, false) as ColorRect


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_aim()
	_handle_fire(delta)
	move_and_slide()
	if clamp_to_playfield:
		global_position = global_position.clamp(_normalized_bounds.position, _normalized_bounds.end)


func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func _handle_aim() -> void:
	look_at(get_global_mouse_position())


func _handle_fire(delta: float) -> void:
	_fire_cooldown -= delta
	if Input.is_action_pressed("fire") and _fire_cooldown <= 0.0:
		_fire()


func _fire() -> void:
	if _weapon == null:
		return
	var direction: Vector2 = Vector2.RIGHT.rotated(rotation)
	_weapon.fire(direction)
	fired.emit(direction)
	_fire_cooldown = _weapon.fire_rate


## Delegate incoming damage to the HealthComponent.
func take_damage(amount: float) -> void:
	health_component.take_damage(amount)
	play_damage_feedback()


## Briefly flash the damage overlay red to give visual hit feedback.
func play_damage_feedback() -> void:
	if _damage_overlay == null:
		return
	_is_showing_damage_feedback = true
	_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.5)
	var timer := get_tree().create_timer(_damage_feedback_duration)
	_damage_feedback_timer = timer
	await timer.timeout
	if _damage_feedback_timer == timer and is_instance_valid(_damage_overlay):
		_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
		_is_showing_damage_feedback = false


## Assign a new weapon at runtime.
func set_weapon(weapon: BaseWeapon) -> void:
	_weapon = weapon


func _on_health_died() -> void:
	set_physics_process(false)
	died.emit()


func _on_invulnerability_changed(active: bool) -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.45) if active else Color(1.0, 1.0, 1.0, 1.0)
