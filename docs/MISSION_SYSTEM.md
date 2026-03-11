# Mission / Quest System

## Overview

The mission system lets designers define goals (objectives) that the player must complete. It is intentionally lightweight for the demo but designed to scale into a full quest system.

**Autoload singleton:** `MissionManager` (registered in `project.godot`)

---

## Core Classes

| Class | File | Role |
|---|---|---|
| `MissionData` | `scripts/data/mission_data.gd` | Resource template for a mission (serialisable as `.tres`) |
| `Mission` | `scripts/systems/mission.gd` | Runtime instance; tracks state and objectives |
| `MissionObjective` | `scripts/systems/mission_objective.gd` | Base class for all objective types |
| `KillEnemyObjective` | `scripts/systems/kill_enemy_objective.gd` | Require the player to kill N enemies (with optional type filter) |
| `ReachAreaObjective` | `scripts/systems/reach_area_objective.gd` | Require the player to reach a world position |
| `ActivateTerminalObjective` | `scripts/systems/activate_terminal_objective.gd` | Require the player to activate a specific terminal |
| `RetrieveItemObjective` | `scripts/systems/retrieve_item_objective.gd` | Require the player to collect a specific item |

---

## Starting a Mission

### From a MissionData resource

```gdscript
var data: MissionData = preload("res://resources/missions/find_keycard.tres")
var mission: Mission = MissionManager.start_mission(data)
```

### Programmatically

```gdscript
var mission: Mission = Mission.new()
mission.mission_id = "escape"
mission.mission_name = "Escape the facility"

var obj := KillEnemyObjective.new("Eliminate the guards", 5, "xeno_crawler")
mission.add_objective(obj)

MissionManager.start_mission_direct(mission)
```

---

## Event Triggers

Game systems call these methods on `MissionManager` to drive mission progress. They are wired to the appropriate objective types automatically.

| Method | Wired by | Objective type |
|---|---|---|
| `MissionManager.report_enemy_killed(enemy_type)` | `EnemyBase._on_health_died()` | `KillEnemyObjective` |
| `MissionManager.report_terminal_activated(terminal_id)` | Terminal interaction code | `ActivateTerminalObjective` |
| `MissionManager.report_item_retrieved(item_id)` | Item pickup code | `RetrieveItemObjective` |
| `MissionManager.check_player_position(position)` | `test_level.gd._process()` | `ReachAreaObjective` |

---

## Mission States

```
INACTIVE → ACTIVE → COMPLETED
                  ↘ FAILED
```

- A mission starts in `INACTIVE` and becomes `ACTIVE` via `Mission.start()`.
- It auto-completes when every objective is complete.
- Call `Mission.fail()` or `MissionManager.clear_all_missions()` to fail active missions.

---

## Signals

### MissionManager

| Signal | When |
|---|---|
| `mission_started(mission)` | `start_mission()` or `start_mission_direct()` called |
| `mission_completed(mission)` | All objectives complete |
| `mission_failed(mission)` | `fail()` called on an active mission |
| `objective_completed(mission, objective)` | Any single objective completes |

### Mission

| Signal | When |
|---|---|
| `state_changed(new_state)` | State changes to ACTIVE, COMPLETED, or FAILED |
| `objective_completed(objective)` | Any objective inside this mission completes |
| `completed` | All objectives done |
| `failed` | Mission failed |

---

## Adding a New Objective Type

1. Create `scripts/systems/my_objective.gd` extending `MissionObjective`.
2. Override `_init()` to accept parameters and call `super._init(desc, target)`.
3. Add a `report_*()` method that calls `increment_progress()` or `complete()`.
4. Add a corresponding `report_*()` method to `MissionManager` that iterates active missions and forwards to your objective type.

---

## Enemy Type Identifiers

Enemy kills are forwarded with the `enemy_type` field from the `EnemyData` resource. Current values:

| Enemy | `enemy_type` |
|---|---|
| Xeno Crawler | `xeno_crawler` |
| Brute | `enemy_brute` |
| Striker | `enemy_striker` |

Use these strings when constructing `KillEnemyObjective` with a type filter:

```gdscript
KillEnemyObjective.new("Eliminate crawlers", 10, "xeno_crawler")
```
