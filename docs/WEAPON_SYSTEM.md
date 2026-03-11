# Weapon System Documentation

## Overview

The modular weapon system provides a complete framework for implementing diverse weapon types with support for:
- **Ammo management** (current ammo, max ammo, infinite ammo)
- **Reload system** (reload time, reload state)
- **Multiple attack types** (projectile-based and hitscan/raycast)
- **Firing modes** (automatic, semi-automatic, burst)
- **Multi-pellet spread** (shotgun-style spread attacks)
- **Alternate fire** (secondary fire mode per weapon)
- **Weapon switching** (inventory management via WeaponManager)
- **Upgrade system** (damage, fire rate, and reload speed multipliers)
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
- `pellet_count` - Number of pellets fired per shot (1 = single, >1 = spread)
- `spread_angle` - Total spread angle in degrees for multi-pellet shots
- `max_ammo` - Maximum ammunition capacity
- `current_ammo` - Current ammunition count
- `reload_time` - Time to complete reload (seconds)
- `infinite_ammo` - If true, never runs out of ammo
- `alt_fire_enabled` - Enable alternate fire mode
- `alt_fire_attack_type` - Attack type for alternate fire
- `alt_fire_damage_multiplier` - Damage multiplier for alternate fire
- `alt_fire_pellet_count` - Pellets fired per alternate fire shot
- `alt_fire_spread_angle` - Spread angle for alternate fire pellets
- `alt_fire_hitscan_range` - Hitscan range for alternate fire

**Key Methods:**
- `try_fire(direction: Vector2, trigger_held: bool) -> bool` - Attempt to fire weapon
- `try_alt_fire(direction: Vector2, trigger_held: bool) -> bool` - Attempt alternate fire
- `reload()` - Start reloading the weapon
- `apply_upgrade(level_increase: int)` - Apply upgrade level
- `can_fire() -> bool` - Check if weapon can currently fire
- `get_effective_fire_rate() -> float` - Get fire rate with upgrades
- `get_effective_reload_time() -> float` - Get reload time with upgrades

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
- `try_alt_fire(direction: Vector2, trigger_held: bool) -> bool` - Alternate fire active weapon

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
- Each level speeds up reload by 5% (faster reloading, max 50% improvement)

## Multi-Pellet Spread

Weapons can fire multiple projectiles or hitscan rays simultaneously in a spread pattern, ideal for shotgun-style weapons.

```gdscript
# Configure spread
weapon.pellet_count = 8    # Fire 8 pellets at once
weapon.spread_angle = 30.0 # Distribute across a 30-degree cone
weapon.attack_type = BaseWeapon.AttackType.HITSCAN

# Pellets share the same ammo: one trigger pull = one ammo consumed
```

**Notes:**
- `pellet_count = 1` (default) behaves identically to a single-shot weapon
- Each pellet deals the weapon's full damage independently
- Works with both PROJECTILE and HITSCAN attack types

## Alternate Fire

Weapons can have a secondary fire mode activated with the `alt_fire` input (right mouse button).

```gdscript
# Enable alternate fire
weapon.alt_fire_enabled = true

# Configure alternate fire
weapon.alt_fire_attack_type = BaseWeapon.AttackType.HITSCAN  # or PROJECTILE
weapon.alt_fire_damage_multiplier = 2.5  # 2.5x base damage
weapon.alt_fire_pellet_count = 1         # Single slug
weapon.alt_fire_spread_angle = 0.0       # No spread
weapon.alt_fire_hitscan_range = 1200.0   # Extended range

# Trigger alternate fire
weapon.try_alt_fire(direction, trigger_held)
```

**Alternate Fire Behaviour:**
- Always **semi-auto**: fires once per trigger press regardless of primary firing mode
- Uses the same ammo pool as primary fire
- Shares the weapon's `damage_multiplier` from upgrades (stacked with `alt_fire_damage_multiplier`)
- Blocked while reloading
- Emits `empty_fired` signal when triggered with no ammo

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

- `fire` - Fire weapon (Mouse Button 1 / Left Click)
- `alt_fire` - Alternate fire (Mouse Button 2 / Right Click)
- `reload` - Reload weapon (R key)
- `weapon_next` - Next weapon (Mouse Wheel Up)
- `weapon_prev` - Previous weapon (Mouse Wheel Down)

## Demo Weapons

Six demo weapons are provided as examples:

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

### 4. Combat Shotgun
**File:** `resources/weapons/shotgun_data.tres`
**Scene:** `scenes/weapons/shotgun.tscn`

- Semi-automatic fire
- **Hitscan spread** (8 pellets, 30° cone)
- 8 shell magazine
- 8 damage per pellet (64 total at full spread)
- Short range (500 units)
- **Alt fire:** Single high-damage slug (3× damage, 1200 range)

### 5. Arc SMG
**File:** `resources/weapons/smg_data.tres`
**Scene:** `scenes/weapons/smg.tscn`

- Fully automatic fire
- Projectile-based
- 40 round magazine
- Low damage (6) with very fast fire rate (0.07s)

### 6. Plasma Launcher
**File:** `resources/weapons/plasma_launcher_data.tres`
**Scene:** `scenes/weapons/plasma_launcher.tscn`

- Semi-automatic fire
- Projectile-based (primary)
- 6 round magazine
- High damage (35), slow fire rate (0.9s)
- **Alt fire:** Charged hitscan burst (2.5× damage, 1500 range)

## Testing

Comprehensive test suites are provided:

- `tests/test_weapon_system.gd` - Tests BaseWeapon functionality (ammo, reload, firing modes, upgrades)
- `tests/test_weapon_manager.gd` - Tests WeaponManager inventory system
- `tests/test_weapons_expansion.gd` - Tests spread, alternate fire, reload multiplier, new weapons

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
new_weapon.name = "Combat Shotgun"

# Configure stats
new_weapon.firing_mode = BaseWeapon.FiringMode.SEMI_AUTO
new_weapon.attack_type = BaseWeapon.AttackType.HITSCAN
new_weapon.damage = 8.0
new_weapon.fire_rate = 0.7
new_weapon.max_ammo = 8
new_weapon.reload_time = 2.5

# Shotgun spread: 8 pellets over 30 degrees
new_weapon.pellet_count = 8
new_weapon.spread_angle = 30.0
new_weapon.hitscan_range = 500.0

# Alternate fire: single high-damage slug
new_weapon.alt_fire_enabled = true
new_weapon.alt_fire_attack_type = BaseWeapon.AttackType.HITSCAN
new_weapon.alt_fire_damage_multiplier = 3.0
new_weapon.alt_fire_pellet_count = 1
new_weapon.alt_fire_hitscan_range = 1200.0

# Add to weapon manager
weapon_manager.add_weapon(new_weapon)
```

## Future Enhancements

Potential additions to the weapon system:

- Weapon attachments/modifications
- Ammunition types
- Weapon durability/overheating
- Dual wielding support
- Charged shots with hold-to-charge mechanic
- Weapon-specific passive traits
