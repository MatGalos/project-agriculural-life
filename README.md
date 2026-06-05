# Project Agricultural Life

Project for my master thesis about implementing stock-market mechanics in a farming simulator.

## Documentation

- [Architecture notes](Docs/architecture.md)

## Current Gameplay Scope

- Third-person player controller with mouse camera and sprinting.
- Rebindable keyboard and mouse controls saved in `user://controls.cfg`.
- Inventory, drag-and-drop slots, and hotbar selection.
- Tool use through the selected hotbar item.
- Farm tiles with grass, plowed, and watered states.
- Crop planting, daily growth, and harvesting.
- Watering can capacity, refill at the well, and water-fill bars in inventory/hotbar UI.
- Day/night and date progression.
- Basic interactables for well, house, and silo prompts.

## Changelog

### Version 0.2

- Implemented tools:
  - Hoe model and functionality.
  - Watering can model and functionality.
  - Scythe model and functionality.
  - Seed bag model and seed planting functionality.
- Implemented item categories:
  - Crops.
  - Seeds.
  - Tools.
  - Resources.
- Implemented crop system and wheat growth visuals.
- Implemented tile system with grass, plowed, and watered states.
- Improved inventory and hotbar.
- Implemented day/night cycle.
- Added terrain, building, tool, and crop assets.

### Version 0.1.1.28

- Added `use_tool` support to controls and settings.
- Added mouse-button serialization for control rebinding.
- Fixed controls reset so mouse binds are preserved and restored.
- Added seed-item planting: wheat seeds act as the wheat seed bag.
- Added scalable crop lookup through `ToolManager.all_crops`.
- Added watering-can water indicators in inventory and hotbar UI.
- Added well refill integration for the watering can.
- Cleaned up gameplay scripts and updated architecture documentation.


### Version 0.1.1.27

- Implemented watering-can fill/refill state.

### Version 0.1.1.26

- Implemented crop system.

### Version 0.1.1.23

- Implemented functionality for hoe.
- Implemented functionality for watering can.
- Implemented functionality for scythe.
- Implemented functionality for seed bag.

### Version 0.1.1.21

- Implemented tile system.

### Version 0.1.1.20

- Implemented day/night cycle.

### Version 0.1.1.18

- Improved hotbar.

### Version 0.1.1.15

- Improved inventory.

### Version 0.1.1.11

- Implemented item category for resources.

### Version 0.1.1.10

- Implemented item category for tools.

### Version 0.1.1.9

- Implemented item category for seeds.

### Version 0.1.1.8

- Implemented item category for crops.

### Version 0.1.1.7

- Implemented item structure.

### Version 0.1.1.6

- Implemented wheat assets.

### Version 0.1.1.5

- Implemented watered block asset.

### Version 0.1.1.4

- Implemented seed bag model.

### Version 0.1.1.3

- Implemented scythe model.

### Version 0.1.1.2

- Implemented watering can model.

### Version 0.1.1.1

- Implemented hoe model.

### Version 0.1

- Implemented basic menus:
  - Start menu.
  - Pause menu.
  - Options menu template.
  - Controls menu inside options.
  - Mock phone menu.
- Implemented basic player in-game UI:
  - Date and time display.
  - Funds display.
  - Event display.
  - Mini-map placeholder.
  - Quick inventory.
  - Crosshair.
  - Interaction descriptions under crosshair.
- Implemented base game assets:
  - Grass block.
  - Plowed block.
  - Terrain atlas.
  - Well.
  - Player house.
  - Silo.
  - Ground plane.
- Implemented base gameplay mechanics:
  - Third-person camera.
  - Basic controls.
  - Sprinting.
  - Basic collisions.
