# Project Agricultural Life

Project for my master thesis about implementing stock-market mechanics in a farming simulator.

## Documentation

- [Architecture notes](Docs/architecture.md)
- [Function reference](Docs/function-reference.md)
- [Testing documentation](Docs/testing.md)

## Current Gameplay Scope

- Third-person player controller with mouse camera and sprinting.
- Rebindable keyboard and mouse controls saved in `user://controls.cfg`.
- Inventory, drag-and-drop slots, and hotbar selection.
- Tool use through the selected hotbar item.
- Farm tiles with grass, plowed, and watered states.
- Crop planting, daily growth, and harvesting.
- Seasonal crop restrictions based on the current in-game season.
- Temporary HUD event messages for gameplay feedback, such as planting blocked by season.
- Watering can capacity, refill at the well, and water-fill bars in inventory/hotbar UI.
- Day/night and date progression.
- Four-season calendar: Spring, Summer, Autumn, and Winter.
- Money, buy prices, sell prices, and commodity-backed dynamic crop prices.
- Commodity market updates during market hours with price history.
- Market events that affect commodity trends and generate news entries.
- Sales-volume market events based on recent crop sales history.
- Weather system with current weather, temperature, forecast, and rain/storm field watering.
- Phone menu with sell, shop, stock market, weather, and news apps.
- Save/load persistence with three save slots stored under `user://save_slot_%d.json`.
- New game and load game menus for choosing the active save slot.
- Pause menu save actions for saving the current slot, saving and returning to the main menu, or saving and quitting to desktop.
- Basic interactables for well, house, and silo prompts.
- Editor farm-grid generator with stable tile IDs for save restoration.

## Changelog

### Version 0.4
- Fixed the camera controls
- Harvest during rain keeps soil watered
- Updated events for overproducing crops
- Added recent sales statistics for sales-driven market event requirements
- Persisted sales statistics in save files
- Documented world tile registration and editor farm-grid generation
- Implemented unit testing for the game
- Implemented more products
  - Implemented carrot
  - Implemented lettuce
  - Implemented potatoe
  - Implemented beetroot
### Version 0.3
- Restructured the world
- Implemented WorldManager
- Implemented Game Economy
  - Implemented MoneyManager
  - Implemented PriceData
  - Implemented EconomyManager
- Implemented storage and selling mechanics
  - Implemented StorageData
  - Implemented SiloInteractive
  - Implemented StorageUI
  - Implemented functionality to move between inventory and storage
  - Implemented sell interface
  - Implemented buy interface
- Implemented stock market
  - Implemented commodity module
  - Made it update every market hour
  - Integrated it into UI
- Implemented Weather system
  - Implemented temperature into game
  - Implemented rain into game
- Implemented event system
- Implemented seasons
  - Added Spring, Summer, Autumn, and Winter calendar flow
  - Added per-crop allowed season configuration
  - Blocked planting when the selected crop cannot grow in the current season
  - Added temporary HUD feedback for blocked seasonal planting
- Implemented apps for phone menu
  - Implemented sell app
  - Implemented shop app
  - Implemented stock market app
  - Implement weather app
  - Implemented news app
- Implemented save game / load game functionality
  - Added three save slots.
  - Persisted player inventory, hotbar, position, time, weather, storage, market prices, active events, news history, and farm tile state.
- Implemented basic menus
  - Implemented new game menu
  - Implemented load game menu
  - Integrated load game into the pause menu with inherited pause blur background.
  - Added pause menu save, save-and-quit-to-menu, and save-and-quit-to-desktop actions for the current save slot.

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
