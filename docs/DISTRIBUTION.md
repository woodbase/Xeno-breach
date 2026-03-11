# Distribution Guide

This document covers how to export, package, and publish Xeno Breach.

---

## itch.io Page

### Game Title

**Xeno Breach**

### Short Description (tagline)

> Fast, aggressive twin-stick sci-fi shooter. Fight through breach-infested stations.

### Full Description

---

**Xeno Breach** is a fast-paced twin-stick shooter set in abandoned space stations overrun by alien entities.

You are part of a private containment crew deployed after research facilities stopped responding.

Your job is not exploration. Your job is **containment and cleanup**.

**Fight through five waves of hostile entities.** Each wave escalates — more enemies, faster attacks, tighter margins.

---

#### Features

- **Twin-stick combat** — move with WASD, aim with mouse, stay aggressive
- **Three enemy types** — Crawler (melee), Brute (slow tank), Striker (fast ranged)
- **Modular weapon system** — auto, semi-auto, and burst-fire weapons with ammo and reload
- **Hitscan and projectile attacks** — including pierce-capable sniper fire
- **Wave-based survival** — five escalating waves with wave-start telegraphing
- **Mission system** — objective tracking across kill, area, terminal, and item goals
- **Co-op ready architecture** — local split-screen support in progress
- **Atmospheric sound design** — procedural ambient loops, reactive combat audio

---

#### Controls

| Action      | Binding        |
|-------------|----------------|
| Move        | WASD           |
| Aim         | Mouse          |
| Fire        | Left Mouse     |
| Alt Fire    | Right Mouse    |
| Reload      | R              |
| Sprint      | Shift          |
| Weapon Next | Scroll Up      |
| Weapon Prev | Scroll Down    |
| Pause       | Escape         |

---

#### Built With

- Godot 4.2+
- Typed GDScript
- Forward Plus renderer

---

### Tags

`action`, `shooter`, `twin-stick`, `sci-fi`, `survival`, `wave-based`, `top-down`, `godot`

### Genre

Action, Shooter

### Classification

- Kind: Game
- Release status: In development

### Pricing

Free

---

## Export Build

### Prerequisites

- Godot 4.2.x installed
- Export templates installed via **Editor → Manage Export Templates**

### Local Export

Export from the Godot editor:

1. Open the project in Godot 4.2+
2. Go to **Project → Export**
3. Select a preset (Web, Windows, or Linux)
4. Click **Export Project**

Or run headless from the command line:

```bash
# Web
godot --headless --export-release "Web" build/web/index.html

# Windows
godot --headless --export-release "Windows Desktop" build/windows/xeno-breach.exe

# Linux
godot --headless --export-release "Linux/X11" build/linux/xeno-breach.x86_64
```

### CI/CD Export

Exports are automated via `.github/workflows/export.yml`.

- **On tag push** (`v*`): builds all three platforms and deploys to itch.io
- **Manual trigger**: builds all platforms and uploads artifacts without deploying

### Secrets Required for itch.io Deployment

Add these secrets to the GitHub repository settings:

| Secret               | Description                                      |
|----------------------|--------------------------------------------------|
| `BUTLER_CREDENTIALS` | API key from itch.io → Account → API keys        |
| `ITCH_USERNAME`      | Your itch.io username                            |

---

## Release Checklist

Before tagging a release:

- [ ] All five enemy waves spawn and complete correctly
- [ ] Main menu loads and all options work
- [ ] Game over and win screens display correctly
- [ ] Audio plays (ambient loop, weapon fire, enemy sounds)
- [ ] Weapons fire, reload, and run out of ammo correctly
- [ ] No console errors during a full run
- [ ] Version number updated in `project.godot` (`config/version`)
- [ ] `export_presets.cfg` export paths are correct
- [ ] Smoke test on each target platform (Web, Windows, Linux)

Then create the release tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

---

## Screenshots

See [`../screenshots/README.md`](../screenshots/README.md) for guidance on which screenshots and GIFs to capture for the itch.io page.
