## EnemyData — Resource that defines an enemy type's configuration.
##
## Create instances via the Godot inspector or [code]EnemyData.new()[/code].
## Assign to [member EnemyBase.data] to apply all stats at runtime.
## Used by [WaveSpawner] or [EnemyBase] to initialise per-type stats.
class_name EnemyData
extends Resource

@export var enemy_name: String = "Drone"
@export var max_health: float = 50.0
@export var move_speed: float = 120.0
@export var detection_range: float = 300.0
@export var attack_range: float = 50.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var patrol_enabled: bool = false
@export var patrol_radius: float = 80.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 350.0
