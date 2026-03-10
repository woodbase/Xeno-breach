## PlayerController — acceleration-based twin-stick movement with weapon firing.
##
## Requires a [HealthComponent] child node named "HealthComponent".
## Optionally supports [WeaponManager] for multiple weapons, or a single [BaseWeapon].
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

## NodePath to the [WeaponManager] or [BaseWeapon] child. Set in the inspector.
@export var weapon_path: NodePath = NodePath("WeaponMount")

## Input device index for local co-op. -1 = keyboard + mouse (player 1); 0+ = gamepad slot.
@export var device_id: int = -1

@onready var health_component: HealthComponent = $HealthComponent

var _weapon_manager: WeaponManager = null
var _weapon: BaseWeapon = null
var _fire_cooldown: float = 0.0
var _normalized_bounds: Rect2
var _damage_feedback_duration: float = 0.25
var _damage_feedback_timer: SceneTreeTimer = null
var _damage_overlay: ColorRect = null


func _ready() -> void:
	_normalized_bounds = playfield_bounds.abs()
	add_to_group("player")
	health_component.damaged.connect(func(amount: float) -> void:
		damaged.emit(amount)
		play_damage_feedback(amount)
		AudioManager.play_sfx("player_hurt", global_position)
	)
	health_component.died.connect(_on_health_died)
	health_component.invulnerability_changed.connect(_on_invulnerability_changed)

	# Support both WeaponManager and direct BaseWeapon
	if not weapon_path.is_empty():
		var node := get_node_or_null(weapon_path)
		if node is WeaponManager:
			_weapon_manager = node as WeaponManager
			_weapon = _weapon_manager.get_active_weapon()
		elif node is BaseWeapon:
			_weapon = node as BaseWeapon

	_damage_overlay = get_tree().root.find_child("DamageOverlay", true, false) as ColorRect


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_aim()
	_handle_weapon_switching()
	_handle_reload()
	_handle_fire(delta)
	move_and_slide()
	if clamp_to_playfield:
		global_position = global_position.clamp(_normalized_bounds.position, _normalized_bounds.end)


func _handle_movement(delta: float) -> void:
	var input_dir: Vector2
	if device_id < 0:
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		input_dir = Vector2(
			Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
		)
		if input_dir.length() < 0.2:
			input_dir = Vector2.ZERO
		input_dir = input_dir.limit_length(1.0)
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func _handle_aim() -> void:
	if device_id < 0:
		look_at(get_global_mouse_position())
	else:
		var aim := Vector2(
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
		)
		if aim.length() > 0.2:
			rotation = aim.angle()


func _handle_fire(delta: float) -> void:
	_fire_cooldown -= delta
	var should_fire: bool
	if device_id < 0:
		should_fire = Input.is_action_pressed("fire")
	else:
		should_fire = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.5

	if should_fire and _fire_cooldown <= 0.0:
		_fire(should_fire)


func _handle_weapon_switching() -> void:
	if _weapon_manager == null:
		return

	if device_id < 0:
		# Mouse wheel for weapon switching
		if Input.is_action_just_pressed("weapon_next"):
			_weapon_manager.next_weapon()
			_weapon = _weapon_manager.get_active_weapon()
		elif Input.is_action_just_pressed("weapon_prev"):
			_weapon_manager.prev_weapon()
			_weapon = _weapon_manager.get_active_weapon()
	else:
		# D-pad for gamepad weapon switching
		if Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_RIGHT):
			_weapon_manager.next_weapon()
			_weapon = _weapon_manager.get_active_weapon()
		elif Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_LEFT):
			_weapon_manager.prev_weapon()
			_weapon = _weapon_manager.get_active_weapon()


func _handle_reload() -> void:
	var should_reload: bool
	if device_id < 0:
		should_reload = Input.is_action_just_pressed("reload")
	else:
		should_reload = Input.is_joy_button_pressed(device_id, JOY_BUTTON_X)

	if should_reload:
		if _weapon_manager != null:
			_weapon_manager.reload()
		elif _weapon != null:
			_weapon.reload()


func _fire(trigger_held: bool) -> void:
	if _weapon == null:
		return

	var direction: Vector2 = Vector2.RIGHT.rotated(rotation)
	var did_fire: bool = false

	if _weapon_manager != null:
		did_fire = _weapon_manager.try_fire(direction, trigger_held)
	else:
		did_fire = _weapon.try_fire(direction, trigger_held)

	if did_fire:
		fired.emit(direction)
		var effective_fire_rate := _weapon.get_effective_fire_rate() if _weapon != null else 0.2
		_fire_cooldown = effective_fire_rate


## Delegate incoming damage to the HealthComponent.
func take_damage(amount: float) -> void:
	health_component.take_damage(amount)


## Briefly flash the damage overlay red to give visual hit feedback.
func play_damage_feedback(amount: float = 10.0) -> void:
	if _damage_overlay == null:
		_damage_overlay = get_tree().root.find_child("DamageOverlay", true, false) as ColorRect
	if _damage_overlay == null:
		return
	var max_health := maxf(1.0, health_component.max_health)
	var alpha := clampf(amount / max_health * 1.5, 0.5, 0.8)
	_damage_overlay.color = Color(1.0, 0.0, 0.0, alpha)
	var timer := get_tree().create_timer(_damage_feedback_duration)
	_damage_feedback_timer = timer
	await timer.timeout
	if _damage_feedback_timer == timer and is_instance_valid(_damage_overlay):
		_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)


## Assign a new weapon at runtime.
func set_weapon(weapon: BaseWeapon) -> void:
	_weapon = weapon


func _on_health_died() -> void:
	set_physics_process(false)
	if is_instance_valid(_damage_overlay):
		_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	_damage_feedback_timer = null
	died.emit()


func _on_invulnerability_changed(active: bool) -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.45) if active else Color(1.0, 1.0, 1.0, 1.0)
