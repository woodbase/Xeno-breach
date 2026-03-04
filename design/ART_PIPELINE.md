# Xeno Breach – Art Pipeline

Version: 0.1

This document defines how art assets should be created, named, and imported into the project.

Following this pipeline ensures consistency, performance, and maintainability.

---

# 1. Art Direction Summary

The visual direction of Xeno Breach is:

Industrial  
Worn  
Functional  
Cold  
Dangerous

The environment should feel like working infrastructure rather than futuristic luxury.

Avoid:

- cartoon styles
- overly clean environments
- bright cyberpunk color palettes

---

# 2. Asset Categories

Assets fall into several categories.

Environment

- walls
- floors
- ceilings
- corridors

Props

- crates
- machines
- terminals
- equipment
- industrial objects

Characters

- player
- enemies
- entities

UI

- icons
- panels
- HUD elements

Audio

- ambience
- alarms
- UI sounds

---

# 3. Naming Conventions

Use clear and consistent asset names.

Textures

tex_wall_industrial_01  
tex_floor_metal_01

Props

prop_crate_metal_01  
prop_terminal_wall_01

Characters

char_player  
char_entity_stalker

UI

ui_panel_main  
ui_button_primary  
icon_health  
icon_ammo

Audio

sfx_alarm_breach  
sfx_ui_click  
amb_facility_hum

---

# 4. Texture Guidelines

Textures should contain visual wear.

Preferred characteristics:

- scratches
- dust
- metal wear
- oil stains
- industrial markings

Avoid perfectly clean surfaces.

Wear and imperfections improve realism.

---

# 5. Texture Resolution

Recommended sizes:

Small props  
512 × 512

Medium assets  
1024 × 1024

Large surfaces  
2048 × 2048

Avoid unnecessarily large textures.

---

# 6. File Formats

Preferred formats:

Textures  
PNG

Normal maps  
PNG

Models  
GLTF or GLB

Audio  
WAV

---

# 7. Asset Folder Structure

Assets should follow this structure.

assets/

textures/  
walls  
floors  
props  

models/  
props  
characters  
environment  

materials/

audio/  
ambience  
ui  
alarms  

ui/  
icons  
panels  

fonts/

---

# 8. Importing Assets

All assets must exist inside the project directory.

Avoid referencing files outside the repository.

Textures should generally use filtering enabled.

Repeat should be disabled unless required.

---

# 9. Lighting Compatibility

Materials must work well in dark environments.

Avoid materials that:

- emit excessive light
- have overly reflective surfaces

Lighting should be controlled by the environment.

---

# 10. Performance Guidelines

To maintain performance:

- limit texture sizes
- reuse assets where possible
- avoid overly complex models
- use instancing for repeated props

---

# 11. Versioning Assets

If an asset is replaced or improved, create a new version.

Example:

prop_terminal_wall_01_v2

Avoid deleting assets that may already be used in scenes.

---

# 12. Future Art Systems

Planned art expansions include:

- alien environments
- breach anomalies
- dynamic lighting effects
- environmental storytelling props

All future assets should follow the same art pipeline.
