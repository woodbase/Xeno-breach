## Projectile — fast-moving Area2D that applies damage on contact.
##
## Set [member direction], [member damage], and [member source_body] before adding to the scene.
## The projectile auto-despawns after [member lifetime] seconds or on first collision.
##
## Damage is applied via the target's [HealthComponent] child node, keeping the system
## decoupled from specific enemy or player class types.
##
## Visual feedback:
## - A [Line2D] child named "Tracer" renders a lightweight motion tail.
## - An [ImpactEffect] scene is spawned at the projectile's position on hit.
class_name Projectile
extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0
@export var lifetime: float = 2.0

## PackedScene for the impact effect. Assign in the inspector or leave null to skip.
@export var impact_effect_scene: PackedScene

## Movement direction — should be normalised. Set by [BaseWeapon] before spawning.
var direction: Vector2 = Vector2.RIGHT

## The entity that fired this projectile. Used to prevent self-damage.
var source_body: Node2D = null

var _lifetime_timer: float = 0.0
var _tracer: Line2D = null
var _is_despawning: bool = false

## Length of the motion tracer in pixels.
const TRACER_LENGTH: float = 20.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_lifetime_timer = lifetime
	_tracer = get_node_or_null("Tracer") as Line2D
	if _tracer != null:
		_tracer.set_point_position(0, -direction * TRACER_LENGTH)
		_tracer.set_point_position(1, Vector2.ZERO)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime_timer -= delta
	if _lifetime_timer <= 0.0:
		_despawn()


func _on_body_entered(body: Node) -> void:
	if _is_despawning:
		return
	if body == source_body:
		return
	var health: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.take_damage(damage)
		AudioManager.play_sfx("impact_body", global_position)
	else:
		AudioManager.play_sfx("impact_wall", global_position)
	_spawn_impact()
	_despawn()


func _spawn_impact() -> void:
	if impact_effect_scene == null:
		return
	var level: Node = get_tree().current_scene
	if level == null:
		return
	var effect: Node2D = impact_effect_scene.instantiate() as Node2D
	if effect == null:
		return
	effect.global_position = global_position
	level.add_child(effect)


func _despawn() -> void:
	_is_despawning = true
	if _tracer != null:
		_tracer.clear_points()
	queue_free()
