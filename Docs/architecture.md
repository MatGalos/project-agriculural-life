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
- `EconomyManager` resolves buy and sell prices, using commodity prices when an item is market-backed, and applies runtime buy-price event multipliers.
- `CommodityMarketManager` updates commodity prices during market hours, stores price history, and applies runtime market-event modifiers without mutating base market data.
- `WeatherManager` owns current weather, temperature, daily forecast data, cached day phase state, phase forecast data, rain/storm watering effects, and completed-day weather history.
- `EventManager` starts and expires market, weather, seasonal, and fixed-date events that modify commodity behavior or buy prices.
- `NewsManager` converts market events into phone news entries and HUD news alerts.
- `SaveManager` serializes and restores persistent game state across three save slots.
- `SalesStatsManager` tracks recent sold item amounts for sales-driven market events.
- `GraphicsSettingsManager` persists and applies resolution, fullscreen mode, and interface scale.
- `UI` is the player HUD scene autoload.

Keep cross-system state in autoloads only when multiple unrelated scenes need it. Scene-local display logic should stay in UI controllers.

## World Registration

`WorldManager` is attached to the gameplay scene and joins the `world_manager` group. It is not an autoload.

Important behavior:

- `register_farm_tiles()` scans `farm_tiles_root` for `FarmTile` children and stores them by `tile_id`.
- `get_tile_by_id(tile_id)` is used by save loading to restore farm tiles by stable IDs.
- `get_all_farm_tiles()` exposes registered farm tiles for systems that need world-wide tile data.
- Farm tile IDs must remain stable between scene edits, otherwise saved crop and tile state cannot be restored correctly.

`FarmGridGeneration` is an editor tool script for generating farm tile grids:

- `tile_scene` must instantiate a `FarmTile`.
- Generated tiles are named `Tile_x_z`.
- Generated tile IDs use `grid_prefix_x_z`, for example `small_0_0`.

## Input And Controls

`InputManager` wraps gameplay input reads and persists rebinds to `user://controls.cfg`.

Important behavior:

- Keyboard and mouse-button binds are serialized.
- Empty legacy config entries are ignored so default project binds are not erased.
- `reset_to_defaults()` recreates all known actions before assigning default binds.
- `use_tool` defaults to left mouse button and is routed through `CharacterController` to `ToolManager`.

## Graphics Options

`GraphicsSettingsManager` stores graphics settings in `user://graphics.cfg` and applies them at startup and when options change.

Current settings:

- Resolution: selected from common presets, including 480p, 720p, 1080p, 1440p, 4K/2160p, 4:3, 16:10, MacBook-style, and 21:9 ultrawide resolutions.
- Interface scale: `Small`, `Medium`, or `Big`, applied through the root window content scale factor.
- Fullscreen: toggles the game window between windowed and fullscreen mode.

The Graphics tab in options owns only UI controls. Runtime application and persistence stay in `GraphicsSettingsManager`.

## Pause And Mouse Capture

`gamemanager` is the source of truth for game pause state.

Rules:

- `setPaused()` must be used instead of changing `get_tree().paused` directly.
- `Esc` is ignored while options or load game are open, so submenu overlays cannot accidentally unpause the game or create a second pause stack.
- Inventory and phone are closed before toggling pause.
- Mouse capture is enabled only while the player is in game, not paused, and no blocking UI is visible.
- Options and load game opened from pause keep the pause blur visible and hide the pause button panel.
- Load game is moved to the front when opened so the pause blur remains behind it and cannot block slot buttons.

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
- Active event buy-price multipliers are applied at runtime and are multiplied together per item.
- Runtime buy-price modifiers never mutate `ItemPriceData.buy_price`; removing the active events returns prices to their configured base values.
- `buy_prices_changed` is emitted when buy-price modifiers are reset or reapplied so shop UI can refresh immediately.
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
- `MarketEventData.get_affected_items()` supports both legacy `target_item` events and multi-product `affected_items` events.
- `MarketEventData.trend_effect`, `trend_strength_modifier`, and `volatility_modifier` modify all affected commodities.
- Runtime market modifiers are rebuilt from active events after day changes and save loads.
- Commodity volatility is restored from captured base values before event modifiers are reapplied, preventing permanent accumulation.
- Multiple events on the same commodity are combined deterministically: trend direction is summed, positive values become bullish, negative values become bearish, and near-zero values become neutral.
- New commodity-backed crops need a `CommodityData` resource and registration in `CommodityMarketManager.commodities`.

## Weather

`WeatherManager` owns current weather, tomorrow weather, temperature, a rolling daily forecast, and the active weather phase.

Important behavior:

- The rolling daily forecast advances on `TimeManager.day_changed`.
- `current_day_phase` caches the active `WeatherPhaseData.DayPhase`.
- `TimeManager.time_changed` is connected to `_on_time_changed()`, which updates the cached phase only when the phase boundary is crossed.
- Day phases are Dawn from 05:00, Morning from 09:00, Afternoon from 14:00, and Night from 20:00 through 04:59.
- `WeatherPhaseData` stores phase-specific weather, temperature, and rain chance.
- `WeatherDayPatternData` controls season-weighted day patterns, phase weather options, base temperature ranges, and phase temperature offsets.
- `SeasonWeatherData` applies season-specific weather balancing: `temperature_modifier` shifts the daily base temperature, while `rain_weight_modifier` and `storm_weight_modifier` adjust rainy/stormy day pattern weights.
- `current_day_base_temperature` is rolled once per generated day pattern; each phase temperature is that shared base plus the pattern's phase offset.
- The current phase forecast is applied through `_apply_current_phase_weather()` and emits `weather_changed`.
- The forecast stores dictionaries containing `weather`, `temperature`, `pattern`, `base_temperature`, and `rain_chance`.
- `FORECAST_DAYS` controls forecast length.
- Weather resources can set `waters_fields`.
- Rain and storm currently water plowed farm tiles automatically.
- `daily_weather_history` stores completed-day records capped to the latest 30 days.
- Weather history entries include year, season, day, whether the day was rainy, daily base temperature, and day-pattern identifiers.
- Event requirements use completed-day history, not the current in-progress phase.
- A rainy day is evaluated from the representative day pattern or watering weather options; a dry day is any completed day that is not rainy.
- `get_consecutive_recent_dry_days()`, `get_rainy_days_in_recent_days(days)`, and `get_current_day_base_temperature()` are used by weather/temperature event requirements.
- The weather phone app listens to `weather_changed` and rebuilds current phase rows plus next-day forecast rows.
- Next-day forecast rows show the pattern display name, representative temperature, and rain chance; the first future row is labeled `Tomorrow`, then later rows use `Day +N`.

## Market Events And News

`EventManager` rolls possible market events once per day after active-event duration is processed. Daily event triggering is deferred after `day_changed` so weather and sales history can update deterministically before requirements are evaluated.

Important behavior:

- Events are grouped in `market_events`, `weather_events`, and `seasonal_events`, then combined into `possible_market_events` for lookup and save/load.
- Dynamic filesystem scanning is avoided; event resources are preloaded explicitly so exported builds remain deterministic.
- Each active event tracks remaining days through `ActiveMarketEvent`.
- Duplicate active events are skipped.
- At most `MAX_EVENTS_STARTED_PER_DAY` new events can start on one in-game day. The current value is `2`.
- Daily event-limit state is saved and loaded so saving mid-day cannot bypass the cap.
- `_does_event_meet_requirements()` delegates to focused requirement helpers for sales, season, day range, weather history, and temperature.
- `RANDOM` and `CONDITION_BASED` events check requirements and then roll `trigger_chance`.
- `FIXED_DATE` events check requirements and start without trigger-chance rolling.
- Fixed-date events are protected by a saved `event_id:year` key so they do not restart repeatedly in the same year.
- If a fixed-date event is blocked by the daily cap, it is not marked as triggered and can still run on a later day in its configured range.
- `MarketEventData.requires_recent_sales` gates events by recent sold item amount.
- Sales-gated events use `target_item`, `recent_sales_threshold`, and `recent_sales_days`.
- Bad harvest events are season-gated to the affected crop season.
- Current per-crop random tuning:
  - Demand Spike: `0.04`.
  - Export Contract: `0.005`.
  - Market Panic: `0.02`.
- Started events emit `market_event_started`.
- Expired events emit `market_event_ended`.
- `market_events_changed` is emitted after daily event processing.
- `trigger_event_by_id(event_id)` is available for tests and debug flows; it is safe against duplicate active events and respects the daily event cap.

`NewsManager` listens for `EventManager.market_event_started`:

- A started market event creates a `NewsItem`.
- The news item stores title, body, current date, and category.
- New entries are inserted at the front of `news_items`.
- News history is capped at the latest 20 entries.
- `news_added` lets the phone news panel refresh immediately.
- `news_cleared` lets the phone news panel clear itself during save loading.
- Loading a save replaces current news history with the saved news list, then rebuilds announced event IDs from active saved events.
- New event news also calls `PlayerHUD.show_event_message("News alert: <event name>")`.
- `sync_active_market_event_news()` can recreate missing news for active events but does not show duplicate HUD alerts.

## Sales Stats

`SalesStatsManager` records sold item amounts and keeps a short rolling history for market-event requirements.

Important behavior:

- `record_sale(item_data, amount)` is called by the sell phone app after money is awarded.
- `current_day_sales` stores totals for the active day.
- `sales_history` stores previous day dictionaries and is capped by `HISTORY_DAYS`.
- `get_recent_sales_amount(item_id, days)` returns current-day sales plus up to `days - 1` previous days.
- `sales_stats_changed` is emitted after sales are recorded, day rollover occurs, or save data is loaded.
- Save data persists both `current_day_sales` and `sales_history`.

## Save System

`SaveManager` stores game state in JSON files under `user://save_slot_%d.json`.

Save-slot behavior:

- `SAVE_SLOT_COUNT` is currently `3`.
- `current_save_slot` defaults to slot `1`.
- `set_current_save_slot(slot)` clamps slot values to the valid 1-3 range.
- `get_save_path(slot)` resolves a slot to its `user://save_slot_%d.json` path.
- `has_save(slot)` checks whether a slot file exists.
- `delete_save(slot)` removes a slot file if it exists.
- The new game menu selects a slot with `SaveManager.start_new_game(slot)`, clears any old file for that slot, resets runtime state, and writes the initial save.
- The load game menu selects a slot with `set_current_save_slot(slot)`, starts gameplay, changes to the main game scene, and then applies `load_game()`.
- Pause menu `Save`, `Save and quit to menu`, and `Save and quit to desktop` all write to the current save slot before continuing their action.

Saved data:

- Player money, position, inventory slots, hotbar mapping, and selected hotbar slot.
- Time/date state.
- Current weather, forecast, and completed-day weather history.
- Silo storage contents.
- Commodity market state, including current prices, trends, volatility, and price history.
- Active market events and their remaining duration.
- Event runtime state needed for calendar locks and the daily event cap.
- News history, capped to the latest 20 entries.
- Farm tile state, planted crop IDs, and crop growth days.
- Sales statistics for the current day and recent sales history.

Load behavior:

- Runtime active events are cleared before applying save data so old-session events do not create stale news.
- News are cleared before applying save data.
- Runtime commodity and buy-price event modifiers are reset and rebuilt from restored active events.
- Derived runtime modifiers are not stored when they can be reconstructed from active event resources.
- If the save contains a `news` array, it replaces the current news list atomically.
- If the save has active events but no saved news array, news are rebuilt from the active saved events.
- Farm tile state is restored through `WorldManager` tile IDs, so farm tiles must have stable `tile_id` values.

## Phone Apps

`PhonePanel` hosts separate app scenes and bottom navigation buttons.

Current apps:

- Sell app: sells storage items and uses dynamic commodity prices where available.
- Shop app: buys items through configured shop data and `MoneyManager`.
- Stock market app: displays commodity prices, market status, and recent history.
- Weather app: displays current weather, current-day phase rows, and next-day forecast rows.
- News app: displays latest `NewsManager` entries in a vertical scroll list.

Rules:

- Phone, inventory, and storage panels are mutually exclusive from `PlayerHUD`.
- Each app owns its own `refresh()` method.
- App panels should connect to relevant manager signals only once.
- App row scenes should be passed through exported `row_scene` fields, not hardcoded in scripts.
- Phone app content that can grow beyond the phone frame should sit inside a vertical `ScrollContainer`.
- Current scrollable phone areas are news entries, shop items, sellable silo items, commodity list/history, and weather forecast rows.

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
- Storage/silo UI uses a fixed-size panel with separate vertical scroll areas for silo contents and player inventory contents.
- Storage item rows are added under the scroll content containers; drag-and-drop still targets the storage and inventory columns.

The current starting inventory is initialized in `PlayerHUD._setup_starting_inventory()` for new sessions. Save loading replaces inventory and hotbar state through `SaveManager`.

HUD event messages:

- `EventController` is hidden by default.
- `show_event_message(message, duration)` displays temporary feedback in the bottom-left event area.
- Empty messages hide the panel immediately.
- The HUD stores active messages by local ID, so multiple simultaneous messages can be displayed as stacked lines.
- Each message removes only itself when its timer expires.
- Current seasonal planting feedback and market-event news alerts use this path.

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
- Configure market events through `MarketEventData` resources rather than hardcoding event logic in managers.
- Keep per-crop random event chances low enough to account for all product variants being rolled each day.
- Keep generated `FarmTile.tile_id` values stable after saves exist.
- For sales-driven events, configure `MarketEventData.target_item`, `requires_recent_sales`, `recent_sales_threshold`, and `recent_sales_days`.
- For season-driven or calendar events, configure `requires_season`, `required_seasons`, `requires_day_range`, `start_day`, `end_day`, and the appropriate `trigger_mode`.
- For weather-driven events, use `requires_weather_history`, `required_dry_days`, `required_rain_days`, or `requires_temperature`; do not inspect transient phase weather directly.
- Use `PlayerHUD.show_event_message()` for short-lived gameplay feedback instead of leaving placeholder UI visible.
- For phone apps, expose row scenes with `@export var row_scene: PackedScene` and refresh from manager signals.
- For growing UI lists, prefer a fixed outer panel with inner `ScrollContainer` nodes over allowing rows to resize the panel.
- Keep display/window settings in `GraphicsSettingsManager` rather than applying them directly from individual menu controls.
- Do not add debug `print()` calls in runtime paths unless they are temporary and removed before commit.
