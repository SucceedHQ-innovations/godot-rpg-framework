# Godot 4 RPG Framework

[![Godot](https://img.shields.io/badge/Godot-4.3+-478CBF?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![GDScript](https://img.shields.io/badge/GDScript-2.0-478CBF?logo=godot-engine&logoColor=white)](https://gdscript.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CI](https://github.com/SucceedHQ-innovations/godot-rpg-framework/actions/workflows/ci.yml/badge.svg)](https://github.com/SucceedHQ-innovations/godot-rpg-framework/actions)

A full-featured Godot 4 RPG framework with ECS-based combat, dialogue system, inventory, quest engine, and procedural dungeon generation.

## Features

- **ECS Combat Engine** — Entity-Component-System architecture for damage, buffs, status effects, and ability cooldowns
- **Dialogue System** — Branching dialogue with conditions, variables, NPC portraits, and skip/auto-advance
- **Inventory & Crafting** — Grid-based inventory with drag-drop, item stacking, equipment slots, and recipe crafting
- **Quest Engine** — Quest chains with objectives, rewards, conditional triggers, and journal UI
- **Procedural Dungeons** — BSP room generation, corridor carving, enemy placement, and loot distribution
- **Save System** — Resource-based serialization with compression and cloud-sync support
- **State Machine** — Hierarchical state machine for player, NPC, and enemy behaviors
- **Localization** — CSV-based i18n with runtime language switching
- **Cutscene Director** — Timeline-based cutscenes with camera control, dialogue, and scripted events

## Architecture

```
godot-rpg-framework/
├── scripts/
│   ├── core/            — Singletons, event bus, save manager
│   ├── combat/          — ECS, damage formulas, status effects
│   ├── dialogue/        — Node-based dialogue graph, conditions
│   ├── inventory/       — Grid storage, items, crafting
│   ├── quests/          — Quest definitions, objectives, rewards
│   ├── dungeon/         — BSP generator, room templates
│   ├── ui/              — HUD, menus, inventory screens
│   └── ai/              — State machines, pathfinding
├── scenes/              — Player, NPCs, UI scenes
├── assets/              — Sprites, fonts, audio, tilemaps
└── tests/               — GDScript unit tests
```

## Getting Started

Open in **Godot 4.3+**. Run `scenes/MainMenu.tscn` to start.

```
git clone https://github.com/SucceedHQ-innovations/godot-rpg-framework.git
```

## License

MIT
