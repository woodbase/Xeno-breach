# Weapon System Documentation

## Overview

The modular weapon system provides a complete framework for implementing diverse weapon types with support for:
- **Ammo management** (current ammo, max ammo, infinite ammo)
- **Reload system** (reload time, reload state)
- **Multiple attack types** (projectile-based and hitscan/raycast)
- **Firing modes** (automatic, semi-automatic, burst)
- **Weapon switching** (inventory management via WeaponManager)
- **Upgrade system** (damage and fire rate multipliers)
- **Impact effects** (visual and audio feedback)

## Architecture

### Core Components

#### BaseWeapon
Located: `scripts/combat/base_weapon.gd`

The main weapon class that handles all weapon logic. Extends `Node2D` for 2D positioning.

**Key Properties:**
- `fire_rate` - Time between shots (seconds)
- `firing_mode` - AUTO, SEMI_AUTO, or BURST
- `damage` - Base damage per hit
- `attack_type` - PROJECTILE or HITSCAN
- `max_ammo` - Maximum ammunition capacity
- `current_ammo` - Current ammunition count
- `reload_time` - Time to complete reload (seconds)
- `infinite_ammo` - If true, never runs out of ammo

**Key Methods:**
- `try_fire(direction: Vector2, trigger_held: bool) -> bool` - Attempt to fire weapon
- `reload()` - Start reloading the weapon
- `apply_upgrade(level_increase: int)` - Apply upgrade level
- `can_fire() -> bool` - Check if weapon can currently fire
- `get_effective_fire_rate() -> float` - Get fire rate with upgrades

**Signals:**
- `ammo_changed(current: int, max: int)` - Emitted when ammo count changes
- `reload_started` - Emitted when reload begins
- `reload_completed` - Emitted when reload finishes
- `empty_fired` - Emitted when trying to fire with no ammo

#### WeaponData
Located: `scripts/data/weapon_data.gd`

Resource class for weapon configuration. Create `.tres` resource files to define weapon stats.

**Usage Example:**
```gdscript
var weapon_data := WeaponData.new()
weapon_data.weapon_name = "Assault Rifle"
weapon_data.fire_rate = 0.1
weapon_data.damage = 15.0
weapon_data.max_ammo = 30
weapon_data.firing_mode = BaseWeapon.FiringMode.AUTO
weapon_data.attack_type = BaseWeapon.AttackType.PROJECTILE

# Apply to weapon
weapon_data.apply_to_weapon(my_weapon)
```

#### WeaponManager
Located: `scripts/systems/weapon_manager.gd`

Manages weapon inventory and switching. Add as a child to the player, then add BaseWeapon nodes as children.

**Key Methods:**
- `switch_weapon(index: int)` - Switch to weapon at index
- `next_weapon()` - Cycle to next weapon
- `prev_weapon()` - Cycle to previous weapon
- `get_active_weapon() -> BaseWeapon` - Get currently active weapon
- `add_weapon(weapon: BaseWeapon)` - Add weapon to inventory
- `reload()` - Reload active weapon
- `try_fire(direction: Vector2, trigger_held: bool) -> bool` - Fire active weapon

**Signals:**
- `weapon_changed(weapon: BaseWeapon)` - Emitted when active weapon changes
- `ammo_changed(current: int, max: int)` - Forwarded from active weapon
- `reload_started` - Forwarded from active weapon
- `reload_completed` - Forwarded from active weapon

## Firing Modes

### AUTO (Automatic)
Fires continuously while trigger is held. Common for assault rifles, machine guns.

```gdscript
weapon.firing_mode = BaseWeapon.FiringMode.AUTO
```

### SEMI_AUTO (Semi-Automatic)
Fires once per trigger press. Must release and press again to fire next shot. Common for pistols, sniper rifles.

```gdscript
weapon.firing_mode = BaseWeapon.FiringMode.SEMI_AUTO
```

### BURST
Fires a burst of shots per trigger press. Configure `burst_count` and `burst_delay`.

```gdscript
weapon.firing_mode = BaseWeapon.FiringMode.BURST
weapon.burst_count = 3
weapon.burst_delay = 0.1  # Delay between burst shots
```

## Attack Types

### PROJECTILE
Spawns a physical projectile that travels through space. Requires a `projectile_scene` to be set.

**Features:**
- Physical projectile movement
- Collision detection via Area2D
- Visual tracer line
- Impact effects

```gdscript
weapon.attack_type = BaseWeapon.AttackType.PROJECTILE
weapon.projectile_scene = preload("res://scenes/weapons/projectile.tscn")
```

### HITSCAN
Instant raycast-based hit detection. Ideal for sniper rifles and laser weapons.

**Features:**
- Instant hit detection
- Configurable range
- Pierce capability (hit multiple targets)
- No travel time

```gdscript
weapon.attack_type = BaseWeapon.AttackType.HITSCAN
weapon.hitscan_range = 2000.0
weapon.hitscan_pierce_count = 2  # Can pierce through 2 enemies
```

## Ammo System

Weapons track ammunition and require reloading when empty.

```gdscript
# Configure ammo
weapon.max_ammo = 30
weapon.current_ammo = 30
weapon.reload_time = 2.0
weapon.infinite_ammo = false  # Set true for unlimited ammo

# Check ammo
if weapon.current_ammo <= 0:
    weapon.reload()

# Listen for ammo changes
weapon.ammo_changed.connect(func(current: int, max_ammo: int):
    print("Ammo: %d / %d" % [current, max_ammo])
)
```

## Upgrade System

Weapons support progressive upgrades that increase effectiveness.

```gdscript
# Apply upgrade
weapon.apply_upgrade(1)  # Increase level by 1

# Check upgrade level
print("Upgrade level: %d" % weapon.upgrade_level)
print("Damage multiplier: %.2f" % weapon.damage_multiplier)
print("Fire rate multiplier: %.2f" % weapon.fire_rate_multiplier)
```

**Upgrade Effects:**
- Each level increases damage by 10%
- Each level increases fire rate by 5% (faster shooting, max 50% improvement)

## Player Integration

### Setting Up with PlayerController

The PlayerController supports both single weapons and WeaponManager.

**Option 1: Single Weapon**
```gdscript
# In scene tree
PlayerController
  └─ BaseWeapon

# Set weapon_path in inspector
weapon_path = NodePath("BaseWeapon")
```

**Option 2: Multiple Weapons with WeaponManager**
```gdscript
# In scene tree
PlayerController
  └─ WeaponManager
      ├─ AssaultRifle (BaseWeapon)
      ├─ Pistol (BaseWeapon)
      └─ SniperRifle (BaseWeapon)

# Set weapon_path in inspector
weapon_path = NodePath("WeaponManager")
```

### Input Actions

The weapon system uses these input actions (defined in project.godot):

- `fire` - Fire weapon (Mouse Button 1)
- `reload` - Reload weapon (R key)
- `weapon_next` - Next weapon (Mouse Wheel Up)
- `weapon_prev` - Previous weapon (Mouse Wheel Down)

## Demo Weapons

Three demo weapons are provided as examples:

### 1. Assault Rifle
**File:** `resources/weapons/assault_rifle_data.tres`

- Automatic fire
- Projectile-based
- 30 round magazine
- Moderate damage (15)
- Fast fire rate (0.1s)

### 2. Pistol
**File:** `resources/weapons/pistol_data.tres`

- Semi-automatic fire
- Projectile-based
- 15 round magazine
- Low damage (12)
- Medium fire rate (0.25s)

### 3. Sniper Rifle
**File:** `resources/weapons/sniper_rifle_data.tres`

- Semi-automatic fire
- **Hitscan-based**
- 8 round magazine
- High damage (50)
- Slow fire rate (0.8s)
- Pierces through 2 targets

## Testing

Comprehensive test suites are provided:

- `tests/test_weapon_system.gd` - Tests BaseWeapon functionality
- `tests/test_weapon_manager.gd` - Tests WeaponManager inventory system

Run tests using Godot's GUT (Godot Unit Test) framework.

## Best Practices

1. **Always set attack_type** - Choose PROJECTILE or HITSCAN based on weapon type
2. **Configure projectile_scene for projectiles** - Required for PROJECTILE attack type
3. **Balance fire rate with damage** - High damage should have slower fire rate
4. **Use WeaponData resources** - Create `.tres` files for easy weapon configuration
5. **Connect to signals** - Use weapon signals for UI updates and feedback
6. **Test with different firing modes** - Ensure weapon behaves correctly in all modes

## Example: Creating a New Weapon

```gdscript
# Create weapon node
var new_weapon := BaseWeapon.new()
new_weapon.name = "Shotgun"

# Configure stats
new_weapon.firing_mode = BaseWeapon.FiringMode.SEMI_AUTO
new_weapon.attack_type = BaseWeapon.AttackType.HITSCAN
new_weapon.damage = 35.0
new_weapon.fire_rate = 0.6
new_weapon.max_ammo = 8
new_weapon.reload_time = 2.5

# Hitscan settings for shotgun spread (single ray for now)
new_weapon.hitscan_range = 500.0
new_weapon.hitscan_pierce_count = 0

# Add to weapon manager
weapon_manager.add_weapon(new_weapon)
```

## Future Enhancements

Potential additions to the weapon system:

- Weapon spread/accuracy system
- Alternate fire modes
- Weapon attachments/modifications
- Ammunition types
- Weapon durability/overheating
- Dual wielding support
- Multiple projectiles per shot (shotgun spread)
- Charged shots
