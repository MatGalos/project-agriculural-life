# Project Agricultural Life

Project for my master thesis about implementing stock-market mechanics in a farming simulator.

## Documentation

- [Architecture notes](Docs/architecture.md)
- [Function reference](Docs/function-reference.md)
- [Testing documentation](Docs/testing.md)
- [How to Play](HOW_TO_PLAY.md)
- [Credits and licenses](CREDITS.md)

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
- In-game day length: 10 real-time minutes.
- Interpolated day/night lighting with visible sun and moon visuals aligned to the shadow direction.
- Four-season calendar: Spring, Summer, Autumn, and Winter.
- Money, buy prices, sell prices, and commodity-backed dynamic crop prices.
- Commodity market updates during market hours with price history.
- Market, weather, seasonal, and calendar events that affect one or more commodities and generate news entries.
- Daily event generation is capped to two newly started events per day.
- Random product market events are further capped to one newly started product event per day.
- Sales-volume market events based on recent crop sales history.
- Oversupply events use crop-yield-adjusted sales thresholds and a cooldown to limit repeated market crashes.
- Event cooldowns and once-per-season/year activation locks are persisted through save/load.
- Event-driven seed buy price modifiers, for example Spring Planting Boom.
- Weather system with current weather, temperature, daily and phase forecasts, and rain/storm field watering.
- Weather history tracks completed days for event requirements such as drought, heavy rain, and heatwave checks.
- Phone menu with sell, shop, market, weather, storage, and news apps.
- Unified UI display formatting for money, season dates, market trends, weather names, product names, seed names, and interaction prompts.
- Central HUD visibility modes hide crosshair, hotbar, prompts, status HUD, and notifications while blocking menus are open.
- Bottom-left HUD news alerts show newly generated market-event news; multiple alerts can stack at once.
- Save/load persistence with three save slots stored under `user://save_slot_%d.json`.
- New game and load game menus for choosing the active save slot, with save slots presented as paper cards.
- New game overwrite confirmation for occupied save slots.
- Pause menu save actions for saving the current slot, saving and returning to the main menu, or saving and quitting to desktop, each with confirmation before writing.
- Basic interactables for well, house, and silo prompts.
- Editor farm-grid generator with stable tile IDs for save restoration.
- Physical farm border boundaries built from invisible `StaticBody3D` colliders aligned with the existing visual fences.
- Main Menu help screens for How to Play and Credits.

## Changelog

### Version 0.4
- Expanded farm content with additional crop products, seasonal crop support, overproduction events, and recent sales statistics.
- Improved weather with day phases, cached phase updates, seasonal balancing, forecasts, and rain/storm field watering behavior.
- Expanded the market/event layer with market, weather, seasonal, fixed-date, and sales-driven events, plus buy-price and commodity modifiers.
- Polished UI across Main Menu, Pause Menu, Options, New Game, Load Game, HUD, FarmPhone apps, Inventory, Storage, Shop, Sell, Market, Weather, and News.
- Standardized player-facing formatting for money, dates, market trends, weather names, product/seed names, and concise interaction prompts.
- Improved day/night visuals with smoother lighting transitions and low-poly sun/moon scene markers.
- Added physical farm border boundaries using invisible colliders aligned with the existing authored fence layout.
- Completed a small camera and interaction readability pass around farm borders, house, silo, prompts, and blocking UI transitions.
- Extended save/load coverage for player state, weather, market events, news, sales statistics, and farm tile state.
- Added automated tests, full-year simulations, oversupply simulations, crop profitability reports, and related balance diagnostics.
- Rebalanced selected crop prices, seed prices, event chances, cooldowns, and oversupply thresholds.
- Fixed camera controls, rain harvest behavior, stale prompt/crosshair feedback, and several world/gameplay readability issues.
- Added How to Play and Credits documentation screens.

### Version 0.3
- Restructured the world
- Implemented WorldManager
- Implemented Game Economy
  - Implemented MoneyManager
  - Implemented PriceData
  - Implemented EconomyManager
- Implemented storage and selling mechanics
  - Implemented StorageData
  - Implemented SiloInteractable
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
  - Implemented weather app
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
