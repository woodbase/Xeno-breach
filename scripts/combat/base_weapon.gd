## BaseWeapon — fires [Projectile] instances from a muzzle position.
##
## Assign [member projectile_scene] in the inspector to a [Projectile]-based PackedScene.
## Call [method fire] with a normalised direction vector to spawn a projectile.
class_name BaseWeapon
extends Node2D

@export var fire_rate: float = 0.2
@export var damage: float = 10.0
@export var projectile_scene: PackedScene
@export var muzzle_offset: Vector2 = Vector2(32.0, 0.0)


## Fire a projectile in [param direction]. Direction should be normalised.
func fire(direction: Vector2) -> void:
	if projectile_scene == null:
		push_warning("BaseWeapon: projectile_scene is not assigned.")
		return

	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_warning("BaseWeapon: projectile_scene root is not a Projectile node.")
		return

	projectile.global_position = global_position + muzzle_offset.rotated(global_rotation)
	projectile.direction = direction
	projectile.damage = damage
	projectile.source_body = get_parent() as Node2D

	var level: Node = get_tree().current_scene
	if level != null:
		level.add_child(projectile)
