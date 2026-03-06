# Xeno Breach — Architecture Reference

## Guiding Principles

| Principle | How it is applied |
|---|---|
| Composition over inheritance | HealthComponent, BaseWeapon are child nodes, not base classes |
| Signal-driven communication | Systems emit signals; nothing holds direct cross-system references |
| Data-driven config | WeaponData, EnemyData, WaveData are `Resource` subclasses |
| Single Responsibility | Movement, combat, and health are separate GDScript classes |
| No circular dependencies | Dependency direction is always top-down (Level → Systems → Components) |

---

## System Map

```
scenes/levels/test_level.tscn
└─ scripts/levels/test_level.gd   ← orchestration only

    ├── Player (player.tscn)
    │    ├── scripts/core/player_controller.gd  ← input, movement, fire dispatch
    │    ├── scripts/core/health_component.gd   ← health state + signals
    │    └── scripts/combat/base_weapon.gd      ← spawns Projectile nodes
    │         └── scripts/combat/projectile.gd  ← movement + damage on contact
    │
    ├── WaveSpawner
    │    └── scripts/systems/wave_spawner.gd    ← spawns & tracks enemy waves
    │         └── EnemyBase (enemy_base.tscn)
    │              ├── scripts/ai/enemy_base.gd  ← Idle/Chase/Attack state machine
    │              └── scripts/core/health_component.gd
    │
    └── HUD (hud.tscn)
         └── scripts/ui/hud.gd                  ← binds to HealthComponent signals

GameStateManager (autoload)
    └── scripts/systems/game_state_manager.gd   ← global state enum + signal
```

---

## Key Design Decisions

### HealthComponent (composition)

Any entity that can take damage owns a `HealthComponent` Node child.
Projectiles query `body.get_node_or_null("HealthComponent")` to apply damage.
This means zero type-checking of specific enemy or player classes.

```gdscript
# Projectile._on_body_entered — no player/enemy coupling
var health: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
if health != null:
    health.take_damage(damage)
```

### Damage contract

Any node exposing `take_damage(amount: float)` participates.
In practice, this project uses `HealthComponent` as the default damage receiver
to keep all health rules in one place.

### Signal bus (decoupling)

| Emitter | Signal | Typical listener |
|---|---|---|
| HealthComponent | `died` | EnemyBase, PlayerController |
| HealthComponent | `health_changed` | HUD |
| PlayerController | `died` | TestLevel → GameStateManager |
| WaveSpawner | `wave_started` | TestLevel (logging / UI) |
| WaveSpawner | `all_waves_completed` | TestLevel → GameStateManager |
| GameStateManager | `state_changed` | Any system that cares about game state |

### No monolithic manager

`GameStateManager` is the only autoload.  
It holds exactly one piece of state (the enum) and one signal.  
All game-play logic lives in scene scripts that are loaded and freed with the scene.

### Data Resources

`WeaponData`, `EnemyData`, and `WaveData` extend Godot's `Resource`.  
They can be authored in the inspector, serialised to `.tres` files, and swapped at runtime
without touching script logic.

---

## Physics Layer Map

| Layer | Bitmask | Used by |
|---|---|---|
| 1 — Player | 1 | Player CharacterBody2D |
| 2 — Enemies | 2 | Enemy CharacterBody2D |
| 3 — World | 4 | Static geometry |
| 4 — Player Projectiles | 8 | Projectile Area2D |
| 5 — Enemy Projectiles | 16 | EnemyProjectile Area2D |

Player projectile `collision_mask = 6` → hits enemies (2) + world (4).

---

## Extending the Architecture

### New enemy type
1. Duplicate `scenes/enemies/enemy_base.tscn`.
2. Override exported properties (speed, health, damage, ranges).
3. Optionally subclass `enemy_base.gd` for unique behaviour.

### New weapon
1. Duplicate `scenes/weapons/base_weapon.tscn`.
2. Create a new `WeaponData` resource and assign it to the scene.
3. Optionally subclass `base_weapon.gd` for spread, burst, or charge shots.

### Status effects
Extend `HealthComponent` with a modifiers array. Each modifier is a `Resource`
subclass that intercepts `take_damage` before applying it.

### Co-op
`PlayerController` is a self-contained `CharacterBody2D`. Instantiate multiple
player scenes; `WaveSpawner` accepts any `Node2D` as target — swap to a group or
nearest-target strategy without touching enemy logic.
