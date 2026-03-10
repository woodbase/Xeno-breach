## WeaponData — Resource that defines a weapon's complete configuration.
##
## Create instances via [code]WeaponData.new()[/code] or the Godot inspector.
## Assign to [BaseWeapon] at runtime to hot-swap weapon loadouts.
class_name WeaponData
extends Resource

@export_group("Basic Info")
@export var weapon_name: String = "Basic Blaster"
@export var weapon_description: String = "Standard issue energy weapon"

@export_group("Fire Rate")
@export var fire_rate: float = 0.2
@export var firing_mode: BaseWeapon.FiringMode = BaseWeapon.FiringMode.AUTO
@export var burst_count: int = 3
@export var burst_delay: float = 0.1

@export_group("Damage")
@export var damage: float = 10.0
@export var attack_type: BaseWeapon.AttackType = BaseWeapon.AttackType.PROJECTILE

@export_group("Projectile Settings")
@export var projectile_speed: float = 600.0
@export var projectile_lifetime: float = 2.0
@export var projectile_scene: PackedScene
@export var impact_effect_scene: PackedScene
@export var muzzle_offset: Vector2 = Vector2(32.0, 0.0)

@export_group("Hitscan Settings")
@export var hitscan_range: float = 1000.0
@export var hitscan_pierce_count: int = 0

@export_group("Ammo System")
@export var max_ammo: int = 30
@export var infinite_ammo: bool = false
@export var reload_time: float = 2.0

@export_group("Recoil")
## Rotation kick applied to the weapon per shot, in degrees.
@export var recoil_amount: float = 5.0
## How quickly (degrees per second) the recoil returns to rest.
@export var recoil_recovery_speed: float = 120.0


## Apply this weapon data to a BaseWeapon instance.
func apply_to_weapon(weapon: BaseWeapon) -> void:
	if weapon == null:
		return

	weapon.fire_rate = fire_rate
	weapon.firing_mode = firing_mode
	weapon.burst_count = burst_count
	weapon.burst_delay = burst_delay
	weapon.damage = damage
	weapon.attack_type = attack_type
	weapon.projectile_scene = projectile_scene
	weapon.impact_effect_scene = impact_effect_scene
	weapon.muzzle_offset = muzzle_offset
	weapon.hitscan_range = hitscan_range
	weapon.hitscan_pierce_count = hitscan_pierce_count
	weapon.max_ammo = max_ammo
	weapon.infinite_ammo = infinite_ammo
	weapon.reload_time = reload_time
	weapon.recoil_amount = recoil_amount
	weapon.recoil_recovery_speed = recoil_recovery_speed
	weapon.current_ammo = max_ammo

