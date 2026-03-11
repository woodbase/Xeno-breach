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

MissionManager (autoload)
    └── scripts/systems/mission_manager.gd      ← tracks active missions, routes event triggers
         ├── scripts/systems/mission.gd          ← runtime mission instance (state machine)
         └── scripts/systems/mission_objective.gd ← base class; concrete types:
              ├── kill_enemy_objective.gd         ← kill N enemies (optional type filter)
              ├── reach_area_objective.gd         ← reach world position within radius
              ├── activate_terminal_objective.gd  ← activate specific terminal
              └── retrieve_item_objective.gd      ← collect specific item
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

### Damageable contract

`scripts/combat/damageable.gd` documents the expected interface.
Any node exposing `take_damage(amount: float)` participates.
The HealthComponent is the preferred implementation.

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

## Enemy Framework

### EnemyBase (`scripts/ai/enemy_base.gd`)

All enemies extend `EnemyBase` (a `CharacterBody2D`). The class owns a four-state AI:

| State | Condition | Behaviour |
|---|---|---|
| IDLE | No target and patrol disabled | Decelerates to rest |
| PATROL | No target and `patrol_enabled = true` | Shuttles between two auto-generated waypoints |
| CHASE | Target within `detection_range` | Moves toward target at `move_speed` |
| ATTACK | Target within `attack_range` | Fires projectile or applies melee damage on cooldown |

### Health and Damage

Every enemy carries a `HealthComponent` child node. Damage is applied by:

```gdscript
var hc: HealthComponent = enemy.get_node_or_null("HealthComponent")
if hc != null:
    hc.take_damage(amount)
```

### Death State

When `HealthComponent.died` fires, `EnemyBase`:
1. Sets `_is_dying = true` and calls `set_physics_process(false)` — all per-frame work stops immediately.
2. Disables the collision shape and clears collision layers.
3. Fades `Body` to transparent over 0.3 s via a `Tween`.
4. Calls `queue_free()` and emits `EnemyBase.died`.

### Performance Optimisations

| Technique | Where | Detail |
|---|---|---|
| Throttled state updates | `EnemyBase._physics_process` | AI state machine runs at most every `_STATE_UPDATE_INTERVAL` (0.1 s) |
| Staggered initialisation | `EnemyBase._ready` | First state tick is offset by a random fraction of the interval to spread CPU spikes |
| Off-screen throttle | `EnemyBase` + `VisibleOnScreenNotifier2D` | State interval increases to `_STATE_UPDATE_INTERVAL_OFFSCREEN` (0.25 s) while the enemy is outside the viewport |
| Squared-distance caching | `EnemyBase._update_state` | `_attack_range_sq` and `_detection_range_sq` cache `range²` to avoid `sqrt` every tick |
| Rate-limited tree search | `EnemyBase._ensure_target` | Scene-tree player lookup is throttled to once per `_TARGET_SEARCH_INTERVAL` (0.5 s) per enemy |
| Disable on death | `EnemyBase._on_health_died` | `set_physics_process(false)` called immediately so dead enemies consume no CPU |
| Hazard idle-pause | `EnvironmentalHazard` | `_physics_process` is disabled while no bodies overlap; re-enabled on `body_entered` |

### Data-Driven Configuration

Assign an `EnemyData` resource to `EnemyBase.data`. On `_ready()` all exported stats
(speed, health, ranges, damage, patrol settings, projectile) are applied from the resource.
Call `apply_data()` to re-apply after a hot-swap.

Pre-authored resources live in `resources/enemies/`:

| File | Enemy | Role |
|---|---|---|
| `xeno_crawler_data.tres` | Xeno Crawler | Melee, patrols |
| `enemy_brute_data.tres` | Brute | Slow, high HP, ranged |
| `enemy_striker_data.tres` | Striker | Fast, low HP, ranged |
| `elite_xeno_crawler_data.tres` | Elite Xeno Crawler | Elite melee with `is_elite = true` |
| `elite_brute_data.tres` | Elite Brute | Elite ranged brute with `is_elite = true` |
| `elite_striker_data.tres` | Elite Striker | Elite ranged striker with `is_elite = true` |
| `boss_data.tres` | Xenomorph Prime | High-HP boss (500 HP) with phase transitions |

#### Elite Enemies

Set `EnemyData.is_elite = true` to mark a variant as elite. `EnemyBase` will
automatically apply a golden body tint and ensure the hit-flash resets to that
tint rather than white. Elite resources carry roughly double the HP and damage
of their base counterparts and award more score via `score_value`.

#### Boss Encounters

Scene: `scenes/enemies/boss.tscn`  
Script: `scripts/ai/boss_enemy.gd` (`BossEnemy extends EnemyBase`)  
Data: `resources/enemies/boss_data.tres`

`BossEnemy` adds a two-phase combat system on top of `EnemyBase`:

| Phase | Trigger | Behaviour change |
|---|---|---|
| 1 | Default | Standard EnemyBase stats from `boss_data.tres` |
| 2 | HP < 50 % | `move_speed × phase_2_speed_mult`, `attack_cooldown × phase_2_cooldown_mult`, body tint turns crimson |

Connect to `BossEnemy.phase_changed(new_phase: int)` to drive HUD / audio feedback.  
`BossEnemy.get_current_phase()` returns the current phase (1 or 2).

### Demo Enemy — Xeno Crawler

Scene: `scenes/enemies/xeno_crawler.tscn`  
Data: `resources/enemies/xeno_crawler_data.tres`

The Xeno Crawler is a close-range melee enemy. It patrols its spawn area, detects the
player within 180 units, chases, and attacks at 45 units with a 0.8 s cooldown.
It has 40 HP and a green tint to distinguish it visually.

### Ranged Enemies — Brute and Striker

Scene (Brute): `scenes/enemies/enemy_brute.tscn`  
Scene (Striker): `scenes/enemies/enemy_striker.tscn`

Both enemy types fire `enemy_projectile.tscn` at the player from a distance.
The Brute is slow and tanky (80 HP); the Striker is fast and fragile (35 HP).

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
2. Create a new `EnemyData` resource in `resources/enemies/` and set all stats.
3. Assign the resource to the `data` export on the scene root — stats are applied on `_ready()`.
4. Optionally subclass `enemy_base.gd` for unique behaviour (charge attacks, special abilities, etc.).
5. Set `is_elite = true` on the data resource to have `EnemyBase` automatically apply the golden elite tint.

### New boss encounter
1. Duplicate `scenes/enemies/boss.tscn`.
2. Create a new `EnemyData` resource with high `max_health` stats.
3. Assign the `BossEnemy` script (`scripts/ai/boss_enemy.gd`) to the scene root.
4. Adjust `phase_2_speed_mult` and `phase_2_cooldown_mult` on the root node for the desired phase-2 difficulty spike.
5. Connect `phase_changed` in the owning level to trigger HUD and audio feedback.

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

### Biomes
Create a `BiomeProfile` resource (`resources/biomes/*.tres`) to define ambient
and light colours plus signature hazards. Assign it to the level root
(`LevelBase.biome_profile`) and the `LevelLighting` will apply the palette.

### Environmental hazards
Use `EnvironmentalHazard` (Area2D) for radiation, coolant spills, or cryo vents.
Attach a `CollisionShape2D`, set `damage_per_second` and `tick_interval`, and
toggle `affects_players/enemies` as needed. Place hazards in a `Hazards` node
within the level scene to keep layout organised.
