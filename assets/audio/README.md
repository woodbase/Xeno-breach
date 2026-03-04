# Audio Assets

Place audio files here and assign them to the **SoundManager** autoload in the Godot
editor (**Project → Project Settings → Autoload → SoundManager**).

Supported formats: `.ogg` (recommended for loops), `.wav` (recommended for short SFX).

---

## Directory layout

```
assets/audio/
├── sfx/          — one-shot sound effects
│   ├── shoot.ogg         → SoundManager.sfx_shoot
│   ├── player_hurt.ogg   → SoundManager.sfx_player_hurt
│   ├── player_die.ogg    → SoundManager.sfx_player_die
│   ├── enemy_die.ogg     → SoundManager.sfx_enemy_die
│   └── impact.ogg        → SoundManager.sfx_impact
└── music/        — looping background tracks
    ├── menu.ogg           → SoundManager.music_menu
    └── gameplay.ogg       → SoundManager.music_gameplay
```

---

## Triggering audio

| Event | SFX key | Called from |
|---|---|---|
| Player fires weapon | `"shoot"` | `BaseWeapon.fire()` |
| Player receives damage | `"player_hurt"` | `PlayerController` (via HealthComponent signal) |
| Player dies | `"player_die"` | `PlayerController._on_health_died()` |
| Enemy dies | `"enemy_die"` | `EnemyBase._on_health_died()` |
| Projectile hits entity | `"impact"` | `Projectile._on_body_entered()` |

Background music is switched automatically when `GameStateManager` changes state:

| Game state | Music key |
|---|---|
| `MAIN_MENU` | `"menu"` |
| `PLAYING` | `"gameplay"` |
| `PAUSED` | *(no change — music continues)* |
| `GAME_OVER` / `VICTORY` | *(music stops)* |
