## EnemyProjectile — projectile preset for enemy attacks.
class_name EnemyProjectile
extends Projectile


func _ready() -> void:
	collision_layer = GameConstants.LAYER_ENEMY_PROJECTILES
	collision_mask = GameConstants.MASK_ENEMY_PROJECTILE
	super._ready()
