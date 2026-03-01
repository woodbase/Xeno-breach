## Projectile — fast-moving Area2D that applies damage on contact.
##
## Set [member direction], [member damage], and [member source_body] before adding to the scene.
## The projectile auto-despawns after [member lifetime] seconds or on first collision.
##
## Damage is applied via the target's [HealthComponent] child node, keeping the system
## decoupled from specific enemy or player class types.
class_name Projectile
extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0
@export var lifetime: float = 2.0

## Movement direction — should be normalised. Set by [BaseWeapon] before spawning.
var direction: Vector2 = Vector2.RIGHT

## The entity that fired this projectile. Used to prevent self-damage.
var source_body: Node2D = null

var _lifetime_timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_lifetime_timer = lifetime


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime_timer -= delta
	if _lifetime_timer <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == source_body:
		return
	var health: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.take_damage(damage)
	queue_free()
