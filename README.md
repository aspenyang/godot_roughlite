
Minimal Godot 4.4 roguelite prototype.

## Overview
Main scene UID: `run/main_scene="uid://dfhcmmbuaxgg8"`. Procedural room graph (see `scenes/rooms/level_map.tscn`). Progression & saves handled by the autoload `save_manager_v2.gd`.


## Features
- Procedural room connectivity with multiple room archetypes.
- Player / enemies / weapons scripts in `scripts/`.
- Save system (SaveManagerV2 autoload).
- Export presets and sample `.pck` in `export/`.
- Git integration via Godot Git Plugin (MIT).

## Structure
- `scenes/` Core scenes (rooms, UI, etc.).
- `scripts/` Gameplay & systems (includes `save_manager_v2.gd`).
- `addons/godot-git-plugin/` VCS plugin.
- `assets/` Art / resources.
- `export/` Built artifacts.
- `save/` Runtime generated save data.

## Gameplay

### Core Loop
Clear or solve the current room’s objective; advance until defeating the final boss.

### Basic Controls
- Move: WASD / Arrow Keys
- Dash: Space
- Aim: Mouse
- Primary Attack: Left Mouse Button

### To Start
At the Main Menu select a save slot:
   - Choosing New Game on an occupied slot overwrites that slot’s existing save data.
   - Selecting an existing slot loads that run if resumable; otherwise starts fresh.

### Room Types
- Combat: Clear all melee and/or ranged enemies.
- Maze: Reach exit; health drains over time.
- Puzzle: Follow highlighted path to exit; path shows every 20s and fully reshuffles every 60s; health drains.
- Reward: (0–1 per run) (Optional) Take a healing potion.
- Miniboss: (0–1 per run) Mid-run chance. The miniboss summons melee adds every 5s until defeated.
- Final Boss: Defeat to win the run.

### Selection & Loading
- Selection is per-transition: `room_manager_v5.gd` decides the next room when the previous completes.
- Special rooms (maze/reward) are limited to a single appearance (tracked flags).
- Miniboss eligible only mid-run.
- Procedural combat layout is generated only when chosen (no pre-cache).
- On resume: if last saved room was procedural, a fresh procedural layout is generated (not identical). (See Improvements.)

### Health & Survival
- Time drain in Maze and Puzzle rooms; manage speed vs safety.
- Reward potion restores health.
- Death ends the run; meta data persists per save design.

### Saving
- After each room selection the script stores:
  - current_level
  - player current health
  - usage flags (maze_used, reward_used)

## Run
- Windows: A prebuilt executable is in the `export` folder. Download/extract and double‑click the `.exe` to launch.
1. Install Godot 4.4.
2. Open the project folder (contains `project.godot`).
3. Press F5.

## Export
Use export presets (`export_presets.cfg`); ship executable + `.pck`.


