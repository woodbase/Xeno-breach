## WeaponData — Resource that defines a weapon's configuration.
##
## Create instances via [code]WeaponData.new()[/code] or the Godot inspector.
## Assign to [BaseWeapon] at runtime to hot-swap weapon loadouts.
class_name WeaponData
extends Resource

@export var weapon_name: String = "Basic Blaster"
@export var fire_rate: float = 0.2
@export var damage: float = 10.0
@export var projectile_speed: float = 600.0
@export var projectile_lifetime: float = 2.0
@export var muzzle_offset: Vector2 = Vector2(32.0, 0.0)
