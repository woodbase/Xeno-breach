## EnemyBase — CharacterBody2D with a three-state AI (Idle / Chase / Attack).
##
## Assign a target via [method set_target] after spawning (done by [WaveSpawner]).
## Health is managed by the required [HealthComponent] child node.
## Connect to [signal died] to respond to enemy death (e.g., for scoring or wave counting).
class_name EnemyBase
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK }

## Emitted when the enemy's health reaches zero, just before [method queue_free].
signal died
signal state_changed(new_state: State, old_state: State)

@export var move_speed: float = 120.0
@export var detection_range: float = 300.0
@export var attack_range: float = 50.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 350.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var _body: CanvasItem = $Body
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _current_state: State = State.IDLE
var _target: Node2D = null
var _attack_timer: float = 0.0
var _hit_flash_timer: Timer
var _base_modulate: Color = Color.WHITE
var _flash_color: Color = Color(1.8, 1.8, 1.8, 1.0)
var _is_dying: bool = false


func _ready() -> void:
	health_component.died.connect(_on_health_died)
	health_component.damaged.connect(_on_health_damaged)
	_init_hit_flash()


func _physics_process(delta: float) -> void:
	if _is_dying:
		velocity = Vector2.ZERO
		return
	_update_state()
	_process_state(delta)
	move_and_slide()


func _update_state() -> void:
	var old_state: State = _current_state
	if _target == null:
		_current_state = State.IDLE
	else:
		var dist: float = global_position.distance_to(_target.global_position)
		if dist <= attack_range:
			_current_state = State.ATTACK
		elif dist <= detection_range:
			_current_state = State.CHASE
		else:
			_current_state = State.IDLE
	if old_state != _current_state:
		state_changed.emit(_current_state, old_state)


func _process_state(delta: float) -> void:
	match _current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta * 10.0)
		State.CHASE:
			var dir: Vector2 = (_target.global_position - global_position).normalized()
			velocity = dir * move_speed
			look_at(_target.global_position)
		State.ATTACK:
			velocity = Vector2.ZERO
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_do_attack()
				_attack_timer = attack_cooldown


## Assign the node this enemy will pursue and attack.
func set_target(target: Node2D) -> void:
	_target = target


func _do_attack() -> void:
	if _target == null:
		return
	if projectile_scene != null:
		_fire_projectile()
		return
	var health: HealthComponent = _target.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.take_damage(damage)


func _fire_projectile() -> void:
	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_warning("EnemyBase: projectile_scene root is not a Projectile.")
		return
	var direction: Vector2 = (_target.global_position - global_position).normalized()
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.damage = damage
	projectile.source_body = self
	var level: Node = get_tree().current_scene
	if level != null:
		level.add_child(projectile)


func _on_health_died() -> void:
	if _is_dying:
		return
	_is_dying = true
	SoundManager.play_sfx("enemy_die")
	died.emit()
	velocity = Vector2.ZERO
	if _collision_shape != null:
		_collision_shape.disabled = true
	set_collision_layer(0)
	set_collision_mask(0)
	var fade_duration: float = 0.3
	if _body != null:
		var tween: Tween = create_tween()
		tween.tween_property(_body, "modulate:a", 0.0, fade_duration)
		await tween.finished
	else:
		await get_tree().create_timer(fade_duration).timeout
	queue_free()


func play_hit_flash() -> void:
	if _body == null or _hit_flash_timer == null:
		return
	_body.modulate = _flash_color
	_hit_flash_timer.start()


func _init_hit_flash() -> void:
	_base_modulate = _body.modulate
	_hit_flash_timer = Timer.new()
	_hit_flash_timer.one_shot = true
	_hit_flash_timer.wait_time = 0.1
	_hit_flash_timer.timeout.connect(_on_hit_flash_timeout)
	add_child(_hit_flash_timer)


func _on_hit_flash_timeout() -> void:
	if _body != null:
		_body.modulate = _base_modulate


func _on_health_damaged(_amount: float) -> void:
	if _is_dying:
		return
	play_hit_flash()
