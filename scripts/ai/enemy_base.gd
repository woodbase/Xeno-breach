## EnemyBase — CharacterBody2D with a three-state AI (Idle / Chase / Attack).
##
## Assign a target via [method set_target] after spawning (done by [WaveSpawner]).
## Health is managed by the required [HealthComponent] child node.
## Connect to [signal died] to respond to enemy death (e.g., for scoring or wave counting).
class_name EnemyBase
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, PATROL }

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
## Enable patrol behaviour. The enemy will move back and forth between two
## automatically-generated waypoints centered on its spawn position.
@export var patrol_enabled: bool = false
## Half-width of the patrol route. The enemy patrols patrol_radius units to
## each side of its spawn position along the X-axis.
@export var patrol_radius: float = 80.0
## Optional data resource. When assigned, stats are loaded from it on [method _ready],
## overriding the individual export properties above.
@export var data: EnemyData
@export_group("Feedback")
@export var hit_stun_duration: float = 0.12
@export var hit_effect_scene: PackedScene = preload("res://scenes/weapons/impact_effect.tscn")

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
var _patrol_points: Array[Vector2] = []
var _patrol_index: int = 0
var _spawn_position: Vector2
## Cached squared values of [member attack_range] and [member detection_range] to avoid
## repeated sqrt calls in [method _update_state]. Refreshed by [method _cache_range_sq].
var _attack_range_sq: float = 0.0
var _detection_range_sq: float = 0.0
## Countdown until the next [method _update_state] tick (seconds).
var _state_timer: float = 0.0
## Cooldown preventing repeated scene-tree searches in [method _ensure_target] (seconds).
var _target_search_cooldown: float = 0.0
const _PATROL_THRESHOLD: float = 10.0
## Squared patrol threshold; kept in sync with _PATROL_THRESHOLD (10² = 100).
const _PATROL_THRESHOLD_SQ: float = 100.0
const _PATROL_SPEED_RATIO: float = 0.5
## How often (in seconds) each enemy re-evaluates its state machine.
## Enemies are staggered by a random offset on [method _ready] to spread CPU cost.
const _STATE_UPDATE_INTERVAL: float = 0.1
## Minimum gap (seconds) between scene-tree player searches in [method _ensure_target].
const _TARGET_SEARCH_INTERVAL: float = 0.5
var _hit_stun_timer: float = 0.0


func _ready() -> void:
	_apply_data()
	health_component.died.connect(_on_health_died)
	health_component.damaged.connect(_on_health_damaged)
	_init_hit_flash()
	_init_patrol()
	# Stagger first state evaluation so enemies spawned together don't all
	# update on the same physics frame, which would cause a CPU spike.
	_state_timer = randf_range(0.0, _STATE_UPDATE_INTERVAL)


## Apply [member data] stats to this enemy's exported properties.
## Called automatically from [method _ready]; safe to call again after hot-swapping [member data].
func apply_data() -> void:
	_apply_data()


func _apply_data() -> void:
	if data == null:
		_cache_range_sq()
		return
	move_speed = data.move_speed
	detection_range = data.detection_range
	attack_range = data.attack_range
	damage = data.damage
	attack_cooldown = data.attack_cooldown
	patrol_enabled = data.patrol_enabled
	patrol_radius = data.patrol_radius
	if data.projectile_scene != null:
		projectile_scene = data.projectile_scene
	projectile_speed = data.projectile_speed
	if health_component != null:
		health_component.max_health = data.max_health
		health_component.current_health = data.max_health
	_cache_range_sq()


## Refresh the cached squared range values from the current [member attack_range]
## and [member detection_range] exports.  Called automatically by [method _apply_data]
## and whenever ranges are modified externally.
func _cache_range_sq() -> void:
	_attack_range_sq = attack_range * attack_range
	_detection_range_sq = detection_range * detection_range


func _physics_process(delta: float) -> void:
	if _is_dying:
		velocity = Vector2.ZERO
		return
	if _hit_stun_timer > 0.0:
		_hit_stun_timer = maxf(0.0, _hit_stun_timer - delta)
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 6.0 * delta)
		move_and_slide()
		return
	# Decrement per-enemy cooldowns each physics frame.
	if _target_search_cooldown > 0.0:
		_target_search_cooldown -= delta
	# Throttle state-machine evaluation to _STATE_UPDATE_INTERVAL seconds.
	# Movement (move_and_slide) still runs every frame for smooth physics.
	_state_timer -= delta
	if _state_timer <= 0.0:
		_state_timer = _STATE_UPDATE_INTERVAL
		_update_state()
	_process_state(delta)
	move_and_slide()


func _update_state() -> void:
	_ensure_target()
	var old_state: State = _current_state
	if _target == null or not is_instance_valid(_target):
		_target = null
		_current_state = State.PATROL if patrol_enabled else State.IDLE
	else:
		# Use squared distance to avoid a sqrt on every state-update tick.
		var dist_sq: float = global_position.distance_squared_to(_target.global_position)
		if dist_sq <= _attack_range_sq:
			_current_state = State.ATTACK
		elif dist_sq <= _detection_range_sq:
			_current_state = State.CHASE
		else:
			_current_state = State.PATROL if patrol_enabled else State.IDLE
	if old_state != _current_state:
		state_changed.emit(_current_state, old_state)
		# Play alert sound when the enemy first spots the player
		if _current_state == State.CHASE and old_state in [State.IDLE, State.PATROL]:
			AudioManager.play_sfx("enemy_alert", global_position)


func _process_state(delta: float) -> void:
	match _current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta * 10.0)
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			# Guard against target becoming invalid between throttled state updates.
			if _target == null or not is_instance_valid(_target):
				velocity = Vector2.ZERO
			else:
				var dir: Vector2 = (_target.global_position - global_position).normalized()
				velocity = dir * move_speed
				look_at(_target.global_position)
		State.ATTACK:
			velocity = Vector2.ZERO
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_do_attack()
				_attack_timer = attack_cooldown


func _ensure_target() -> void:
	if _target != null and is_instance_valid(_target):
		return
	# Rate-limit scene-tree searches so only one enemy performs the lookup per
	# _TARGET_SEARCH_INTERVAL seconds (per enemy), preventing O(n) tree scans
	# on every state-update tick when the player is temporarily absent.
	if _target_search_cooldown > 0.0:
		return
	_target_search_cooldown = _TARGET_SEARCH_INTERVAL
	var candidate: Node = get_tree().get_first_node_in_group("player")
	var node := candidate as Node2D
	_target = node


## Assign the node this enemy will pursue and attack.
func set_target(target: Node2D) -> void:
	_target = target


func _do_attack() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	AudioManager.play_sfx("enemy_attack", global_position)
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
	AudioManager.play_sfx("enemy_death", global_position)
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
	_hit_stun_timer = hit_stun_duration
	_spawn_hit_effect()
	play_hit_flash()


## Initialize patrol waypoints centered on the spawn position.
## Called automatically from [method _ready]; early-returns when patrol is disabled or [member patrol_radius] <= 0.0.
func _init_patrol() -> void:
	_spawn_position = global_position
	if not patrol_enabled or patrol_radius <= 0.0:
		_patrol_points.clear()
		_patrol_index = 0
		return
	_patrol_points = [
		_spawn_position + Vector2(patrol_radius, 0.0),
		_spawn_position - Vector2(patrol_radius, 0.0),
	]
	_patrol_index = 0


func _process_patrol(delta: float) -> void:
	if _patrol_points.is_empty():
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta * 10.0)
		return
	var waypoint: Vector2 = _patrol_points[_patrol_index]
	# Use squared distance to avoid sqrt for the waypoint-threshold check.
	if global_position.distance_squared_to(waypoint) <= _PATROL_THRESHOLD_SQ:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		waypoint = _patrol_points[_patrol_index]
	var dir: Vector2 = (waypoint - global_position).normalized()
	velocity = dir * move_speed * _PATROL_SPEED_RATIO
	if dir != Vector2.ZERO:
		look_at(waypoint)


func _spawn_hit_effect() -> void:
	if hit_effect_scene == null:
		return
	var level: Node = get_tree().current_scene
	if level == null:
		return
	var effect: Node2D = hit_effect_scene.instantiate() as Node2D
	if effect == null:
		return
	effect.global_position = global_position
	level.add_child(effect)
