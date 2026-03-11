extends GutTest

## Test suite for WeaponManager - weapon inventory and switching system.

const WeaponManager = preload("res://scripts/systems/weapon_manager.gd")
const BaseWeapon = preload("res://scripts/combat/base_weapon.gd")

var weapon_manager: WeaponManager
var weapon1: BaseWeapon
var weapon2: BaseWeapon
var weapon3: BaseWeapon
var test_scene: Node2D


func before_each() -> void:
	test_scene = Node2D.new()
	add_child_autofree(test_scene)

	weapon_manager = WeaponManager.new()
	test_scene.add_child(weapon_manager)

	weapon1 = BaseWeapon.new()
	weapon1.name = "Weapon1"
	weapon1.max_ammo = 30
	weapon_manager.add_child(weapon1)

	weapon2 = BaseWeapon.new()
	weapon2.name = "Weapon2"
	weapon2.max_ammo = 15
	weapon_manager.add_child(weapon2)

	weapon3 = BaseWeapon.new()
	weapon3.name = "Weapon3"
	weapon3.max_ammo = 8
	weapon_manager.add_child(weapon3)


func after_each() -> void:
	weapon_manager = null
	weapon1 = null
	weapon2 = null
	weapon3 = null


## Test that WeaponManager correctly identifies all weapon children
func test_weapon_manager_finds_weapons() -> void:
	weapon_manager._ready()
	assert_eq(weapon_manager.get_weapon_count(), 3, "Should find 3 weapons")


## Test that first weapon is active on ready
func test_first_weapon_active_on_ready() -> void:
	weapon_manager._ready()
	var active := weapon_manager.get_active_weapon()
	assert_not_null(active, "Should have an active weapon")
	assert_eq(active.name, "Weapon1", "First weapon should be active")
	assert_true(active.visible, "Active weapon should be visible")


## Test weapon switching by index
func test_switch_weapon_by_index() -> void:
	weapon_manager._ready()

	weapon_manager.switch_weapon(1)
	var active := weapon_manager.get_active_weapon()
	assert_eq(active.name, "Weapon2", "Should switch to second weapon")
	assert_true(weapon2.visible, "Weapon 2 should be visible")
	assert_false(weapon1.visible, "Weapon 1 should be hidden")

	weapon_manager.switch_weapon(2)
	active = weapon_manager.get_active_weapon()
	assert_eq(active.name, "Weapon3", "Should switch to third weapon")
	assert_true(weapon3.visible, "Weapon 3 should be visible")
	assert_false(weapon2.visible, "Weapon 2 should be hidden")


## Test next_weapon cycles through weapons
func test_next_weapon_cycles() -> void:
	weapon_manager._ready()

	assert_eq(weapon_manager.active_weapon_index, 0, "Should start at index 0")

	weapon_manager.next_weapon()
	assert_eq(weapon_manager.active_weapon_index, 1, "Should be at index 1")
	assert_eq(weapon_manager.get_active_weapon().name, "Weapon2", "Should be weapon 2")

	weapon_manager.next_weapon()
	assert_eq(weapon_manager.active_weapon_index, 2, "Should be at index 2")

	weapon_manager.next_weapon()
	assert_eq(weapon_manager.active_weapon_index, 0, "Should wrap back to index 0")
	assert_eq(weapon_manager.get_active_weapon().name, "Weapon1", "Should be weapon 1")


## Test prev_weapon cycles backwards
func test_prev_weapon_cycles() -> void:
	weapon_manager._ready()

	weapon_manager.prev_weapon()
	assert_eq(weapon_manager.active_weapon_index, 2, "Should wrap to last weapon")
	assert_eq(weapon_manager.get_active_weapon().name, "Weapon3", "Should be weapon 3")

	weapon_manager.prev_weapon()
	assert_eq(weapon_manager.active_weapon_index, 1, "Should be at index 1")


## Test weapon_changed signal
func test_weapon_changed_signal() -> void:
	weapon_manager._ready()

	watch_signals(weapon_manager)
	weapon_manager.switch_weapon(1)

	assert_signal_emitted(weapon_manager, "weapon_changed", "weapon_changed should emit on switch")
	assert_signal_emitted_with_parameters(weapon_manager, "weapon_changed", [weapon2], "Should emit with new weapon")


## Test adding weapon at runtime
func test_add_weapon_at_runtime() -> void:
	weapon_manager._ready()

	var new_weapon := BaseWeapon.new()
	new_weapon.name = "NewWeapon"
	weapon_manager.add_weapon(new_weapon)

	assert_eq(weapon_manager.get_weapon_count(), 4, "Should have 4 weapons after adding")


## Test removing weapon
func test_remove_weapon() -> void:
	weapon_manager._ready()

	weapon_manager.remove_weapon(1)
	assert_eq(weapon_manager.get_weapon_count(), 2, "Should have 2 weapons after removing")


## Test removing active weapon switches to another
func test_removing_active_weapon_switches() -> void:
	weapon_manager._ready()
	weapon_manager.switch_weapon(1)  # Make weapon 2 active

	var original_active := weapon_manager.get_active_weapon()
	assert_eq(original_active.name, "Weapon2", "Weapon 2 should be active")

	weapon_manager.remove_weapon(1)  # Remove weapon 2

	var new_active := weapon_manager.get_active_weapon()
	assert_not_null(new_active, "Should have a new active weapon")
	assert_ne(new_active, original_active, "Active weapon should have changed")


## Test try_fire delegates to active weapon
func test_try_fire_delegates_to_weapon() -> void:
	weapon_manager._ready()

	weapon1.infinite_ammo = true
	weapon1.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon1._ready()

	var result := weapon_manager.try_fire(Vector2.RIGHT, true)
	assert_true(result, "Should successfully fire through manager")


## Test reload delegates to active weapon
func test_reload_delegates_to_weapon() -> void:
	weapon_manager._ready()

	weapon1.infinite_ammo = false
	weapon1.max_ammo = 10
	weapon1.reload_time = 0.1
	weapon1._ready()

	weapon1._fire_single(Vector2.RIGHT)
	weapon1._fire_single(Vector2.RIGHT)

	assert_eq(weapon1.current_ammo, 8, "Should have 8 ammo")

	weapon_manager.reload()
	assert_true(weapon1.is_reloading, "Weapon should be reloading")


## Test that switching weapons while one is active works correctly
func test_only_active_weapon_visible() -> void:
	weapon_manager._ready()

	weapon_manager.switch_weapon(0)
	assert_true(weapon1.visible, "Weapon 1 should be visible")
	assert_false(weapon2.visible, "Weapon 2 should be hidden")
	assert_false(weapon3.visible, "Weapon 3 should be hidden")

	weapon_manager.switch_weapon(1)
	assert_false(weapon1.visible, "Weapon 1 should be hidden")
	assert_true(weapon2.visible, "Weapon 2 should be visible")
	assert_false(weapon3.visible, "Weapon 3 should be hidden")


## Test ammo_changed signal forwarding
func test_ammo_changed_signal_forwarding() -> void:
	weapon_manager._ready()

	weapon1.infinite_ammo = false
	weapon1.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon1._ready()

	watch_signals(weapon_manager)
	weapon1._fire_single(Vector2.RIGHT)

	assert_signal_emitted(weapon_manager, "ammo_changed", "Manager should forward ammo_changed signal")


## Test reload signals forwarding
func test_reload_signals_forwarding() -> void:
	weapon_manager._ready()

	weapon1.infinite_ammo = false
	weapon1.reload_time = 0.1
	weapon1._ready()

	weapon1._fire_single(Vector2.RIGHT)

	watch_signals(weapon_manager)
	weapon_manager.reload()

	assert_signal_emitted(weapon_manager, "reload_started", "Manager should forward reload_started")

	await wait_seconds(0.2)

	assert_signal_emitted(weapon_manager, "reload_completed", "Manager should forward reload_completed")


## Test empty_fired signal forwarding from active weapon
func test_empty_fired_signal_forwarding() -> void:
	weapon_manager._ready()

	weapon1.infinite_ammo = false
	weapon1.max_ammo = 0
	weapon1._ready()

	watch_signals(weapon_manager)
	weapon1._fire_single(Vector2.RIGHT)

	assert_signal_emitted(weapon_manager, "empty_fired", "Manager should forward empty_fired from active weapon")


## Test ammo_changed is not forwarded from inactive weapons
func test_ammo_changed_not_forwarded_from_inactive_weapon() -> void:
	weapon_manager._ready()

	weapon1.infinite_ammo = false
	weapon1.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon1._ready()

	weapon2.infinite_ammo = false
	weapon2.attack_type = BaseWeapon.AttackType.HITSCAN
	weapon2._ready()

	# weapon1 is active; fire weapon2 (inactive) directly
	watch_signals(weapon_manager)
	weapon2._fire_single(Vector2.RIGHT)

	assert_signal_not_emitted(weapon_manager, "ammo_changed", "Manager should NOT forward ammo_changed from inactive weapon")
