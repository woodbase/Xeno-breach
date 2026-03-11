## BaseWeapon — modular weapon system supporting projectiles, hitscan, ammo, reload, and firing modes.
##
## Supports multiple firing modes (auto, semi-auto, burst), ammo management, reload system,
## both projectile and hitscan attack types, multi-pellet spread, and alternate fire.
##
## A child node named "MuzzleFlash" (any CanvasItem) is shown briefly on each shot
## and hidden automatically, providing lightweight muzzle-flash visual feedback.
class_name BaseWeapon
extends Node2D

const AudioLibrary = preload("res://scripts/systems/audio_library.gd")

## Emitted when ammo count changes (current, max).
signal ammo_changed(current: int, max: int)

## Emitted when reload starts.
signal reload_started

## Emitted when reload completes.
signal reload_completed

## Emitted when attempting to fire with no ammo.
signal empty_fired

enum FiringMode {
	AUTO,       ## Fires continuously while trigger held
	SEMI_AUTO,  ## Fires once per trigger press
	BURST       ## Fires a burst of rounds per trigger press
}

enum AttackType {
	PROJECTILE, ## Spawns a physical projectile
	HITSCAN     ## Instant raycast-based hit detection
}

@export_group("Fire Rate")
@export var fire_rate: float = 0.2
@export var firing_mode: FiringMode = FiringMode.AUTO
@export var burst_count: int = 3
@export var burst_delay: float = 0.1

@export_group("Damage")
@export var damage: float = 10.0
@export var attack_type: AttackType = AttackType.PROJECTILE

@export_group("Spread Settings")
## Number of projectiles or rays fired per shot. Values above 1 create a spread pattern.
@export var pellet_count: int = 1
## Total angle in degrees across which multiple pellets are distributed.
@export var spread_angle: float = 0.0

@export_group("Projectile Settings")
@export var projectile_scene: PackedScene
@export var muzzle_offset: Vector2 = Vector2(32.0, 0.0)
@export var impact_effect_scene: PackedScene

@export_group("Hitscan Settings")
@export var hitscan_range: float = 1000.0
@export var hitscan_pierce_count: int = 0

@export_group("Ammo System")
@export var max_ammo: int = 30
@export var infinite_ammo: bool = false
@export var reload_time: float = 2.0

@export_group("Recoil")
## Rotation applied to the weapon node per shot, in degrees. The weapon
## kicks back by this amount and springs back to rest automatically.
@export var recoil_amount: float = 5.0
## How quickly (degrees per second) the recoil offset returns to zero.
@export var recoil_recovery_speed: float = 120.0

@export_group("Upgrade System")
@export var upgrade_level: int = 0
@export var damage_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
## Multiplier applied to reload_time. Values below 1.0 speed up reloading.
@export var reload_multiplier: float = 1.0

@export_group("Alternate Fire")
## Enable a secondary fire mode for this weapon.
@export var alt_fire_enabled: bool = false
## Attack type used when alternate fire is triggered.
@export var alt_fire_attack_type: AttackType = AttackType.HITSCAN
## Damage multiplier applied to base damage for alternate fire.
@export var alt_fire_damage_multiplier: float = 1.5
## Number of pellets fired per alternate fire shot.
@export var alt_fire_pellet_count: int = 1
## Total spread angle in degrees for alternate fire pellets.
@export var alt_fire_spread_angle: float = 0.0
## Hitscan range used for alternate fire.
@export var alt_fire_hitscan_range: float = 1000.0

## Duration in seconds that the muzzle flash remains visible.
const MUZZLE_FLASH_DURATION: float = 0.075

var current_ammo: int = 30
var is_reloading: bool = false

var _muzzle_flash: CanvasItem = null
var _flash_timer: float = 0.0
var _recoil_offset: float = 0.0
var _fire_audio: AudioStreamPlayer2D = null
var _reload_timer: float = 0.0
var _burst_shots_remaining: int = 0
var _burst_cooldown: float = 0.0
var _last_trigger_state: bool = false
var _alt_fire_last_trigger_state: bool = false


func _ready() -> void:
	_muzzle_flash = get_node_or_null("MuzzleFlash") as CanvasItem
	if _muzzle_flash != null:
		_muzzle_flash.visible = false
	_ensure_fire_audio()
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo, max_ammo)


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and _muzzle_flash != null:
			_muzzle_flash.visible = false

	if _recoil_offset != 0.0:
		var step: float = recoil_recovery_speed * delta
		_recoil_offset = move_toward(_recoil_offset, 0.0, step)
		rotation_degrees = _recoil_offset

	if is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_complete_reload()

	if _burst_shots_remaining > 0:
		_burst_cooldown -= delta
		if _burst_cooldown <= 0.0:
			_fire_burst_shot()


## Attempt to fire the weapon with current trigger state.
## Returns true if a shot was fired, false otherwise.
func try_fire(direction: Vector2, trigger_held: bool) -> bool:
	if is_reloading:
		return false

	# Handle different firing modes
	match firing_mode:
		FiringMode.SEMI_AUTO:
			if trigger_held and not _last_trigger_state:
				_last_trigger_state = true
				return _fire_single(direction)
			elif not trigger_held:
				_last_trigger_state = false
			return false

		FiringMode.BURST:
			if trigger_held and not _last_trigger_state:
				_last_trigger_state = true
				return _start_burst(direction)
			elif not trigger_held:
				_last_trigger_state = false
			return false

		FiringMode.AUTO:
			_last_trigger_state = trigger_held
			if trigger_held:
				return _fire_single(direction)
			return false

	return false


## Fire a projectile or hitscan in [param direction]. Direction should be normalised.
## This is the legacy method maintained for backward compatibility.
func fire(direction: Vector2) -> void:
	_fire_single(direction)


func _fire_single(direction: Vector2) -> bool:
	if not infinite_ammo and current_ammo <= 0:
		empty_fired.emit()
		return false

	if not infinite_ammo:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, max_ammo)

	_execute_attack(direction, attack_type, damage * damage_multiplier,
			pellet_count, spread_angle, hitscan_range, hitscan_pierce_count)
	_show_muzzle_flash()
	_play_fire_audio()
	_apply_recoil()
	return true


## Fire the alternate fire mode. Always semi-auto (one shot per trigger press).
## Returns true if the alternate fire was triggered.
func try_alt_fire(direction: Vector2, trigger_held: bool) -> bool:
	if not alt_fire_enabled:
		return false
	if is_reloading:
		return false

	if trigger_held and not _alt_fire_last_trigger_state:
		_alt_fire_last_trigger_state = true
		return _fire_alt_single(direction)
	elif not trigger_held:
		_alt_fire_last_trigger_state = false
	return false


func _fire_alt_single(direction: Vector2) -> bool:
	if not infinite_ammo and current_ammo <= 0:
		empty_fired.emit()
		return false

	if not infinite_ammo:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, max_ammo)

	var effective_damage := damage * damage_multiplier * alt_fire_damage_multiplier
	_execute_attack(direction, alt_fire_attack_type, effective_damage,
			alt_fire_pellet_count, alt_fire_spread_angle, alt_fire_hitscan_range,
			hitscan_pierce_count)
	_show_muzzle_flash()
	_play_fire_audio()
	_apply_recoil()
	return true


## Execute an attack with the given parameters, firing one or more pellets.
func _execute_attack(direction: Vector2, type: AttackType, effective_damage: float,
		pellets: int, spread: float, h_range: float, pierce: int) -> void:
	if pellets <= 1:
		match type:
			AttackType.PROJECTILE:
				_fire_projectile(direction, effective_damage)
			AttackType.HITSCAN:
				_fire_hitscan_at(direction, effective_damage, h_range, pierce)
	else:
		for i in range(pellets):
			var angle_offset: float = lerpf(-spread * 0.5, spread * 0.5, float(i) / float(pellets - 1))
			var spread_dir := direction.rotated(deg_to_rad(angle_offset))
			match type:
				AttackType.PROJECTILE:
					_fire_projectile(spread_dir, effective_damage)
				AttackType.HITSCAN:
					_fire_hitscan_at(spread_dir, effective_damage, h_range, pierce)


func _fire_projectile(direction: Vector2, effective_damage: float) -> void:
	if projectile_scene == null:
		push_warning("BaseWeapon: projectile_scene is not assigned.")
		return

	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_warning("BaseWeapon: projectile_scene root is not a Projectile node.")
		return

	projectile.global_position = global_position + muzzle_offset.rotated(global_rotation)
	projectile.direction = direction
	projectile.damage = effective_damage
	projectile.source_body = get_parent() as Node2D

	var level: Node = get_tree().current_scene
	if level != null:
		level.add_child(projectile)


func _fire_hitscan_at(direction: Vector2, effective_damage: float, range: float, pierce: int) -> void:
	var space_state := get_world_2d().direct_space_state
	var start_pos := global_position + muzzle_offset.rotated(global_rotation)
	var end_pos := start_pos + direction * range
	var source := get_parent() as Node2D

	var hits: int = 0
	var current_start := start_pos

	while hits <= pierce:
		var query := PhysicsRayQueryParameters2D.create(current_start, end_pos)
		query.exclude = [source] if source != null else []
		query.collide_with_areas = true
		query.collide_with_bodies = true

		var result := space_state.intersect_ray(query)
		if result.is_empty():
			break

		var hit_pos: Vector2 = result.position
		var collider: Object = result.collider

		# Apply damage to hit target
		if collider is Node:
			var health: HealthComponent = collider.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.take_damage(effective_damage)
				AudioManager.play_sfx("impact_body", hit_pos)
			else:
				AudioManager.play_sfx("impact_wall", hit_pos)

		# Spawn impact effect
		_spawn_impact_at(hit_pos)

		hits += 1
		if hits > pierce:
			break

		# Continue ray from slightly past the hit point
		current_start = hit_pos + direction * 0.1


func _start_burst(direction: Vector2) -> bool:
	if not infinite_ammo and current_ammo <= 0:
		empty_fired.emit()
		return false

	_burst_shots_remaining = burst_count
	_burst_cooldown = 0.0
	return true


func _fire_burst_shot() -> void:
	if _burst_shots_remaining <= 0:
		return

	var direction := Vector2.RIGHT.rotated(global_rotation)
	if _fire_single(direction):
		_burst_shots_remaining -= 1
		if _burst_shots_remaining > 0:
			_burst_cooldown = burst_delay


## Start reloading the weapon.
func reload() -> void:
	if is_reloading:
		return
	if current_ammo >= max_ammo:
		return
	if infinite_ammo:
		return

	is_reloading = true
	_reload_timer = get_effective_reload_time()
	reload_started.emit()


func _complete_reload() -> void:
	is_reloading = false
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo, max_ammo)
	reload_completed.emit()


## Get the actual fire rate accounting for upgrades.
func get_effective_fire_rate() -> float:
	return fire_rate * fire_rate_multiplier


## Get the actual reload time accounting for upgrades.
func get_effective_reload_time() -> float:
	return reload_time * reload_multiplier


## Apply an upgrade to the weapon.
func apply_upgrade(level_increase: int = 1) -> void:
	upgrade_level += level_increase
	# Each level increases damage by 10%, improves fire rate by 5%, and speeds up reload by 5%
	damage_multiplier = 1.0 + (upgrade_level * 0.1)
	fire_rate_multiplier = maxf(0.5, 1.0 - (upgrade_level * 0.05))
	reload_multiplier = maxf(0.5, 1.0 - (upgrade_level * 0.05))


## Check if the weapon can fire (has ammo and not reloading).
func can_fire() -> bool:
	return not is_reloading and (infinite_ammo or current_ammo > 0)


func _spawn_impact_at(position: Vector2) -> void:
	if impact_effect_scene == null:
		return
	var level: Node = get_tree().current_scene
	if level == null:
		return
	var effect: Node2D = impact_effect_scene.instantiate() as Node2D
	if effect == null:
		return
	effect.global_position = position
	level.add_child(effect)


func _show_muzzle_flash() -> void:
	if _muzzle_flash == null:
		return
	_muzzle_flash.visible = true
	_flash_timer = MUZZLE_FLASH_DURATION


func _apply_recoil() -> void:
	if recoil_amount == 0.0:
		return
	_recoil_offset += recoil_amount
	rotation_degrees = _recoil_offset


func _ensure_fire_audio() -> void:
	if _fire_audio != null:
		return
	_fire_audio = AudioStreamPlayer2D.new()
	_fire_audio.name = "FireAudio"
	_fire_audio.stream = AudioLibrary.get_blaster_shot()
	_fire_audio.volume_db = -4.0
	_fire_audio.bus = AudioManager.BUS_SFX
	_fire_audio.max_distance = 1000.0
	add_child(_fire_audio)


func _play_fire_audio() -> void:
	if _fire_audio == null:
		return
	_fire_audio.stop()
	if _fire_audio.stream == null:
		_fire_audio.stream = AudioLibrary.get_blaster_shot()
	_fire_audio.play()
