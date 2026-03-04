# Xeno Breach – UI Guidelines

Version: 0.1

This document defines how UI should be implemented in Xeno Breach.  
The goal is to keep the interface minimal, readable, and atmospheric.

The UI must support gameplay without distracting from the environment.

---

# 1. UI Philosophy

The UI in Xeno Breach should feel like **equipment readouts**, not a game overlay.

Design goals:

- Minimal
- Functional
- Tactical
- Non-intrusive

The player should feel like they are looking through a device interface, not a HUD from an arcade shooter.

Avoid:

- Large colorful UI elements
- Overly animated UI
- Decorative UI graphics

---

# 2. Core HUD Elements

The HUD should only show essential information.

Required elements:

- Health
- Ammo
- Current objective

Optional future elements:

- Motion sensor
- Environmental warnings

---

# 3. HUD Layout

Recommended layout:

Top Left  
Mission / Objective

Bottom Left  
Health

Bottom Right  
Ammo

Example layout:

OBJECTIVE: REACH CONTROL ROOM

HP: 100

                     AMMO: 18

Keep the center of the screen **clear**.

---

# 4. HUD Colors

Health  
White

Low Health  
Red

Ammo  
Cyan

Objectives  
Amber

Critical warnings  
Red flashing

---

# 5. HUD Size Rules

UI elements should be small and subtle.

General rules:

Health bar height  
6–10 px

Text size  
16–20 px

Icons  
24 px

The HUD should occupy **less than 10% of screen space**.

---

# 6. UI Panels

UI panels should follow the project color palette.

Panel background  
#1B232C

Panel border  
#3A4652

Text  
#D8DEE5

Hover / active  
#00E0C6

Alert  
#C12A2A

---

# 7. Menu Structure

Menus should remain simple and readable.

Main Menu

- NEW GAME
- CONTINUE
- SETTINGS
- EXIT

Pause Menu

- RESUME
- SETTINGS
- MAIN MENU
- QUIT

Settings Menu

- AUDIO
- VIDEO
- CONTROLS
- GAMEPLAY

---

# 8. UI Animation

UI animation should be subtle and quick.

Allowed animation styles:

- Panel slide-in
- Short flicker activation
- Terminal-style text reveal

Avoid:

- Bouncing UI
- Exaggerated scaling
- Playful animation

---

# 9. UI Sound

UI sounds should be minimal and mechanical.

Hover  
Short tick

Click  
Short digital beep

Alert  
Distorted alarm tone

---

# 10. UI Implementation (Godot)

UI should be implemented using **Control nodes**.

Recommended structure:

UI  
HUD  
- Health  
- Ammo  
- Objective  

Menus  
- MainMenu  
- PauseMenu  
- SettingsMenu  

Use **anchors** instead of fixed positions where possible.

Avoid hardcoded screen coordinates.

---

# 11. Accessibility

Minimum text contrast must remain high.

Text color  
#D8DEE5

Background  
#0B0F14

Ensure text remains readable even in dark environments.

---

# 12. Future UI Systems

Planned UI systems:

- Motion detector
- Equipment inventory
- Terminal interfaces
- Facility map

These should follow the same style principles defined in this document.
