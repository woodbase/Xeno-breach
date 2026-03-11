extends GutTest

## Test suite for the Weapons Expansion features.
##
## Validates pellet spread system, alternate fire mode, reload multiplier
## upgrade improvements, and WeaponData support for new fields.

const BaseWeapon = preload("res://scripts/combat/base_weapon.gd")
const WeaponData = preload("res://scripts/data/weapon_data.gd")
const WeaponManager = preload("res://scripts/systems/weapon_manager.gd")

var weapon: BaseWeapon
var test_scene: Node2D


func before_each() -> void:
	test_scene = Node2D.new()
	add_child_autofree(test_scene)

	weapon = BaseWeapon.new()
	weapon.position = Vector2.ZERO
	test_scene.add_child(weapon)


func after_each() -> void:
	weapon = null


# ─── Pellet Spread System ────────────────────────────────────────────────────

## Single pellet (default) still consumes exactly one ammo per shot.
func test_single_pellet_consumes_one_ammo() -> void:
	weapon.max_ammo = 10
	weapon.infinite_ammo = false
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon.pellet_count = 1
	weapon.spread_angle = 0.0
	weapon._ready()

	weapon._fire_single(Vector2.RIGHT)
	assert_eq(weapon.current_ammo, 9, "Single pellet should consume 1 ammo")


## Multiple pellets still consume only one ammo per trigger pull.
func test_multi_pellet_consumes_one_ammo() -> void:
	weapon.max_ammo = 10
	weapon.infinite_ammo = false
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon.pellet_count = 8
	weapon.spread_angle = 30.0
	weapon._ready()

	weapon._fire_single(Vector2.RIGHT)
	assert_eq(weapon.current_ammo, 9, "Multi-pellet shotgun blast should consume only 1 ammo")


## pellet_count defaults to 1.
func test_pellet_count_default_is_one() -> void:
	assert_eq(weapon.pellet_count, 1, "Default pellet_count should be 1")


## spread_angle defaults to 0.
func test_spread_angle_default_is_zero() -> void:
	assert_eq(weapon.spread_angle, 0.0, "Default spread_angle should be 0.0")


# ─── Alternate Fire ──────────────────────────────────────────────────────────

## try_alt_fire returns false when alt fire is disabled.
func test_alt_fire_disabled_returns_false() -> void:
	weapon.alt_fire_enabled = false
	weapon.infinite_ammo = true
	weapon.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon._ready()

	var result := weapon.try_alt_fire(Vector2.RIGHT, true)
	assert_false(result, "try_alt_fire should return false when alt_fire_enabled is false")


## try_alt_fire fires once on first trigger press.
func test_alt_fire_fires_on_trigger_press() -> void:
	weapon.alt_fire_enabled = true
	weapon.alt_fire_attack_type = BaseWeapon.AttackType.HITSCAN
	weapon.alt_fire_damage_multiplier = 2.0
	weapon.alt_fire_pellet_count = 1
	weapon.max_ammo = 10
	weapon.infinite_ammo = false
	weapon._ready()

	var result := weapon.try_alt_fire(Vector2.RIGHT, true)
	assert_true(result, "try_alt_fire should return true on first trigger press")
	assert_eq(weapon.current_ammo, 9, "Alt fire should consume 1 ammo")


## Alt fire is semi-auto: holding trigger does not continue firing.
func test_alt_fire_is_semi_auto() -> void:
	weapon.alt_fire_enabled = true
	weapon.alt_fire_attack_type = BaseWeapon.AttackType.HITSCAN
	weapon.max_ammo = 10
	weapon.infinite_ammo = false
	weapon._ready()

	weapon.try_alt_fire(Vector2.RIGHT, true)  # First press — fires
	var ammo_after_first := weapon.current_ammo

	weapon.try_alt_fire(Vector2.RIGHT, true)  # Holding — should not fire again
	assert_eq(weapon.current_ammo, ammo_after_first, "Alt fire should not fire again while trigger is held")


## Releasing the trigger allows alt fire to fire again.
func test_alt_fire_resets_on_release() -> void:
	weapon.alt_fire_enabled = true
	weapon.alt_fire_attack_type = BaseWeapon.AttackType.HITSCAN
	weapon.max_ammo = 10
	weapon.infinite_ammo = false
	weapon._ready()

	weapon.try_alt_fire(Vector2.RIGHT, true)   # Press — fires
	weapon.try_alt_fire(Vector2.RIGHT, false)  # Release
	var result := weapon.try_alt_fire(Vector2.RIGHT, true)  # Press again — should fire

	assert_true(result, "Alt fire should fire after releasing and pressing trigger again")


## Alt fire does not fire when weapon is reloading.
func test_alt_fire_blocked_while_reloading() -> void:
	weapon.alt_fire_enabled = true
	weapon.max_ammo = 10
	weapon.reload_time = 5.0
	weapon.infinite_ammo = false
	weapon._ready()

	weapon._fire_single(Vector2.RIGHT)  # Use one ammo
	weapon.reload()
	assert_true(weapon.is_reloading, "Weapon should be reloading")

	var result := weapon.try_alt_fire(Vector2.RIGHT, true)
	assert_false(result, "Alt fire should be blocked while reloading")


## Alt fire with no ammo emits empty_fired and does not fire.
func test_alt_fire_with_no_ammo_emits_empty_fired() -> void:
	weapon.alt_fire_enabled = true
	weapon.alt_fire_attack_type = BaseWeapon.AttackType.HITSCAN
	weapon.max_ammo = 0
	weapon.infinite_ammo = false
	weapon._ready()

	watch_signals(weapon)
	weapon.try_alt_fire(Vector2.RIGHT, true)

	assert_signal_emitted(weapon, "empty_fired", "empty_fired should emit when alt firing with no ammo")


## Alt fire pellet count defaults to 1.
func test_alt_fire_pellet_count_default() -> void:
	assert_eq(weapon.alt_fire_pellet_count, 1, "Default alt_fire_pellet_count should be 1")


## Alt fire damage multiplier defaults to 1.5.
func test_alt_fire_damage_multiplier_default() -> void:
	assert_eq(weapon.alt_fire_damage_multiplier, 1.5, "Default alt_fire_damage_multiplier should be 1.5")


# ─── Reload Multiplier & Upgrade System ──────────────────────────────────────

## reload_multiplier defaults to 1.0.
func test_reload_multiplier_default() -> void:
	assert_eq(weapon.reload_multiplier, 1.0, "Default reload_multiplier should be 1.0")


## get_effective_reload_time returns reload_time * reload_multiplier.
func test_get_effective_reload_time() -> void:
	weapon.reload_time = 2.0
	weapon.reload_multiplier = 0.5
	assert_almost_eq(weapon.get_effective_reload_time(), 1.0, 0.001,
			"Effective reload time should be reload_time * reload_multiplier")


## apply_upgrade also improves reload_multiplier.
func test_upgrade_improves_reload_multiplier() -> void:
	weapon._ready()
	assert_eq(weapon.reload_multiplier, 1.0, "Initial reload_multiplier should be 1.0")

	weapon.apply_upgrade(1)
	assert_almost_eq(weapon.reload_multiplier, 0.95, 0.001,
			"Upgrade level 1 should reduce reload_multiplier to 0.95")

	weapon.apply_upgrade(1)
	assert_almost_eq(weapon.reload_multiplier, 0.9, 0.001,
			"Upgrade level 2 should reduce reload_multiplier to 0.90")


## reload_multiplier is capped at 0.5 (50% speed improvement max).
func test_reload_multiplier_caps_at_half() -> void:
	weapon._ready()
	weapon.apply_upgrade(20)
	assert_almost_eq(weapon.reload_multiplier, 0.5, 0.001,
			"reload_multiplier should not drop below 0.5")


## Upgraded weapon reloads faster than base weapon.
func test_upgraded_weapon_reloads_faster() -> void:
	weapon.reload_time = 2.0
	weapon.reload_multiplier = 1.0
	var base_reload := weapon.get_effective_reload_time()

	weapon.apply_upgrade(2)
	var upgraded_reload := weapon.get_effective_reload_time()

	assert_true(upgraded_reload < base_reload,
			"Upgraded weapon should reload faster than base weapon")


# ─── WeaponData — new field propagation ─────────────────────────────────────

## WeaponData correctly applies pellet_count and spread_angle.
func test_weapon_data_applies_spread_settings() -> void:
	var data := WeaponData.new()
	data.pellet_count = 6
	data.spread_angle = 20.0
	data.apply_to_weapon(weapon)

	assert_eq(weapon.pellet_count, 6, "pellet_count should be applied from WeaponData")
	assert_eq(weapon.spread_angle, 20.0, "spread_angle should be applied from WeaponData")


## WeaponData correctly applies all alt fire properties.
func test_weapon_data_applies_alt_fire_settings() -> void:
	var data := WeaponData.new()
	data.alt_fire_enabled = true
	data.alt_fire_attack_type = BaseWeapon.AttackType.HITSCAN
	data.alt_fire_damage_multiplier = 3.0
	data.alt_fire_pellet_count = 3
	data.alt_fire_spread_angle = 15.0
	data.alt_fire_hitscan_range = 800.0
	data.apply_to_weapon(weapon)

	assert_true(weapon.alt_fire_enabled, "alt_fire_enabled should be applied")
	assert_eq(weapon.alt_fire_attack_type, BaseWeapon.AttackType.HITSCAN,
			"alt_fire_attack_type should be applied")
	assert_eq(weapon.alt_fire_damage_multiplier, 3.0,
			"alt_fire_damage_multiplier should be applied")
	assert_eq(weapon.alt_fire_pellet_count, 3, "alt_fire_pellet_count should be applied")
	assert_eq(weapon.alt_fire_spread_angle, 15.0, "alt_fire_spread_angle should be applied")
	assert_eq(weapon.alt_fire_hitscan_range, 800.0, "alt_fire_hitscan_range should be applied")


# ─── WeaponManager — try_alt_fire delegation ─────────────────────────────────

## WeaponManager.try_alt_fire delegates to the active weapon.
func test_weapon_manager_delegates_alt_fire() -> void:
	var manager := WeaponManager.new()
	test_scene.add_child(manager)

	var w := BaseWeapon.new()
	w.name = "TestWeapon"
	w.max_ammo = 10
	w.infinite_ammo = false
	w.alt_fire_enabled = true
	w.alt_fire_attack_type = BaseWeapon.AttackType.HITSCAN
	manager.add_child(w)
	manager._ready()

	var result := manager.try_alt_fire(Vector2.RIGHT, true)
	assert_true(result, "WeaponManager.try_alt_fire should delegate to active weapon")

	manager.queue_free()


## WeaponManager.try_alt_fire returns false when no active weapon.
func test_weapon_manager_alt_fire_no_weapon() -> void:
	var manager := WeaponManager.new()
	test_scene.add_child(manager)
	manager._ready()  # No children — no active weapon

	var result := manager.try_alt_fire(Vector2.RIGHT, true)
	assert_false(result, "try_alt_fire should return false when there is no active weapon")

	manager.queue_free()


# ─── New Weapon Resources ────────────────────────────────────────────────────

## Shotgun WeaponData resource can be loaded and has expected pellet count.
func test_shotgun_data_resource_loads() -> void:
	var data: WeaponData = load("res://resources/weapons/shotgun_data.tres") as WeaponData
	assert_not_null(data, "shotgun_data.tres should load successfully")
	assert_eq(data.weapon_name, "Combat Shotgun", "Shotgun should have correct name")
	assert_eq(data.pellet_count, 8, "Shotgun should have 8 pellets")
	assert_true(data.alt_fire_enabled, "Shotgun should have alt fire enabled")


## SMG WeaponData resource can be loaded and has correct fire rate.
func test_smg_data_resource_loads() -> void:
	var data: WeaponData = load("res://resources/weapons/smg_data.tres") as WeaponData
	assert_not_null(data, "smg_data.tres should load successfully")
	assert_eq(data.weapon_name, "Arc SMG", "SMG should have correct name")
	assert_eq(data.firing_mode, BaseWeapon.FiringMode.AUTO, "SMG should be automatic")
	assert_almost_eq(data.fire_rate, 0.07, 0.001, "SMG should have fast fire rate")


## Plasma Launcher WeaponData resource can be loaded and has alt fire.
func test_plasma_launcher_data_resource_loads() -> void:
	var data: WeaponData = load("res://resources/weapons/plasma_launcher_data.tres") as WeaponData
	assert_not_null(data, "plasma_launcher_data.tres should load successfully")
	assert_eq(data.weapon_name, "Plasma Launcher", "Plasma Launcher should have correct name")
	assert_true(data.alt_fire_enabled, "Plasma Launcher should have alt fire enabled")
	assert_almost_eq(data.alt_fire_damage_multiplier, 2.5, 0.001,
			"Plasma Launcher alt fire should deal 2.5x damage")
