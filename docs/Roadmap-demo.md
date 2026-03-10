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

- [x] FPS camera
- [x] Mouse look
- [x] Player movement (WASD)
- [x] Sprint
- [x] Jump (optional)
- [x] Collision handling
- [x] Player health system
- [x] Damage feedback
- [x] Death state

---

## Weapon System (Modular)

Story Points: 8  
Priority: Critical

Tasks:

- [x] Weapon base class
- [x] Firing system
- [x] Hitscan or projectile system
- [x] Fire rate / cooldown
- [x] Ammo system
- [x] Reload system
- [x] Impact effects

Architecture must support:

- [x] Multiple weapons
- [x] Weapon upgrades
- [x] Different firing modes
- [x] Weapon switching

Demo weapon:

- Basic rifle or pistol

---

## Enemy Framework

Story Points: 8  
Priority: Critical

Tasks:

- [x] Enemy base class
- [x] Enemy health
- [x] Damage system
- [x] Enemy death state
- [x] Basic enemy AI

AI behaviors:

- [x] Patrol or idle
- [x] Detect player
- [x] Chase player
- [x] Melee or close-range attack

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

- [x] Hit effects
- [x] Enemy damage reaction
- [x] Screen damage effect
- [ ] Weapon recoil
- [x] Basic muzzle flash

---

## Sound System

Story Points: 5

Tasks:

- [x] Weapon firing sound
- [x] Enemy sounds
- [x] Player damage sound
- [x] Ambient level sound
- [x] UI sounds

Use placeholder sounds if necessary.

---

# Milestone 3 – Level Design

Goal: Create one complete playable level.

Priority: Critical

---

## Level Architecture

Story Points: 5

Tasks:

- [x] Level scene structure
- [ ] Modular room layout
- [x] Enemy spawn system
- [x] Environmental collisions
- [ ] Navigation zones

---

## Level Gameplay

Story Points: 5

Tasks:

- [x] Player start location
- [x] Enemy encounters
- [ ] Level progression path
- [ ] Environmental storytelling

---

## Level Completion

Story Points: 3

Tasks:

- [ ] Exit trigger
- [x] Victory screen
- [ ] Demo completion screen

---

# Milestone 4 – UI / UX

Goal: Create a clean FPS interface.

Priority: High

---

## HUD

Story Points: 5

HUD elements:

- [x] Player health
- [ ] Ammo
- [ ] Current weapon
- [ ] Crosshair
- [ ] Damage indicator

---

## Menu System

Story Points: 5

Tasks:

- [x] Main menu
- [x] Start game
- [x] Restart level
- [x] Quit game

---

# Milestone 5 – Mission / Quest Architecture

Goal: Prepare the game for story-driven missions.

Priority: Medium

NOTE:
The demo does NOT require full quests,
but the system must be prepared.

Story Points: 8

Tasks:

- [ ] Mission manager system
- [ ] Objective structure
- [ ] Event triggers
- [ ] Mission completion tracking

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

- [ ] Basic lighting
- [ ] Environment textures
- [ ] Weapon model polish
- [ ] Enemy model polish

---

## Performance

Story Points: 3

Tasks:

- [ ] FPS stability
- [ ] Collision optimization
- [ ] Enemy logic optimization

---

## Demo Experience

Story Points: 5

Tasks:

- [ ] Intro text or screen
- [ ] Short story introduction
- [ ] Demo end screen
- [ ] "Wishlist / Follow development" message

---

# Milestone 7 – Packaging & Release

Goal: Prepare demo for distribution.

Priority: Medium

---

## Build & Distribution

Story Points: 3

Tasks:

- [ ] Export build
- [ ] Create itch.io page
- [ ] Screenshots
- [ ] Gameplay GIF
- [ ] Description text

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
