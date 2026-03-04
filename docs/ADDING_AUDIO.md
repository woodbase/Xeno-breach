# Adding Audio Files to Xeno Breach

The audio system is now fully integrated into Xeno Breach! This guide explains how to add actual audio files to make the game come alive with sound.

## Quick Start

The audio system is ready to use - just add audio files to the appropriate directories and the game will automatically play them. All audio files are **optional** - the game will work fine without them during development.

## Where to Add Audio Files

### Sound Effects

Place your SFX files in these locations:

#### Weapons (`assets/audio/sfx/weapons/`)
- `blaster_fire.ogg` - Plays when the player fires their weapon

#### Impacts (`assets/audio/sfx/impacts/`)
- `impact_body.ogg` - Plays when a projectile hits an enemy
- `impact_wall.ogg` - Plays when a projectile hits a wall/obstacle
- `enemy_death.ogg` - Plays when an enemy dies
- `player_hurt.ogg` - Plays when the player takes damage

#### Enemies (`assets/audio/sfx/enemies/`)
- `enemy_alert.ogg` - Plays when an enemy spots and starts chasing the player
- `enemy_attack.ogg` - Plays when an enemy attacks

#### UI (`assets/audio/sfx/ui/`)
- `button_select.ogg` - Plays when hovering over menu buttons
- `button_confirm.ogg` - Plays when clicking a button
- `wave_start.ogg` - Plays at the start of each wave
- `game_over.ogg` - Plays when the player dies

### Background Music

Place music files in `assets/audio/music/`:

- `menu_theme.ogg` - Plays in the main menu
- `combat_theme.ogg` - Plays during combat (all waves)
- `victory_theme.ogg` - Plays on the victory screen

### Ambient Sounds

Place ambient loops in `assets/audio/ambience/`:

- `station_ambience.ogg` - Looping station background sound during gameplay

## Audio Format Recommendations

### Recommended: OGG Vorbis (.ogg)
- Godot's preferred format
- Good compression with high quality
- No licensing issues
- Smaller file size than WAV

### Alternative: WAV (.wav)
- Uncompressed audio
- Best for very short sounds (< 1 second)
- Larger file sizes

### To Convert to OGG

Use a tool like Audacity (free):
1. Open your audio file in Audacity
2. File → Export → Export as OGG
3. Set quality to 5-7 (good balance of quality/size)
4. Save to the appropriate directory

## Audio Integration Points

The following events now trigger sounds automatically:

### Player Actions
- **Weapon firing** - Triggered every time the player shoots
- **Taking damage** - Plays hurt sound when hit by enemies
- **Death** - Game over sound when player dies

### Enemy Behavior
- **Enemy alert** - When enemy enters chase state (spots player)
- **Enemy attack** - When enemy performs attack
- **Enemy death** - When enemy is killed

### UI Events
- **Button hover** - Mouse over menu buttons
- **Button click** - Clicking menu buttons
- **Wave start** - Beginning of each wave
- **Game over** - Player death screen
- **Victory** - Completing all waves

### Background Audio
- **Menu music** - Plays on main menu
- **Combat music** - Plays during gameplay
- **Victory music** - Plays on victory screen
- **Station ambience** - Looping background during gameplay

## Audio System Features

### Spatial Audio
Sound effects (weapon fire, impacts, enemy sounds) use **positional 2D audio**:
- Sounds get quieter the further they are from the camera
- Max distance: 1000 pixels
- Automatically handled by AudioStreamPlayer2D nodes

### Audio Buses
The system uses 4 separate audio buses for mixing:
- **SFX** - All sound effects (weapons, impacts, enemies)
- **Music** - Background music tracks
- **UI** - Menu and interface sounds
- **Ambience** - Atmospheric background loops

### Volume Control (Ready for Settings Menu)
The AudioManager provides methods for volume control:
```gdscript
AudioManager.set_bus_volume("SFX", 0.7)  # 0.0 to 1.0
AudioManager.set_bus_mute("Music", true)
```

## Testing Your Audio

1. Add audio files to the appropriate directories
2. Launch the game
3. Verify sounds play at the right moments:
   - Menu: Button hover and click sounds, background music
   - Gameplay: Weapon fire, enemy alerts, impacts, damage
   - Waves: Wave start announcement
   - End screens: Victory or game over music

## Finding Free Audio Assets

### Sound Effects
- **Freesound.org** - Large library of CC-licensed sounds
- **OpenGameArt.org** - Game-focused audio assets
- **Kenney.nl** - High-quality game audio packs

### Music
- **Incompetech.com** - Royalty-free music by Kevin MacLeod
- **FreeMusicArchive.org** - Creative Commons music
- **OpenGameArt.org** - Game music tracks

### Tools for Creating Audio
- **Audacity** (free) - Audio editing and conversion
- **LMMS** (free) - Music creation
- **ChipTone** (free) - Retro sound effect generator
- **Bfxr** (free) - Sound effect generator

## Notes

- All audio files are **optional** - missing files won't cause errors
- The AudioManager checks if files exist before trying to play them
- OGG format is recommended for best compatibility and size
- Keep sound effects short (< 2 seconds) for best performance
- Music files can be longer but should loop smoothly

## Customizing Audio

To add new sounds or change file paths, edit `scripts/systems/audio_manager.gd`:

```gdscript
const SOUNDS := {
	"my_new_sound": "res://assets/audio/sfx/my_sound.ogg",
	# ... existing sounds
}
```

Then call it from your code:
```gdscript
AudioManager.play_sfx("my_new_sound", position)
```

Happy sound designing! 🎵
