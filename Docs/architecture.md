# Project Architecture Notes

This document describes the current runtime flow for the main gameplay scripts. It is intended as a maintenance guide for future work, not as a full design document.

## Autoloads

The project uses these gameplay autoloads:

- `gamemanager` controls global UI menus, pause state, scene transitions, and mouse capture.
- `InputManager` centralizes gameplay action queries and control rebinding persistence.
- `HotbarManager` owns hotbar selection state and exposes the currently selected item.
- `ToolManager` applies active hotbar tools/seeds to world targets and owns watering-can state.
- `CropGrowthManager` advances registered farm tiles when the day changes.
- `TimeManager` owns in-game time, date, seasons, and day/month/year signals.
- `MoneyManager` owns the current player money amount and emits money change signals.
- `EconomyManager` resolves buy and sell prices, using commodity prices when an item is market-backed.
- `CommodityMarketManager` updates commodity prices during market hours and stores price history.
- `WeatherManager` owns current weather, temperature, forecast data, and rain/storm watering effects.
- `EventManager` starts and expires market events that modify commodity behavior.
- `NewsManager` converts market events into phone news entries.
- `UI` is the player HUD scene autoload.

Keep cross-system state in autoloads only when multiple unrelated scenes need it. Scene-local display logic should stay in UI controllers.

## Input And Controls

`InputManager` wraps gameplay input reads and persists rebinds to `user://controls.cfg`.

Important behavior:

- Keyboard and mouse-button binds are serialized.
- Empty legacy config entries are ignored so default project binds are not erased.
- `reset_to_defaults()` recreates all known actions before assigning default binds.
- `use_tool` defaults to left mouse button and is routed through `CharacterController` to `ToolManager`.

## Pause And Mouse Capture

`gamemanager` is the source of truth for game pause state.

Rules:

- `setPaused()` must be used instead of changing `get_tree().paused` directly.
- `Esc` is ignored while options are open, so options cannot accidentally unpause the game.
- Inventory and phone are closed before toggling pause.
- Mouse capture is enabled only while the player is in game, not paused, and no blocking UI is visible.

## Inventory Data

`InventoryData` is a `Resource` containing an array of `InventorySlot` resources.

Important behavior:

- Call `setup()` before reading or mutating slots if the caller is not sure the data was initialized.
- `setup()` preserves existing slot contents and only adjusts the array size.
- Mutating methods emit `inventory_changed` after a real data change.
- UI should refresh from `inventory_changed` instead of polling every frame.

Slot move behavior:

- Empty target: move the whole source slot.
- Same item target: merge as much as possible up to `max_stack`.
- Different item target: swap both slots.

## Hotbar Data

`HotbarData` maps visible hotbar slots to inventory slot indexes. By default, hotbar slots 1-5 show inventory slots 0-4.

`HotbarManager` owns selection state and uses `HotbarData` to resolve the selected `ItemData`. Hotbar UI should only render what `HotbarManager.inventory_data` and `HotbarManager.hotbar_data` expose.

## Tools And Crops

`ToolManager` resolves the currently selected hotbar item and applies it to the raycast target.

Supported behavior:

- Hoe: turns grass farm tiles into plowed farm tiles.
- Watering can: waters plowed farm tiles if water is available.
- Seed item: plants the crop matching `SeedItemData.crop_id` on watered empty farm tiles.
- Scythe: harvests ready crops and adds the harvest item to inventory.

Crop lookup uses `all_crops: Array[CropData]`. Add new crop resources to that list instead of hardcoding individual seed checks.

Season rules:

- `CropData.allowed_seasons` defines which `SeasonData.Season` values can grow that crop.
- `CropData.can_grow_in_current_season()` compares `allowed_seasons` with `TimeManager.get_current_season()`.
- `ToolManager` blocks seed planting when the crop cannot grow in the current season.
- Blocked seasonal planting logs the message and shows the same text through `PlayerHUD.show_event_message()`.
- The current HUD event message duration is controlled by `PlayerHUD.EVENT_MESSAGE_DURATION`.

Watering-can state:

- `watering_can_water` stores current water units.
- `watering_can_capacity` stores max water units.
- `watering_can_changed` is emitted after watering or refill.
- `WellInteractable` refills the watering can through `ToolManager.refill_watering_can()`.

## Farm Tiles And Growth

`FarmTile` owns tile state, planted crop data, crop growth days, and the active crop visual instance.

Growth rules:

- Crops can be planted only on watered tiles with no existing crop.
- A watered tile with a crop advances growth when a new day starts.
- Watered tiles revert to plowed after daily processing.
- Harvesting a ready crop clears the crop visual and returns the harvest item.

`CropGrowthManager` registers runtime farm tiles and calls `process_new_day()` from `TimeManager.day_changed`.

## Time And Seasons

`TimeManager` advances game time in minutes and emits signals for time, day, month, year, and season changes.

Calendar rules:

- One in-game day is `REAL_SECONDS_PER_GAME_DAY` real seconds.
- Each day has `GAME_MINUTES_PER_DAY` minutes.
- Each month has `DAYS_PER_MONTH` days.
- Each year has `MONTHS_PER_YEAR` months.
- Month 1 is Spring, month 2 is Summer, month 3 is Autumn, and month 4 is Winter.

Important behavior:

- `get_date_string()` returns an ordinal day plus season and year, for example `1st of Summer, Year 1`.
- `skip_to_morning()` advances time to 06:00 and simulates missed commodity market updates when skipping past market hours.
- Systems that need daily processing should connect to `day_changed` instead of checking the date every frame.

## Economy And Commodity Market

`MoneyManager` stores player funds and emits `money_changed` after every successful update.

`EconomyManager` resolves item prices:

- `get_buy_price()` uses `ItemPriceData.buy_price` when configured, otherwise falls back to `ItemData.base_price`.
- `get_sell_price()` uses `CommodityMarketManager.get_current_price()` for commodity-backed items.
- Non-commodity sell prices use `ItemPriceData.sell_price` or `ItemData.base_price` as fallback.

`CommodityMarketManager` owns commodity price updates:

- Market hours are controlled by `MARKET_OPEN_HOUR` and `MARKET_CLOSE_HOUR`.
- Prices update once per market hour.
- `last_processed_day` and `last_processed_hour` prevent duplicate hourly updates.
- Commodity price history is capped to the latest 30 entries.
- The commodity exchange phone app displays market open/closed status and recent price history.
- `simulate_skipped_market_hours()` is used when time skipping would otherwise miss market updates.

Event modifiers:

- `EventManager` resets commodity modifiers before applying currently active events.
- `MarketEventData.trend_effect`, `trend_strength_modifier`, and `volatility_modifier` modify the target commodity.
- New commodity-backed crops need a `CommodityData` resource and registration in `CommodityMarketManager.commodities`.

## Weather

`WeatherManager` owns current weather, tomorrow weather, temperature, and a rolling forecast.

Important behavior:

- Weather changes on `TimeManager.day_changed`.
- The forecast stores dictionaries containing `weather` and `temperature`.
- `FORECAST_DAYS` controls forecast length.
- Weather resources can set `waters_fields`.
- Rain and storm currently water plowed farm tiles automatically.
- The weather phone app listens to `weather_changed` and rebuilds the forecast list.

## Market Events And News

`EventManager` rolls possible market events once per day.

Important behavior:

- `possible_market_events` contains the market event resources that can start.
- Each active event tracks remaining days through `ActiveMarketEvent`.
- Duplicate active events are skipped.
- Started events emit `market_event_started`.
- Expired events emit `market_event_ended`.
- `market_events_changed` is emitted after daily event processing.

`NewsManager` listens for `EventManager.market_event_started`:

- A started market event creates a `NewsItem`.
- The news item stores title, body, current date, and category.
- New entries are inserted at the front of `news_items`.
- `news_added` lets the phone news panel refresh immediately.

## Phone Apps

`PhonePanel` hosts separate app scenes and bottom navigation buttons.

Current apps:

- Sell app: sells storage items and uses dynamic commodity prices where available.
- Shop app: buys items through configured shop data and `MoneyManager`.
- Stock market app: displays commodity prices, market status, and recent history.
- Weather app: displays current weather and forecast rows.
- News app: displays latest `NewsManager` entries.

Rules:

- Phone, inventory, and storage panels are mutually exclusive from `PlayerHUD`.
- Each app owns its own `refresh()` method.
- App panels should connect to relevant manager signals only once.
- App row scenes should be passed through exported `row_scene` fields, not hardcoded in scripts.

## Inventory UI

`InventoryPanel` builds slot UI nodes from `slot_ui_scene` and binds them to `InventoryData.slots` by index.

`InventorySlotUI` handles drag and drop:

- Child nodes ignore mouse input so drag starts on the slot panel.
- Drag payloads use `{ "type": "inventory_slot", "slot_index": index }` to avoid accepting unrelated UI drags.
- Icons are displayed at a fixed UI size and do not resize slots based on source texture size.
- Watering-can slots show a water-fill bar and refresh from `ToolManager.watering_can_changed`.

## Hotbar UI

`QuickInventoryController` renders the mapped inventory slots and refreshes when inventory data changes. It also refreshes after inventory drag and drop to keep hotbar icons synchronized with slot movement.

Watering-can bars are created under each slot icon at runtime. They are intentionally attached to `IconRect`, not the slot `PanelContainer`, so the bar does not resize or darken the whole hotbar slot.

## Player HUD

`PlayerHUD` owns mutually exclusive blocking panels:

- Inventory cannot open while phone is open.
- Phone cannot open while inventory is open.
- Closing either panel restores mouse capture only if the game is active and not paused.

The current starting inventory is initialized in `PlayerHUD._setup_starting_inventory()`. Replace this with save-game loading when persistence is implemented.

HUD event messages:

- `EventController` is hidden by default.
- `show_event_message(message, duration)` displays temporary feedback in the bottom-left event area.
- Empty messages hide the panel immediately.
- `_event_message_version` prevents an older timer from hiding a newer message.
- Current seasonal planting feedback uses this path; future news/event notifications can reuse it.

## Interaction UI

`InteractionController` raycasts from the player camera and updates prompt/crosshair UI lazily. It intentionally re-fetches UI labels if they were not available during `_ready()`, because HUD creation order can vary when using autoload scenes.

Prompt priority:

- Tool prompts from `ToolManager.get_tool_prompt_for_target()` are shown first.
- Interactable prompts are shown only when no tool prompt is available.

## Maintenance Checklist

Before adding new inventory, crop, tool, or UI behavior:

- Prefer updating data resources first, then let UI refresh from signals.
- Avoid direct mouse mode changes outside `gamemanager`, `PlayerHUD`, or panel open/close methods.
- Use `get_node_or_null()` for optional scene dependencies.
- Keep item icons independent from source texture resolution by configuring `TextureRect.expand_mode` and `stretch_mode`.
- Add new crop resources to `ToolManager.all_crops` before adding special-case code.
- Configure `CropData.allowed_seasons` for every new crop.
- Register commodity-backed items in `CommodityMarketManager.commodities` and provide price data where needed.
- Use `PlayerHUD.show_event_message()` for short-lived gameplay feedback instead of leaving placeholder UI visible.
- For phone apps, expose row scenes with `@export var row_scene: PackedScene` and refresh from manager signals.
- Do not add debug `print()` calls in runtime paths unless they are temporary and removed before commit.
