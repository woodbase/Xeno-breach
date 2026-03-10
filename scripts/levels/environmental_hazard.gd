## EnvironmentalHazard — Area2D that applies periodic damage to overlapping bodies.
##
## Intended for environmental threats such as radiation leaks, fire, or toxic pools.
## Attach a CollisionShape2D to define the hazard bounds.
class_name EnvironmentalHazard
extends Area2D

@export var hazard_name: String = "Hazard"
@export var damage_per_second: float = 12.0
@export_range(0.1, 5.0, 0.05) var tick_interval: float = 0.5
@export var affects_players: bool = true
@export var affects_enemies: bool = false

var _bodies: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var to_remove: Array = []
	for body in _bodies.keys():
		if not is_instance_valid(body):
			to_remove.append(body)
			continue
		var timer: float = float(_bodies[body]) - delta
		if timer <= 0.0:
			_apply_damage(body)
			timer = tick_interval
		_bodies[body] = timer
	for body in to_remove:
		_bodies.erase(body)


func _on_body_entered(body: Node) -> void:
	if not _can_affect(body):
		return
	_bodies[body] = 0.0


func _on_body_exited(body: Node) -> void:
	_bodies.erase(body)


func _can_affect(body: Node) -> bool:
	if affects_players and body.is_in_group("player"):
		return true
	if affects_enemies and body is EnemyBase:
		return true
	return false


func _apply_damage(body: Node) -> void:
	var damage: float = damage_per_second * tick_interval
	var health: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.take_damage(damage)
		return
	if "take_damage" in body:
		body.call("take_damage", damage)
