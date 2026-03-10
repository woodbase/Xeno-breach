extends GutTest

## Test suite for the modular weapon system (BaseWeapon).
##
## Validates ammo system, reload mechanics, firing modes, hitscan vs projectile,
## and upgrade functionality.

const BaseWeapon = preload("res://scripts/combat/base_weapon.gd")
const WeaponData = preload("res://scripts/data/weapon_data.gd")
const HealthComponent = preload("res://scripts/core/health_component.gd")

var weapon: BaseWeapon
var test_scene: Node2D
var target_body: Node2D


func before_each() -> void:
	test_scene = Node2D.new()
	add_child_autofree(test_scene)

	weapon = BaseWeapon.new()
	weapon.position = Vector2.ZERO
	test_scene.add_child(weapon)


func after_each() -> void:
	weapon = null
	target_body = null


## Test that weapon initializes with correct ammo values
func test_weapon_initializes_with_max_ammo() -> void:
	weapon.max_ammo = 30
	weapon._ready()
	assert_eq(weapon.current_ammo, 30, "Weapon should start with max ammo")


## Test that firing reduces ammo count
func test_firing_reduces_ammo() -> void:
	weapon.max_ammo = 10
	weapon.infinite_ammo = false
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	var initial_ammo := weapon.current_ammo
	weapon._fire_single(Vector2.RIGHT)
	assert_eq(weapon.current_ammo, initial_ammo - 1, "Ammo should decrease by 1 after firing")


## Test that weapon doesn't fire when out of ammo
func test_cannot_fire_with_no_ammo() -> void:
	weapon.max_ammo = 1
	weapon.infinite_ammo = false
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	weapon._fire_single(Vector2.RIGHT)
	assert_eq(weapon.current_ammo, 0, "Should have 0 ammo after firing once")

	var result := weapon._fire_single(Vector2.RIGHT)
	assert_false(result, "Should not be able to fire with 0 ammo")


## Test that infinite ammo doesn't deplete
func test_infinite_ammo_doesnt_deplete() -> void:
	weapon.max_ammo = 30
	weapon.infinite_ammo = true
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	var initial_ammo := weapon.current_ammo
	weapon._fire_single(Vector2.RIGHT)
	assert_eq(weapon.current_ammo, initial_ammo, "Infinite ammo should not deplete")


## Test reload mechanics
func test_reload_restores_ammo() -> void:
	weapon.max_ammo = 30
	weapon.reload_time = 0.1
	weapon.infinite_ammo = false
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	# Fire a few rounds
	weapon._fire_single(Vector2.RIGHT)
	weapon._fire_single(Vector2.RIGHT)
	weapon._fire_single(Vector2.RIGHT)
	assert_eq(weapon.current_ammo, 27, "Should have 27 ammo after 3 shots")

	# Start reload
	weapon.reload()
	assert_true(weapon.is_reloading, "Should be in reload state")
	assert_eq(weapon.current_ammo, 27, "Ammo shouldn't change immediately on reload start")

	# Wait for reload to complete
	await wait_seconds(0.2)

	assert_false(weapon.is_reloading, "Should not be reloading after reload time")
	assert_eq(weapon.current_ammo, weapon.max_ammo, "Should have max ammo after reload")


## Test that weapon can't fire while reloading
func test_cannot_fire_while_reloading() -> void:
	weapon.max_ammo = 30
	weapon.reload_time = 1.0
	weapon.infinite_ammo = false
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	weapon.reload()
	assert_true(weapon.is_reloading, "Should be reloading")

	var result := weapon.try_fire(Vector2.RIGHT, true)
	assert_false(result, "Should not be able to fire while reloading")


## Test semi-auto firing mode (one shot per trigger pull)
func test_semi_auto_firing_mode() -> void:
	weapon.max_ammo = 30
	weapon.infinite_ammo = false
	weapon.firing_mode = BaseWeapon.FiringMode.SEMI_AUTO
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	var initial_ammo := weapon.current_ammo

	# First trigger press should fire
	var fired := weapon.try_fire(Vector2.RIGHT, true)
	assert_true(fired, "Should fire on first trigger press")
	assert_eq(weapon.current_ammo, initial_ammo - 1, "Ammo should decrease by 1")

	# Holding trigger should not fire again
	fired = weapon.try_fire(Vector2.RIGHT, true)
	assert_false(fired, "Should not fire while holding trigger in semi-auto")
	assert_eq(weapon.current_ammo, initial_ammo - 1, "Ammo should remain the same")

	# Releasing and pressing again should fire
	weapon.try_fire(Vector2.RIGHT, false)  # Release
	fired = weapon.try_fire(Vector2.RIGHT, true)  # Press again
	assert_true(fired, "Should fire on second trigger press")
	assert_eq(weapon.current_ammo, initial_ammo - 2, "Ammo should decrease by 1 again")


## Test auto firing mode
func test_auto_firing_mode() -> void:
	weapon.max_ammo = 30
	weapon.infinite_ammo = false
	weapon.firing_mode = BaseWeapon.FiringMode.AUTO
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	var initial_ammo := weapon.current_ammo

	# Should fire continuously while trigger held
	weapon.try_fire(Vector2.RIGHT, true)
	weapon.try_fire(Vector2.RIGHT, true)
	weapon.try_fire(Vector2.RIGHT, true)

	assert_lt(weapon.current_ammo, initial_ammo, "Ammo should decrease with auto fire")


## Test burst firing mode
func test_burst_firing_mode() -> void:
	weapon.max_ammo = 30
	weapon.infinite_ammo = false
	weapon.firing_mode = BaseWeapon.FiringMode.BURST
	weapon.burst_count = 3
	weapon.burst_delay = 0.05
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	var initial_ammo := weapon.current_ammo

	# Start burst
	weapon.try_fire(Vector2.RIGHT, true)
	assert_eq(weapon._burst_shots_remaining, 3, "Should have 3 burst shots queued")

	# Wait for burst to complete
	await wait_seconds(0.2)

	# Burst should have fired 3 rounds
	assert_eq(weapon.current_ammo, initial_ammo - 3, "Should have fired 3 rounds in burst")
	assert_eq(weapon._burst_shots_remaining, 0, "Burst should be complete")


## Test weapon upgrade system
func test_weapon_upgrades_increase_stats() -> void:
	weapon.damage = 10.0
	weapon.fire_rate = 0.5
	weapon._ready()

	assert_eq(weapon.damage_multiplier, 1.0, "Initial damage multiplier should be 1.0")
	assert_eq(weapon.fire_rate_multiplier, 1.0, "Initial fire rate multiplier should be 1.0")

	weapon.apply_upgrade(1)
	assert_eq(weapon.upgrade_level, 1, "Upgrade level should be 1")
	assert_eq(weapon.damage_multiplier, 1.1, "Damage multiplier should increase to 1.1")
	assert_almost_eq(weapon.fire_rate_multiplier, 0.95, 0.01, "Fire rate multiplier should be 0.95")

	weapon.apply_upgrade(1)
	assert_eq(weapon.upgrade_level, 2, "Upgrade level should be 2")
	assert_eq(weapon.damage_multiplier, 1.2, "Damage multiplier should increase to 1.2")


## Test can_fire method
func test_can_fire_method() -> void:
	weapon.max_ammo = 10
	weapon.infinite_ammo = false
	weapon._ready()

	assert_true(weapon.can_fire(), "Should be able to fire with ammo")

	weapon.current_ammo = 0
	assert_false(weapon.can_fire(), "Should not be able to fire without ammo")

	weapon.current_ammo = 5
	weapon.is_reloading = true
	assert_false(weapon.can_fire(), "Should not be able to fire while reloading")


## Test WeaponData apply_to_weapon method
func test_weapon_data_applies_correctly() -> void:
	var weapon_data := WeaponData.new()
	weapon_data.weapon_name = "Test Gun"
	weapon_data.fire_rate = 0.15
	weapon_data.damage = 25.0
	weapon_data.max_ammo = 20
	weapon_data.reload_time = 1.5
	weapon_data.firing_mode = BaseWeapon.FiringMode.BURST
	weapon_data.attack_type = BaseWeapon.AttackType.HITSCAN

	weapon_data.apply_to_weapon(weapon)

	assert_eq(weapon.fire_rate, 0.15, "Fire rate should match")
	assert_eq(weapon.damage, 25.0, "Damage should match")
	assert_eq(weapon.max_ammo, 20, "Max ammo should match")
	assert_eq(weapon.reload_time, 1.5, "Reload time should match")
	assert_eq(weapon.firing_mode, BaseWeapon.FiringMode.BURST, "Firing mode should match")
	assert_eq(weapon.attack_type, BaseWeapon.AttackType.HITSCAN, "Attack type should match")
	assert_eq(weapon.current_ammo, 20, "Current ammo should be set to max")


## Test ammo_changed signal
func test_ammo_changed_signal_emitted() -> void:
	weapon.max_ammo = 10
	weapon.infinite_ammo = false
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN

	watch_signals(weapon)
	weapon._ready()

	assert_signal_emitted(weapon, "ammo_changed", "ammo_changed should emit on ready")

	weapon._fire_single(Vector2.RIGHT)
	assert_signal_emitted_with_parameters(weapon, "ammo_changed", [9, 10], "Should emit with correct values")


## Test empty_fired signal
func test_empty_fired_signal_emitted() -> void:
	weapon.max_ammo = 0
	weapon.infinite_ammo = false
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	watch_signals(weapon)
	weapon._fire_single(Vector2.RIGHT)

	assert_signal_emitted(weapon, "empty_fired", "empty_fired should emit when trying to fire with no ammo")


## Test reload signals
func test_reload_signals_emitted() -> void:
	weapon.max_ammo = 10
	weapon.reload_time = 0.1
	weapon.infinite_ammo = false
	weapon._ready()

	weapon._fire_single(Vector2.RIGHT)

	watch_signals(weapon)
	weapon.reload()

	assert_signal_emitted(weapon, "reload_started", "reload_started should emit")

	await wait_seconds(0.2)

	assert_signal_emitted(weapon, "reload_completed", "reload_completed should emit after reload time")
