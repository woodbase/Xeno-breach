# Xeno Breach – Roadmap to Playable Demo

Engine: Godot  
Genre: Retro FPS (Doom / Wolfenstein style)  
Target: Playable demo with one complete level

Goal:
Deliver a polished playable demo of Xeno Breach that represents a complete vertical slice of the game.

The demo should include:
- One fully playable level
- One weapon
- One enemy type
- Core FPS mechanics
- Story foundation
- Mission/quest system architecture (planned but not required in demo)
- Sound, UI, and basic game polish

The architecture must support future expansion including:
- Multiple weapons
- Weapon upgrades
- Quest-driven gameplay
- Multiple levels
- Additional enemy types

---

# Milestone 1 – Core FPS Framework

Goal: Establish stable FPS gameplay.

Priority: Critical

---

## Player Controller

Story Points: 5  
Priority: Critical

Tasks:

- FPS camera
- Mouse look
- Player movement (WASD)
- Sprint
- Jump (optional)
- Collision handling
- Player health system
- Damage feedback
- Death state

---

## Weapon System (Modular)

Story Points: 8  
Priority: Critical

Tasks:

- Weapon base class
- Firing system
- Hitscan or projectile system
- Fire rate / cooldown
- Ammo system
- Reload system
- Impact effects

Architecture must support:

- Multiple weapons
- Weapon upgrades
- Different firing modes
- Weapon switching

Demo weapon:

- Basic rifle or pistol

---

## Enemy Framework

Story Points: 8  
Priority: Critical

Tasks:

- Enemy base class
- Enemy health
- Damage system
- Enemy death state
- Basic enemy AI

AI behaviors:

- Patrol or idle
- Detect player
- Chase player
- Melee or close-range attack

Demo enemy:

- Xeno Crawler

---

# Milestone 2 – Combat & Feedback

Goal: Make combat feel satisfying.

Priority: High

---

## Combat Feedback

Story Points: 5

Tasks:

- Hit effects
- Enemy damage reaction
- Screen damage effect
- Weapon recoil
- Basic muzzle flash

---

## Sound System

Story Points: 5

Tasks:

- Weapon firing sound
- Enemy sounds
- Player damage sound
- Ambient level sound
- UI sounds

Use placeholder sounds if necessary.

---

# Milestone 3 – Level Design

Goal: Create one complete playable level.

Priority: Critical

---

## Level Architecture

Story Points: 5

Tasks:

- Level scene structure
- Modular room layout
- Enemy spawn system
- Environmental collisions
- Navigation zones

---

## Level Gameplay

Story Points: 5

Tasks:

- Player start location
- Enemy encounters
- Level progression path
- Environmental storytelling

---

## Level Completion

Story Points: 3

Tasks:

- Exit trigger
- Victory screen
- Demo completion screen

---

# Milestone 4 – UI / UX

Goal: Create a clean FPS interface.

Priority: High

---

## HUD

Story Points: 5

HUD elements:

- Player health
- Ammo
- Current weapon
- Crosshair
- Damage indicator

---

## Menu System

Story Points: 5

Tasks:

- Main menu
- Start game
- Restart level
- Quit game

---

# Milestone 5 – Mission / Quest Architecture

Goal: Prepare the game for story-driven missions.

Priority: Medium

NOTE:
The demo does NOT require full quests,
but the system must be prepared.

Story Points: 8

Tasks:

- Mission manager system
- Objective structure
- Event triggers
- Mission completion tracking

Examples of future missions:

- Reach area
- Kill enemy group
- Activate terminal
- Retrieve item

---

# Milestone 6 – Game Polish

Goal: Make the demo feel like a finished game slice.

Priority: High

---

## Visual Polish

Story Points: 5

Tasks:

- Basic lighting
- Environment textures
- Weapon model polish
- Enemy model polish

---

## Performance

Story Points: 3

Tasks:

- FPS stability
- Collision optimization
- Enemy logic optimization

---

## Demo Experience

Story Points: 5

Tasks:

- Intro text or screen
- Short story introduction
- Demo end screen
- "Wishlist / Follow development" message

---

# Milestone 7 – Packaging & Release

Goal: Prepare demo for distribution.

Priority: Medium

---

## Build & Distribution

Story Points: 3

Tasks:

- Export build
- Create itch.io page
- Screenshots
- Gameplay GIF
- Description text

---

# Future Milestones (Post Demo)

Not required for demo but planned.

---

## Weapons Expansion

- Additional weapons
- Weapon upgrades
- Alternate fire modes

---

## Enemy Expansion

- Ranged enemies
- Elite enemies
- Boss encounters

---

## Story System

- Full mission system
- Dialogue
- Story events

---

## Level Expansion

- Multiple levels
- Biomes
- Environmental hazards
