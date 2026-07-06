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
- Market, weather, seasonal, and calendar events that affect one or more commodities and generate news entries.
- Daily event generation is capped to two newly started events per day.
- Random product market events are further capped to one newly started product event per day.
- Sales-volume market events based on recent crop sales history.
- Oversupply events use crop-yield-adjusted sales thresholds and a cooldown to limit repeated market crashes.
- Event cooldowns and once-per-season/year activation locks are persisted through save/load.
- Event-driven seed buy price modifiers, for example Spring Planting Boom.
- Weather system with current weather, temperature, daily and phase forecasts, and rain/storm field watering.
- Weather history tracks completed days for event requirements such as drought, heavy rain, and heatwave checks.
- Phone menu with sell, shop, stock market, weather, and news apps.
- Bottom-left HUD news alerts show newly generated market-event news; multiple alerts can stack at once.
- Save/load persistence with three save slots stored under `user://save_slot_%d.json`.
- New game and load game menus for choosing the active save slot.
- Pause menu save actions for saving the current slot, saving and returning to the main menu, or saving and quitting to desktop.
- Basic interactables for well, house, and silo prompts.
- Editor farm-grid generator with stable tile IDs for save restoration.

## Changelog

### Version 0.5
- Expanded the market event system:
  - Added market, weather, and seasonal event categories.
  - Added random, condition-based, and fixed-date trigger modes.
  - Added multi-product market events through explicit affected item lists.
  - Added season, day-range, weather-history, temperature, and recent-sales requirements.
  - Added fixed-date calendar-event protection so events such as Halloween Pumpkin Demand run once per year.
  - Limited new event starts to two events per in-game day.
- Added runtime buy-price event modifiers for seed prices without mutating `ItemPriceData`.
- Reworked commodity event modifiers so trend strength and volatility do not permanently accumulate.
- Added completed-day weather history used by Drought, Heavy Rain, and Summer Heatwave.
- Added Spring Planting Boom, Autumn Harvest Festival, Halloween Pumpkin Demand, Winter Shortage, Drought, Heavy Rain, Summer Heatwave, Export Contract, and Market Panic events.
- Restricted bad harvest events to the matching crop season.
- Reduced high-volume random market event chances:
  - Demand Spike: `0.032` per crop event.
  - Export Contract: `0.01` per crop event.
  - Market Panic: `0.02` per crop event.
- Added bottom-left HUD news alerts for newly started market events, including stacked alerts when multiple events start together.
- Extended save/load with calendar-event lock state, daily event limit state, and weather history.
- Added EventSystem tests covering multi-product events, event conditions, seed price modifiers, calendar locks, weather requirements, deterministic stacking, event chance configuration, and save/load behavior.
- Added a deterministic full-year simulation test with CSV reports for daily market/weather/event data and event activation summaries.
- Updated the full-year simulation into a five-seed run that reports `600` total days, per-seed daily/event/validation CSV files, a multi-seed summary, and an aggregate report.
- Added an Oversupply sales simulation report covering all crop products, sales thresholds, cooldown behavior, product isolation, price impact, and save/load diagnostics.
- Rebalanced selected event parameters after multi-seed simulation:
  - Demand Spike trigger chance is `0.032`.
  - Export Contract trigger chance is `0.01`.
  - Summer Heatwave trigger chance is `0.56`.
  - Heavy Rain uses `cooldown_days = 7`.
  - Bad Harvest events use `cooldown_days = 5`.
  - `beetroot_bad_harvest` trend strength modifier is `0.024`.
- Rebalanced Oversupply events:
  - All Oversupply events use `cooldown_days = 5`.
  - Yield-1 crops use `recent_sales_threshold = 200`.
  - Yield-3 crops use `recent_sales_threshold = 600`.
- Added crop profitability analysis reports for product price, seed price, seasonal profitability, ROI, market scenarios, and Oversupply risk.
- Rebalanced crop product base sell prices:
  - Wheat `15`, Carrot `23`, Beetroot `33`, Lettuce `33`, Cabbage `50`, Pumpkin `39`.
  - Potatoe `16`, Corn `15`, Strawberry `15`, Tomatoe `13`.
- Rebalanced seed buy prices:
  - Wheat `5`, Carrot `5`, Beetroot `8`, Lettuce `8`, Cabbage `12`, Pumpkin `8`.
  - Potatoe `8`, Corn `9`, Strawberry `11`, Tomatoe `10`.

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
  - Implemented cabbage
  - Implemented pumpkin
  - Implemented tomatoe
  - Implemented corn
  - Implemented strawberry
- Added settings for the resolutions
- Improvements to weather
  - Implemented weather phase system
  - Added cached day phase updates from in-game time changes
  - Implemented seasonal weather balancing for temperature and rainy/stormy pattern weights
- Improvements to apps
  - Improve weather app
  - Weather forecast now labels the next day as Tomorrow and shows pattern, temperature, and rain chance

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
