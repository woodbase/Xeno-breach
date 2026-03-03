# Xeno Breach

**Fast, aggressive twin-stick sci-fi shooter — built in Godot 4.x with typed GDScript.**

Fight through breach-infested stations in high-octane combat designed for speed, clarity, and replayability.

---

## Engine & Language

- **Engine:** Godot 4.2+
- **Language:** Typed GDScript (no C#)
- **Renderer:** Forward Plus

---

## Project Structure

```
scenes/          Godot scene files (.tscn)
  player/        Player scene
  enemies/       Enemy scenes
  weapons/       Weapon and projectile scenes
  levels/        Level scenes
  ui/            HUD and UI scenes

scripts/         GDScript source files (.gd)
  core/          Player controller, health component
  combat/        Weapon, projectile, damageable interface
  ai/            Enemy base with state machine
  systems/       Wave spawner, game state manager
  data/          Resource data containers
  utilities/     Constants, helpers
  ui/            HUD script
  levels/        Level orchestration scripts

assets/          Raw game assets (sprites, audio, etc.)
docs/            Architecture and design documentation
tests/           Unit and integration test scripts
```

---

## Core Architecture

- **Composition over inheritance** — HealthComponent, WeaponMount are reusable child nodes
- **Signal-driven communication** — systems never directly reference each other's internals
- **Data-driven** — WeaponData, EnemyData, WaveData Resources separate config from logic
- **No monolithic manager** — GameStateManager is the only autoload; everything else is local
- **Single Responsibility** — movement, combat, and health are separate classes

See [`docs/architecture.md`](docs/architecture.md) for the full system design.

---

## Input (default)

| Action     | Binding       |
|------------|---------------|
| Move       | WASD          |
| Aim        | Mouse         |
| Fire       | Left Mouse    |
| Pause      | Escape        |

---

## Getting Started

1. Open the project in **Godot 4.2+**
2. Run the project (starts at `scenes/ui/main_menu.tscn`)
3. Start a run and survive five waves of enemies

---

## Design Pillars

1. Immediate and responsive controls
2. High combat clarity
3. Scalable enemy systems
4. Modular architecture
5. Replayable wave-based structure
6. Designed for future co-op
7. Performance-conscious (PC first, mobile-ready)

