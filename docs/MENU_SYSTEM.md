# Menu System Documentation

This document describes the complete menu system implementation in Xeno-breach.

## Overview

The menu system provides a complete user interface for navigating the game, including:
- Main menu for starting the game
- Pause menu for in-game controls
- Victory and game over screens
- Scene transitions and state management

## Components

### 1. Main Menu

**Location:** `scenes/ui/main_menu.tscn` / `scripts/ui/main_menu.gd`

**Features:**
- Title screen with game branding
- "INITIATE DEPLOYMENT" button to start the game
- "ABORT / EXIT" button to quit
- Co-op player count selector (1-4 players)
- Integrated with `GameStateManager` for state transitions
- Sound effects on button hover/focus

**Flow:**
```
Main Menu → [Start] → Intro Screen → Game Level
         → [Quit] → Exit Application
```

**Code Integration:**
```gdscript
func _on_start_pressed() -> void:
    AudioManager.play_ui("button_confirm")
    GameStateManager.change_state(GameStateManager.State.INTRO)
    get_tree().change_scene_to_file("res://scenes/ui/intro_screen.tscn")
```

### 2. Pause Menu

**Location:** `scenes/ui/pause_menu.tscn` / `scripts/ui/pause_menu.gd`

**Features:**
- Semi-transparent overlay during gameplay
- Four action buttons:
  - **RESUME** - Returns to gameplay
  - **RESTART LEVEL** - Reloads current level
  - **MAIN MENU** - Returns to main menu
  - **QUIT GAME** - Exits application
- Signal-based architecture for loose coupling
- Runs with `PROCESS_MODE_WHEN_PAUSED` to stay interactive

**Signals:**
- `resume_pressed`
- `restart_pressed`
- `main_menu_pressed`
- `quit_pressed`

**Usage in Levels:**
```gdscript
# In test_level.gd
hud.resume_pressed.connect(_toggle_pause)
hud.restart_pressed.connect(_restart_run)
hud.quit_pressed.connect(func() -> void: get_tree().quit())
```

**Pause Toggle Implementation:**
```gdscript
func _toggle_pause() -> void:
    if get_tree().paused:
        get_tree().paused = false
        GameStateManager.change_state(GameStateManager.State.PLAYING)
        hud.hide_pause_menu()
    else:
        get_tree().paused = true
        GameStateManager.change_state(GameStateManager.State.PAUSED)
        hud.show_pause_menu()
```

### 3. Game State Manager

**Location:** `scripts/systems/game_state_manager.gd` (Autoload Singleton)

**States:**
- `MAIN_MENU` - Main menu screen
- `INTRO` - Story introduction
- `PLAYING` - Active gameplay
- `PAUSED` - Game paused
- `GAME_OVER` - Player died
- `VICTORY` - Level completed
- `DEMO_END` - All demo content completed

**State Transitions:**
```gdscript
func change_state(new_state: State) -> void:
    if new_state == current_state:
        return
    var old_state: State = current_state
    current_state = new_state
    state_changed.emit(new_state, old_state)
```

### 4. Level Integration

**Location:** `scripts/levels/level_base.gd`

**Menu-Related Functions:**

**`go_to_main_menu()`**
```gdscript
func go_to_main_menu() -> void:
    if _transitioning:
        return
    _transitioning = true
    get_tree().paused = false
    GameStateManager.change_state(GameStateManager.State.MAIN_MENU)
    get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
```

**`go_to_next_level()`**
```gdscript
func go_to_next_level() -> void:
    if _transitioning:
        return
    if not next_level_scene_path.is_empty():
        if ResourceLoader.exists(next_level_scene_path):
            _transitioning = true
            get_tree().paused = false
            GameStateManager.next_level_scene_path = next_level_scene_path
            GameStateManager.change_state(GameStateManager.State.VICTORY)
            get_tree().change_scene_to_file(VICTORY_SCREEN_SCENE_PATH)
            return
    _on_no_next_level()
```

**Restart Level:**
```gdscript
# In test_level.gd
func _restart_run() -> void:
    if _transitioning:
        return
    _transitioning = true
    get_tree().paused = false
    get_tree().reload_current_scene()
```

## Complete Flow Diagram

```
┌─────────────┐
│ Main Menu   │
│             │
│ • Start     │◄─────────────┐
│ • Quit      │              │
└──────┬──────┘              │
       │                     │
       ▼                     │
┌─────────────┐              │
│Intro Screen │              │
│             │              │
│ • Continue  │              │
│ • Skip      │              │
└──────┬──────┘              │
       │                     │
       ▼                     │
┌─────────────────────────┐  │
│   Game Level (Playing)  │  │
│                         │  │
│  ┌──────────────────┐   │  │
│  │   Pause Menu     │   │  │
│  │  • Resume        │   │  │
│  │  • Restart       │───┼──┘ (reload scene)
│  │  • Main Menu     │───┼──┐
│  │  • Quit          │   │  │
│  └──────────────────┘   │  │
│                         │  │
│  Game Over / Victory    │  │
│  • Retry (restart)      │  │
│  • Menu                 │──┤
└─────────────────────────┘  │
                             │
                             └─────┐
                                   │
                                   ▼
                            ┌─────────────┐
                            │ Main Menu   │
                            └─────────────┘
```

## Key Input Actions

### Pause Action
- **Default Key:** ESC
- **Action Name:** "pause"
- **Behavior:** Toggles pause menu on/off during gameplay

### Accept Actions
- **Actions:** "fire" or "ui_accept"
- **Usage:** Can trigger start game or retry actions in some screens

## Audio Integration

**UI Sounds:**
- `button_select` - Played on button hover/focus
- `button_confirm` - Played on button press
- `game_over` - Played when all players die
- `wave_start` - Played when new wave begins

**Music Tracks:**
- `menu_theme` - Main menu music
- `combat_theme` - Gameplay music
- `victory_theme` - Victory screen music

**Implementation:**
```gdscript
# Sound effects
AudioManager.play_ui("button_confirm")

# Music
AudioManager.play_music("menu_theme")
AudioManager.stop_music()
```

## Testing

**Test Suite:** `tests/test_menu_system.gd`

**Coverage:**
- Pause menu visibility toggle
- Signal emission for all buttons
- State manager transitions
- Button focus behavior

**Running Tests:**
Load the test scene in Godot editor or run via command line with appropriate test runner.

## Implementation Checklist

All required features have been implemented:

- ✅ **Main menu** - Complete with start and quit functionality
- ✅ **Start game** - Transitions through intro screen to game level
- ✅ **Restart level** - Available in pause menu, reloads current scene
- ✅ **Quit game** - Available in main menu and pause menu

## Architecture Patterns

### Signal-Based Communication
The pause menu uses signals instead of direct method calls, allowing for flexible integration:
```gdscript
# PauseMenu emits signals
pause_menu.restart_pressed.emit()

# Level connects to signals
hud.restart_pressed.connect(_restart_run)
```

### State-Driven Design
All menu transitions update the global game state:
```gdscript
GameStateManager.change_state(GameStateManager.State.PAUSED)
```

### Scene Transition Safety
Transitions use a `_transitioning` flag to prevent race conditions:
```gdscript
if _transitioning:
    return
_transitioning = true
```

## Future Enhancements

Potential improvements for the menu system:
- Settings menu for audio, video, and controls
- Level selection screen
- Save/load game functionality
- Statistics and achievements screen
- Multiplayer lobby system
- Customizable key bindings UI

## Related Documentation

- [Architecture Overview](architecture.md)
- [Audio System](ADDING_AUDIO.md)
- [Co-op System](../scripts/systems/coop_manager.gd)
- [Game State Management](../scripts/systems/game_state_manager.gd)
