# Audio Assets

Place audio files in the directories below. They are loaded at runtime by the
**AudioManager** autoload (**Project → Project Settings → Autoload → AudioManager**).

Supported formats: `.ogg` (recommended for loops and music), `.wav` (recommended for
short one-shot SFX).

---

## Directory layout

```
assets/audio/
├── sfx/
│   ├── weapons/
│   │   └── blaster_fire.ogg        → AudioManager SOUNDS["weapon_fire"]
│   ├── impacts/
│   │   ├── impact_body.ogg         → AudioManager SOUNDS["impact_body"]
│   │   ├── impact_wall.ogg         → AudioManager SOUNDS["impact_wall"]
│   │   ├── enemy_death.ogg         → AudioManager SOUNDS["enemy_death"]
│   │   └── player_hurt.ogg         → AudioManager SOUNDS["player_hurt"]
│   ├── enemies/
│   │   ├── enemy_alert.ogg         → AudioManager SOUNDS["enemy_alert"]
│   │   └── enemy_attack.ogg        → AudioManager SOUNDS["enemy_attack"]
│   └── ui/
│       ├── button_select.ogg       → AudioManager SOUNDS["button_select"]
│       ├── button_confirm.ogg      → AudioManager SOUNDS["button_confirm"]
│       ├── wave_start.ogg          → AudioManager SOUNDS["wave_start"]
│       └── game_over.ogg           → AudioManager SOUNDS["game_over"]
├── music/
│   ├── menu_theme.ogg              → AudioManager SOUNDS["menu_theme"]
│   ├── combat_theme.ogg            → AudioManager SOUNDS["combat_theme"]
│   └── victory_theme.ogg           → AudioManager SOUNDS["victory_theme"]
└── ambience/
    └── station_hum.ogg             → AudioManager SOUNDS["station_ambience"]
```

---

## When sounds are triggered

| Event | Sound key | Caller |
|---|---|---|
| Player fires weapon | `"weapon_fire"` | `test_level.gd` → `_on_player_fired()` |
| Player receives damage | `"player_hurt"` | `test_level.gd` → `_on_player_damaged_audio()` |
| Player dies | `"game_over"` (UI) | `test_level.gd` → `_on_player_died()` |
| Enemy alerts (spots player) | `"enemy_alert"` | `enemy_base.gd` → `_update_state()` |
| Enemy attacks | `"enemy_attack"` | `enemy_base.gd` → `_do_attack()` |
| Enemy dies | `"enemy_death"` | `test_level.gd` → `_on_enemy_spawned()` |
| Projectile hits entity | `"impact_body"` | `projectile.gd` → `_on_body_entered()` |
| Projectile hits wall | `"impact_wall"` | `projectile.gd` → `_on_body_entered()` |
| Wave starts | `"wave_start"` (UI) | `test_level.gd` → `_on_wave_started()` |
| Button hover/focus | `"button_select"` (UI) | `main_menu.gd` |
| Button confirmed | `"button_confirm"` (UI) | `main_menu.gd` |

Background music is managed explicitly by each scene:

| Scene / event | Music |
|---|---|
| `main_menu.gd._ready()` | `"menu_theme"` |
| `test_level.gd._ready()` | `"combat_theme"` |
| `test_level.gd` — all waves cleared | `"victory_theme"` |
| `test_level.gd._on_player_died()` | *(music stopped)* |

## Audio buses

AudioManager creates these buses at startup if they don't already exist:

| Bus | Used for |
|---|---|
| `SFX` | Positional sound effects (AudioStreamPlayer2D) |
| `Music` | Background music loop |
| `UI` | Non-positional interface sounds |
| `Ambience` | Looping ambient background layer |
