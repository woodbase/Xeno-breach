# Audio Assets

This directory contains all audio assets for Xeno Breach.

## Directory Structure

- **sfx/** - Sound effects
  - **weapons/** - Weapon firing sounds
  - **impacts/** - Hit and impact sounds
  - **enemies/** - Enemy vocalizations and sounds
  - **ui/** - User interface sounds
- **music/** - Background music tracks
- **ambience/** - Ambient/atmospheric sounds

## Audio Format

Recommended format: **OGG Vorbis** (.ogg)
- Godot's preferred format
- Good compression with quality
- No licensing issues
- Smaller file size than WAV

Alternative formats supported:
- WAV (uncompressed, larger files)
- MP3 (compressed, licensing considerations)

## Required Audio Files

### SFX - Weapons
- `blaster_fire.ogg` - Player weapon firing sound

### SFX - Impacts
- `impact_body.ogg` - Projectile hitting enemy
- `impact_wall.ogg` - Projectile hitting wall/obstacle
- `enemy_death.ogg` - Enemy death sound
- `player_hurt.ogg` - Player taking damage

### SFX - Enemies
- `enemy_alert.ogg` - Enemy entering alert/chase state
- `enemy_attack.ogg` - Enemy attack sound

### SFX - UI
- `button_select.ogg` - Menu button hover/select
- `button_confirm.ogg` - Menu button click/confirm
- `wave_start.ogg` - Wave starting announcement
- `game_over.ogg` - Game over sound

### Music
- `menu_theme.ogg` - Main menu background music
- `combat_theme.ogg` - In-game combat music
- `victory_theme.ogg` - Victory screen music

### Ambience
- `station_ambience.ogg` - Space station ambient sound (looping)

## Notes

- All audio files are optional during development
- The AudioManager will gracefully skip missing files
- Replace placeholder files with actual audio assets
- Keep file sizes reasonable (compress/optimize audio)
- Test audio levels to ensure consistent volume
