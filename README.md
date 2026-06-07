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

### Version 0.3
- Restuctured the world
- Implemented WorldManager
- Implemented Game Economy
  - Implement MoneyManager
  - Implement PriceData
  - Implement EconomyManager
- Implemeeted storage and selling mechanics
  - Implemented StorageData
  - Implemented SiloInteractive
  - Implemented StorageUI
  - Implemented functionality to move between inventory and storage
  - Implemented sell interface
  - Implemented buy interface
- Implemented stock market
  - Implemented commodity module
  - Make it update every hour
- Implemented apps for phone menu
  - implemented sell app
  - implement shop app

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
