# Function Reference

This document lists the main functions found in `Scripts/` and summarizes their current responsibility. It is intended as a quick maintenance reference; implementation details remain in the source files.

## `Scripts/Events/ActiveMarketEvent.gd`

| Function | Description |
| --- | --- |
| `func setup(data: MarketEventData) -> void:` | Initializes this object or row from provided data. |

## `Scripts/Events/MarketEventData.gd`

Resource only plus helper functions. Stores event identity, category, trigger mode, affected products, commodity effects, buy-price effects, and optional sales/season/day-range/weather/temperature requirements.

| Function | Description |
| --- | --- |
| `func get_affected_items() -> Array[ItemData]:` | Returns unique non-null commodity items affected by the event, using `affected_items` or legacy `target_item`. |
| `func get_affected_buy_price_items() -> Array[ItemData]:` | Returns unique non-null items whose buy prices are affected by the event. |

## `Scripts/Farming/CropData.gd`

| Function | Description |
| --- | --- |
| `func can_grow_in_current_season() -> bool:` | Returns whether grow in current season is allowed in the current state. |

## `Scripts/Farming/FarmTile.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _exit_tree() -> void:` | Cleans up registrations before this node leaves the scene tree. |
| `func set_state(new_state: TileState) -> void:` | Sets state and applies related side effects. |
| `func update_visuals() -> void:` | Updates visuals from current gameplay data. |
| `func plow() -> void:` | Changes a farm tile into the plowed state when possible. |
| `func water() -> void:` | Changes a farm tile into the watered state when possible. |
| `func reset_to_grass() -> void:` | Resets to grass to its default state. |
| `func has_crop() -> bool:` | Returns whether crop exists or is available. |
| `func can_plant() -> bool:` | Returns whether plant is allowed in the current state. |
| `func plant_crop(new_crop_data: CropData) -> bool:` | Plants crop if tile and crop rules allow it. |
| `func process_new_day() -> void:` | Processes new day for the current tick or day. |
| `func advance_crop_growth() -> void:` | Advances crop growth to its next state. |
| `func update_crop_visual() -> void:` | Updates crop visual from current gameplay data. |
| `func is_crop_ready() -> bool:` | Returns whether crop ready is true. |
| `func get_crop_display_name() -> String:` | Returns the current crop display name. |
| `func harvest_crop() -> ItemData:` | Harvests crop and returns produced items when available. |
| `func _spawn_crop_visual(scene: PackedScene) -> void:` | Handles spawn crop visual behavior. |
| `func _clear_crop() -> void:` | Clears clear crop and related state. |
| `func _clear_crop_visual() -> void:` | Clears clear crop visual and related state. |

## `Scripts/GameManagers/CommodityMarketManager.gd`

| Function | Description |
| --- | --- |
| `func update_market(log_time: String = "") -> void:` | Updates market from current gameplay data. |
| `func simulate_skipped_market_hours(from_day: int, from_hour: int, to_day: int, to_hour: int) -> void:` | Simulates skipped market hours for skipped or deferred time. |
| `func _simulate_day_hours(day: int, start_hour: int, end_hour: int) -> void:` | Handles simulate day hours behavior. |
| `func _update_commodity_price(commodity: CommodityData, log_time: String) -> void:` | Updates update commodity price from current data. |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _capture_base_market_values() -> void:` | Captures base volatility and trend strength values used when rebuilding runtime event modifiers. |
| `func _ensure_base_market_values() -> void:` | Ensures base commodity modifier values are available before applying event effects. |
| `func _initialize_price_history() -> void:` | Handles initialize price history behavior. |
| `func _on_time_changed() -> void:` | Handles the 'on time changed' signal callback. |
| `func get_commodity_for_item(item_data: ItemData) -> CommodityData:` | Returns the current commodity for item. |
| `func has_commodity(item_data: ItemData) -> bool:` | Returns whether commodity exists or is available. |
| `func get_current_price(item_data: ItemData) -> int:` | Returns the current current price. |
| `func _get_history_label(time_string: String) -> String:` | Builds or returns get history label for internal use. |
| `func reset_event_modifiers() -> void:` | Restores commodity trend, trend strength, and volatility to base runtime values before active events are reapplied. |
| `func apply_event_modifier(event_data: MarketEventData) -> void:` | Applies one event's commodity modifiers to every affected item. |
| `func _apply_runtime_values_to_commodity(commodity: CommodityData) -> void:` | Resolves summed trend direction, trend strength, and volatility for one commodity. |

## `Scripts/GameManagers/CropGrowthManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func register_tile(tile: FarmTile) -> void:` | Registers tile for manager-driven updates. |
| `func unregister_tile(tile: FarmTile) -> void:` | Unregisters tile from manager-driven updates. |
| `func _on_day_changed() -> void:` | Handles the 'on day changed' signal callback. |

## `Scripts/GameManagers/EconomyManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _register_prices() -> void:` | Handles register prices behavior. |
| `func get_buy_price(item_data: ItemData) -> int:` | Returns the current buy price after applying active runtime event multipliers. |
| `func get_sell_price(item_data: ItemData) -> int:` | Returns the current sell price. |
| `func reset_buy_price_modifiers() -> void:` | Clears all runtime buy-price multipliers and emits `buy_prices_changed`. |
| `func apply_buy_price_event_modifier(event_data: MarketEventData) -> void:` | Applies one event's buy-price multiplier to all affected buy-price items. |

## `Scripts/GameManagers/EventManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _rebuild_possible_market_events() -> void:` | Rebuilds the combined event list from market, weather, and seasonal event arrays. |
| `func _on_day_changed() -> void:` | Handles the 'on day changed' signal callback. |
| `func _finish_day_event_processing() -> void:` | Deferred day-end event processing after dependent managers have updated daily state. |
| `func _process_active_events() -> void:` | Processes process active events for current game state. |
| `func _try_trigger_market_events() -> void:` | Attempts to start eligible daily events until the daily start cap is reached. |
| `func _try_trigger_fixed_date_events_for_current_day() -> void:` | Attempts fixed-date events for the current date, used on startup/new day. |
| `func _is_event_already_active(event_data: MarketEventData) -> bool:` | Checks whether is event already active is true for internal flow. |
| `func trigger_event_by_id(event_id: String) -> bool:` | Safely starts a configured event directly by ID for tests/debug use. |
| `func _start_market_event(event_data: MarketEventData, emit_started_signal: bool = true) -> bool:` | Creates an active event if it is not duplicate and the daily cap allows it. |
| `func _update_daily_event_limit_key() -> void:` | Resets the daily start counter when the date changes. |
| `func _can_start_event_today() -> bool:` | Returns whether the daily event-start cap still allows another event. |
| `func _apply_market_event_effects() -> void:` | Applies apply market event effects to current state. |
| `func get_active_market_events() -> Array[ActiveMarketEvent]:` | Returns the current active market events. |
| `func get_event_by_id(event_id: String) -> MarketEventData:` | Finds a configured market event resource by save-game event ID. |
| `func _does_event_meet_requirements(event_data: MarketEventData) -> bool:` | Checks sales and other event requirements before trigger chance is rolled. |
| `func _meets_sales_requirements(event_data: MarketEventData) -> bool:` | Checks recent sales requirements through `SalesStatsManager`. |
| `func _meets_season_requirements(event_data: MarketEventData) -> bool:` | Checks whether the current season is in the event's required season list. |
| `func _meets_day_range_requirements(event_data: MarketEventData) -> bool:` | Checks inclusive current-season day ranges from 1 to 30. |
| `func _meets_weather_requirements(event_data: MarketEventData) -> bool:` | Checks completed-day dry/rain history requirements. |
| `func _meets_temperature_requirements(event_data: MarketEventData) -> bool:` | Checks the current day's stable base temperature against event min/max values. |
| `func _can_trigger_fixed_date_event(event_data: MarketEventData) -> bool:` | Checks saved fixed-date event lock state. |
| `func _mark_fixed_date_event_triggered(event_data: MarketEventData) -> void:` | Stores the fixed-date event lock key for the current year. |
| `func _get_fixed_date_event_key(event_data: MarketEventData) -> String:` | Builds the `event_id:year` lock key. |
| `func create_calendar_event_state_save_data() -> Dictionary:` | Serializes fixed-date event lock state. |
| `func apply_calendar_event_state_save_data(save_data: Dictionary) -> void:` | Restores fixed-date event lock state. |
| `func create_daily_event_limit_save_data() -> Dictionary:` | Serializes the current date key and number of events started today. |
| `func apply_daily_event_limit_save_data(save_data: Dictionary) -> void:` | Restores the daily event-start counter. |
| `func _validate_possible_market_events() -> void:` | Validates event resources for duplicate IDs, nulls, invalid ranges, and missing required data. |

## `Scripts/GameManagers/gameManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _input(event: InputEvent) -> void:` | Handles raw input events routed to this node. |
| `func togglePause() -> void:` | Toggles pause between active and inactive states. |
| `func setPaused(value: bool) -> void:` | Handles set paused behavior. |
| `func startGame() -> void:` | Starts game. |
| `func returnToMenu() -> void:` | Returns to to menu. |
| `func openNewGamePanel() -> void:` | Opens the new game slot picker from the main menu. |
| `func openLoadGamePanel(from_context: int) -> void:` | Opens the load game slot picker from the main menu or pause menu and applies the correct background/context. |
| `func closeLoadGamePanel() -> void:` | Closes the load game slot picker and returns to the menu context it was opened from. |
| `func showMainMenu() -> void:` | Shows the main menu and hides gameplay submenus. |
| `func openOptions(from_context: int) -> void:` | Opens options. |
| `func showGlobalUI() -> void:` | Handles show global ui behavior. |
| `func _handle_pause_action() -> void:` | Handles handle pause action behavior. |
| `func _updateMouseMode() -> void:` | Handles update mouse mode behavior. |

## `Scripts/GameManagers/hotbarManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _process(_delta: float) -> void:` | Runs per-frame update logic while the node is active. |
| `func select_slot(slot_index: int) -> void:` | Selects slot and notifies listeners when it changes. |
| `func get_selected_slot() -> int:` | Returns the current selected slot. |
| `func get_selected_item() -> ItemData:` | Returns the current selected item. |
| `func _is_game_menu_open() -> bool:` | Checks whether is game menu open is true for internal flow. |

## `Scripts/GameManagers/inputManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func get_move_vector() -> Vector2:` | Returns the current move vector. |
| `func rebind_action(action_name: String, event: InputEvent) -> void:` | Handles rebind action behavior. |
| `func save_controls() -> void:` | Saves controls to persistent storage. |
| `func load_controls() -> void:` | Loads controls from persistent storage. |
| `func reset_to_defaults() -> void:` | Resets to defaults to its default state. |
| `func get_pressed_hotbar_slot() -> int:` | Returns the current pressed hotbar slot. |
| `func is_interact_pressed() -> bool:` | Returns whether interact pressed is true. |
| `func is_sprint_pressed() -> bool:` | Returns whether sprint pressed is true. |
| `func is_inventory_pressed() -> bool:` | Returns whether inventory pressed is true. |
| `func is_phone_pressed() -> bool:` | Returns whether phone pressed is true. |
| `func is_use_tool_pressed() -> bool:` | Returns whether use tool pressed is true. |
| `func _serialize_events(events: Array[InputEvent]) -> Array[Dictionary]:` | Serializes serialize events for persistence. |
| `func _load_serialized_events(action_name: String, serialized: Array) -> void:` | Loads load serialized events from serialized data. |
| `func _add_key(action_name: String, keycode: Key) -> void:` | Handles add key behavior. |
| `func _add_mouse_button(action_name: String, button_index: MouseButton) -> void:` | Handles add mouse button behavior. |
| `func _ensure_action_exists(action_name: String) -> void:` | Ensures ensure action exists exists before it is used. |

## `Scripts/GameManagers/MoneyManager.gd`

| Function | Description |
| --- | --- |
| `func get_money() -> int:` | Returns the current money. |
| `func set_money(new_amount: int) -> void:` | Sets money and applies related side effects. |
| `func add_money(amount: int) -> void:` | Adds money and emits related updates when needed. |
| `func can_afford(amount: int) -> bool:` | Returns whether afford is allowed in the current state. |
| `func spend_money(amount: int) -> bool:` | Attempts to spend money if the player can afford it. |

## `Scripts/GameManagers/SalesStatsManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Connects daily rollover handling to `TimeManager.day_changed`. |
| `func record_sale(item_data: ItemData, amount: int) -> void:` | Adds sold amount to the current day's item total and emits `sales_stats_changed`. |
| `func get_recent_sales_amount(item_id: String, days: int = HISTORY_DAYS) -> int:` | Returns sales for an item across the current day and recent history. |
| `func _on_day_changed() -> void:` | Moves current-day sales into rolling history, trims old entries, and emits `sales_stats_changed`. |
| `func create_save_data() -> Dictionary:` | Serializes current-day sales and recent sales history. |
| `func apply_save_data(save_data: Dictionary) -> void:` | Restores sales statistics from save data and emits `sales_stats_changed`. |

## `Scripts/GameManagers/NewsManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _on_market_event_started(event_data: MarketEventData) -> void:` | Creates news for a newly started market event and shows a HUD news alert when the news is new. |
| `func _on_market_event_ended(event_data: MarketEventData) -> void:` | Clears the announced-event marker when an active market event expires. |
| `func sync_active_market_event_news() -> void:` | Ensures every currently active market event has a corresponding news entry when no saved news list overrides it. |
| `func add_market_event_news(event_data: MarketEventData) -> bool:` | Creates a news entry for a market event unless that event was already announced; returns whether a new item was added. |
| `func _show_market_event_news_alert(event_data: MarketEventData) -> void:` | Displays a bottom-left HUD alert for newly generated market-event news. |
| `func add_news(news_item: NewsItem) -> void:` | Adds news and emits related updates when needed. |
| `func clear_news() -> void:` | Clears current news and announced-event tracking, then emits `news_cleared`. |
| `func replace_news_items(saved_news_items: Array[NewsItem]) -> void:` | Replaces current news with the loaded save-game news list, capped to `MAX_NEWS_COUNT`. |
| `func get_latest_news() -> Array[NewsItem]:` | Returns the current latest news. |
| `func rebuild_announced_event_ids_from_active_events() -> void:` | Rebuilds duplicate-prevention state from currently active market events after loading. |

## `Scripts/GameManagers/SaveManager.gd`

| Function | Description |
| --- | --- |
| `func save_game() -> void:` | Serializes the current game state to the selected save slot. |
| `func load_game() -> void:` | Loads the selected save slot and applies all persisted game state. |
| `func _get_item_by_id(item_id: String) -> ItemData:` | Finds an item resource by save-game item ID, using cache and directory lookup. |
| `func _find_item_by_id_in_directory(item_id: String, directory_path: String) -> ItemData:` | Recursively searches item resource directories for a matching item ID. |
| `func _clear_runtime_events_before_load() -> void:` | Clears active runtime events before save data is applied. |
| `func _create_save_data() -> Dictionary:` | Builds the top-level save dictionary. |
| `func _apply_save_data(save_data: Dictionary) -> void:` | Applies the top-level save dictionary to runtime managers. |
| `func _apply_time_data(time_data: Dictionary) -> void:` | Restores date and time state. |
| `func _create_inventory_save_data() -> Array:` | Serializes non-empty player inventory slots. |
| `func _apply_inventory_save_data(inventory_data: Array) -> void:` | Restores player inventory slots by item ID and slot index. |
| `func _create_hotbar_save_data() -> Dictionary:` | Serializes hotbar slot mapping and selected slot state. |
| `func _apply_hotbar_save_data(hotbar_save_data: Dictionary) -> void:` | Restores hotbar mapping, selected slot, and related UI signals. |
| `func _create_storage_save_data() -> Dictionary:` | Serializes silo storage contents. |
| `func _apply_storage_save_data(storage_data: Dictionary) -> void:` | Restores silo storage contents and refreshes dependent panels. |
| `func _create_weather_save_data() -> Dictionary:` | Serializes current weather, forecast entries, and completed-day weather history. |
| `func _apply_weather_save_data(weather_data: Dictionary) -> void:` | Restores current weather, forecast, weather history, and weather signals. |
| `func _create_market_save_data() -> Dictionary:` | Serializes commodity market prices, trends, volatility, and history. |
| `func _apply_market_save_data(market_data: Dictionary) -> void:` | Restores commodity market state. |
| `func _create_events_save_data() -> Array:` | Serializes active market events and remaining duration. |
| `func _apply_events_save_data(events_data: Array, emit_change: bool = true) -> void:` | Restores active market events and optionally emits event-change signals. |
| `func _create_event_state_save_data() -> Dictionary:` | Serializes event runtime state that cannot be derived from active events, including calendar locks and daily start limits. |
| `func _apply_event_state_save_data(event_state_data: Dictionary) -> void:` | Restores event runtime state such as fixed-date locks and daily start counters. |
| `func _create_news_save_data() -> Array:` | Serializes the latest saved news entries, capped to `MAX_NEWS_SAVE_COUNT`. |
| `func _apply_news_save_data(news_data: Array) -> void:` | Restores saved news history and refreshes the news panel. |
| `func _get_crop_by_id(crop_id: String) -> CropData:` | Finds a crop resource by crop ID for world restoration. |
| `func _create_world_save_data() -> Dictionary:` | Serializes farm tile state, planted crop IDs, and crop growth. |
| `func _apply_world_save_data(world_data: Dictionary) -> void:` | Restores farm tile state through `WorldManager` tile IDs. |
| `func _create_player_position_save_data() -> Dictionary:` | Serializes player world position. |
| `func _apply_player_position_save_data(position_data: Dictionary) -> void:` | Restores player world position. |
| `func _create_sales_stats_save_data() -> Dictionary:` | Serializes sales statistics through `SalesStatsManager`. |
| `func _apply_sales_stats_save_data(sales_data: Dictionary) -> void:` | Restores sales statistics through `SalesStatsManager`. |
| `func get_save_path(slot: int = current_save_slot) -> String:` | Resolves a save slot to its `user://save_slot_%d.json` path. |
| `func set_current_save_slot(slot: int) -> void:` | Selects the active save slot, clamped to the valid slot range. |
| `func has_save(slot: int) -> bool:` | Returns whether the given save slot file exists. |
| `func delete_save(slot: int) -> void:` | Deletes the given save slot file if it exists. |
| `func start_new_game(slot: int) -> void:` | Selects a save slot, clears any old save for that slot, resets runtime state, and writes a fresh save. |
| `func get_save_slot_info(slot: int) -> Dictionary:` | Reads lightweight save metadata for a slot picker row without loading the full game state. |
| `func get_season_name_from_month(month: int) -> String:` | Converts the saved month number into a season name for save slot display. |

## `Scripts/GameManagers/TimeManager.gd`

| Function | Description |
| --- | --- |
| `func _process(delta: float) -> void:` | Runs per-frame update logic while the node is active. |
| `func _add_minutes(minutes: int) -> void:` | Handles add minutes behavior. |
| `func _advance_day() -> void:` | Handles advance day behavior. |
| `func _advance_month() -> void:` | Handles advance month behavior. |
| `func _advance_year() -> void:` | Handles advance year behavior. |
| `func get_hour() -> int:` | Returns the current hour. |
| `func get_minute() -> int:` | Returns the current minute. |
| `func get_time_string() -> String:` | Returns the current time string. |
| `func get_season_name() -> String:` | Returns the current season name. |
| `func get_date_string() -> String:` | Returns the current date string. |
| `func get_day_progress() -> float:` | Returns the current day progress. |
| `func skip_to_morning() -> void:` | Handles skip to morning behavior. |
| `func get_ordinal_day() -> String:` | Returns the current ordinal day. |
| `func get_current_season() -> SeasonData.Season:` | Returns the current current season. |
| `func get_current_season_display_name() -> String:` | Returns the current current season display name. |

## `Scripts/GameManagers/ToolManager.gd`

| Function | Description |
| --- | --- |
| `func get_active_tool() -> ToolItemData:` | Returns the current active tool. |
| `func use_active_tool(target: Node) -> void:` | Handles use active tool behavior. |
| `func refill_watering_can() -> void:` | Handles refill watering can behavior. |
| `func get_tool_prompt_for_target(target: Node) -> String:` | Returns the current tool prompt for target. |
| `func _use_tool_item(target: Node, tool: ToolItemData) -> void:` | Handles use tool item behavior. |
| `func _use_hoe(target: Node) -> void:` | Handles use hoe behavior. |
| `func _use_watering_can(target: Node) -> void:` | Handles use watering can behavior. |
| `func _use_seed_item(target: Node, seed_item: SeedItemData) -> void:` | Handles use seed item behavior. |
| `func _use_scythe(target: Node) -> void:` | Handles use scythe behavior. |
| `func _find_farm_tile(target: Node) -> FarmTile:` | Finds find farm tile from the provided context. |
| `func _get_crop_data_for_seed(seed_item: SeedItemData) -> CropData:` | Builds or returns get crop data for seed for internal use. |
| `func _get_tool_item_prompt(tile: FarmTile, tool: ToolItemData) -> String:` | Builds or returns get tool item prompt for internal use. |
| `func _refresh_inventory_ui() -> void:` | Refreshes refresh inventory ui from current data. |
| `func _show_hud_event_message(message: String) -> void:` | Handles show hud event message behavior. |

## `Scripts/GameManagers/WeatherManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Connects weather to time/day signals, builds initial forecasts, applies the current phase weather, and logs the starting phase. |
| `func _on_day_changed() -> void:` | Records the completed day, applies the next daily weather entry, rebuilds phase forecast data, and applies the current phase. |
| `func _on_time_changed() -> void:` | Updates cached day phase state after `TimeManager.time_changed`. |
| `func _record_completed_day_weather() -> void:` | Adds the completed day to the capped weather-history list used by event requirements. |
| `func _get_completed_day_date() -> Dictionary:` | Builds the year, season, and day values for the day that just ended. |
| `func _get_season_for_month(month: int) -> SeasonData.Season:` | Converts a month number into the corresponding season enum. |
| `func _is_representative_day_rainy(pattern: WeatherDayPatternData) -> bool:` | Determines whether a completed day should count as rainy for event history. |
| `func _apply_new_day_weather() -> void:` | Advances the rolling daily forecast and emits `weather_changed` for daily weather data. |
| `func _roll_weather() -> WeatherData:` | Picks one configured weather resource for daily forecast data. |
| `func _roll_temperature(weather: WeatherData) -> int:` | Rolls a temperature within the selected weather resource range. |
| `func get_current_weather_name() -> String:` | Returns the current current weather name. |
| `func get_tomorrow_weather_name() -> String:` | Returns the current tomorrow weather name. |
| `func get_current_temperature_string() -> String:` | Returns the current current temperature string. |
| `func get_tomorrow_temperature_string() -> String:` | Returns the current tomorrow temperature string. |
| `func _water_fields_if_needed() -> void:` | Waters plowed farm tiles when the active weather resource has `waters_fields`. |
| `func _generate_initial_forecast() -> void:` | Rebuilds the rolling daily forecast to `FORECAST_DAYS` entries. |
| `func _generate_forecast_entry() -> Dictionary:` | Creates one daily forecast dictionary containing weather, temperature, day pattern, base temperature, and rain chance. |
| `func get_forecast() -> Array[Dictionary]:` | Returns the current forecast. |
| `func get_weather_by_name(weather_name: String) -> WeatherData:` | Finds configured weather data by display name for save loading. |
| `func is_current_weather_watering_fields() -> bool:` | Returns whether the current weather automatically waters fields. |
| `func get_day_phase_name(phase: WeatherPhaseData.DayPhase) -> String:` | Converts a day phase enum to a display/log name. |
| `func _update_day_phase() -> void:` | Recomputes the current day phase, updates `current_day_phase` only on change, logs the transition, and applies phase weather. |
| `func get_current_day_phase() -> WeatherPhaseData.DayPhase:` | Maps `TimeManager.get_hour()` to Dawn, Morning, Afternoon, or Night. |
| `func _generate_phase_forecast(phase: WeatherPhaseData.DayPhase, day_base_temperature: int) -> WeatherPhaseData:` | Creates phase-specific weather data from the current day pattern and shared daily base temperature. |
| `func _roll_rain_chance(weather: WeatherData) -> int:` | Rolls rain chance based on weather type and watering behavior. |
| `func _generate_today_phase_forecast() -> void:` | Rolls the current day pattern and one daily base temperature, then builds Dawn, Morning, Afternoon, and Night phase forecasts. |
| `func _get_phase_forecast(phase: WeatherPhaseData.DayPhase) -> WeatherPhaseData:` | Finds the generated phase forecast for a specific day phase. |
| `func _apply_current_phase_weather() -> void:` | Applies weather and temperature from the cached current phase and emits `weather_changed`. |
| `func _get_pattern_weight_for_current_season(pattern: WeatherDayPatternData) -> int:` | Returns a day pattern's weight for the active season. |
| `func _roll_day_pattern() -> WeatherDayPatternData:` | Picks a season-weighted weather day pattern. |
| `func _roll_day_base_temperature(pattern: WeatherDayPatternData) -> int:` | Rolls one base temperature for all phase temperatures in the current day pattern. |
| `func get_current_season_weather_profile() -> SeasonWeatherData:` | Returns the weather balancing profile for the active season. |
| `func get_consecutive_recent_dry_days() -> int:` | Returns the number of consecutive non-rainy completed days at the end of history. |
| `func get_rainy_days_in_recent_days(days: int) -> int:` | Counts rainy completed days in the requested recent-history window. |
| `func get_current_day_base_temperature() -> float:` | Returns the stable daily base temperature for temperature-gated events. |
| `func create_weather_history_save_data() -> Array:` | Serializes completed-day weather history. |
| `func apply_weather_history_save_data(history_data: Array) -> void:` | Restores completed-day weather history from save data. |
| `func _get_weather_options_for_phase(pattern: WeatherDayPatternData, phase: WeatherPhaseData.DayPhase) -> Array[WeatherData]:` | Returns weather options configured for a pattern and phase. |
| `func _get_temperature_offset_for_phase(pattern: WeatherDayPatternData, phase: WeatherPhaseData.DayPhase) -> int:` | Returns the temperature offset configured for a pattern and phase. |
| `func get_today_phase_forecast() -> Array[WeatherPhaseData]:` | Returns the generated phase forecast for the current day. |
| `func get_current_phase_weather() -> WeatherPhaseData:` | Returns the active phase weather data. |
| `func get_current_day_pattern_name() -> String:` | Returns the active day pattern display name. |
| `func get_phase_forecast_text(phase_data: WeatherPhaseData) -> String:` | Formats one phase forecast for debug output. |
| `func print_today_forecast() -> void:` | Prints the current day pattern and all phase forecast rows. |

## `Scripts/GameManagers/WorldManager.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func register_farm_tiles() -> void:` | Registers farm tiles for manager-driven updates. |
| `func get_tile_by_id(tile_id: String) -> FarmTile:` | Returns the current tile by id. |
| `func get_all_farm_tiles() -> Array:` | Returns the current all farm tiles. |

## `Scripts/Generation/FarmGridGeneration.gd`

| Function | Description |
| --- | --- |
| `func generate_grid() -> void:` | Handles generate grid behavior. |

## `Scripts/Interactions/HouseInteractable.gd`

| Function | Description |
| --- | --- |
| `func get_prompt_text() -> String:` | Returns the current prompt text. |
| `func interact() -> void:` | Runs the interaction behavior for this interactable object. |

## `Scripts/Interactions/Interactable.gd`

| Function | Description |
| --- | --- |
| `func interact() -> void:` | Runs the interaction behavior for this interactable object. |
| `func get_prompt_text() -> String:` | Returns the current prompt text. |
| `func get_display_name() -> String:` | Returns the current display name. |

## `Scripts/Interactions/SiloInteractable.gd`

| Function | Description |
| --- | --- |
| `func get_prompt_text() -> String:` | Returns the current prompt text. |
| `func interact() -> void:` | Runs the interaction behavior for this interactable object. |

## `Scripts/Interactions/WellInteractable.gd`

| Function | Description |
| --- | --- |
| `func get_prompt_text() -> String:` | Returns the current prompt text. |
| `func interact() -> void:` | Runs the interaction behavior for this interactable object. |

## `Scripts/Inventory/HotbarData.gd`

| Function | Description |
| --- | --- |
| `func setup() -> void:` | Initializes this object or row from provided data. |
| `func select_slot(index: int) -> void:` | Selects slot and notifies listeners when it changes. |
| `func get_selected_inventory_slot_index() -> int:` | Returns the current selected inventory slot index. |
| `func get_inventory_slot_index(hotbar_index: int) -> int:` | Returns the current inventory slot index. |

## `Scripts/Inventory/inventory_slot_ui.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func set_slot(index: int, slot: InventorySlot) -> void:` | Sets slot and applies related side effects. |
| `func clear() -> void:` | Handles clear behavior. |
| `func _get_drag_data(_position):` | Creates drag payload data and drag preview UI. |
| `func _can_drop_data(_position, data) -> bool:` | Checks whether the current drag payload can be dropped here. |
| `func _drop_data(_position, data) -> void:` | Applies the accepted drag-and-drop payload. |
| `func _update_water_bar(item_data: ItemData) -> void:` | Updates update water bar from current data. |
| `func _gui_input(event: InputEvent) -> void:` | Handles gui input behavior. |

## `Scripts/Inventory/InventoryData.gd`

| Function | Description |
| --- | --- |
| `func setup() -> void:` | Initializes this object or row from provided data. |
| `func get_slot(index: int) -> InventorySlot:` | Returns the current slot. |
| `func clear_inventory() -> void:` | Handles clear inventory behavior. |
| `func add_item(item_data: ItemData, amount: int) -> int:` | Adds item and emits related updates when needed. |
| `func get_item_count(item_data: ItemData) -> int:` | Returns the current item count. |
| `func has_item(item_data: ItemData, amount: int) -> bool:` | Returns whether item exists or is available. |
| `func remove_item(item_data: ItemData, amount: int) -> bool:` | Removes item and emits related updates when needed. |
| `func move_or_merge_slot(from_index: int, to_index: int) -> void:` | Moves or merge slot between source and target containers. |
| `func _move_slot_contents(from_slot: InventorySlot, to_slot: InventorySlot) -> void:` | Handles move slot contents behavior. |
| `func _swap_slot_contents(first_slot: InventorySlot, second_slot: InventorySlot) -> void:` | Handles swap slot contents behavior. |

## `Scripts/Inventory/InventorySlot.gd`

| Function | Description |
| --- | --- |
| `func is_empty() -> bool:` | Returns whether empty is true. |
| `func clear() -> void:` | Handles clear behavior. |
| `func can_stack_with(item: ItemData) -> bool:` | Returns whether stack with is allowed in the current state. |
| `func get_space_left() -> int:` | Returns the current space left. |
| `func add_to_stack(add_amount: int) -> int:` | Adds to stack and emits related updates when needed. |

## `Scripts/PhoneApps/CommodityExchangeApp/CommodityExchangePanel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |
| `func _update_status() -> void:` | Updates update status from current data. |
| `func _on_commodity_selected(commodity: CommodityData) -> void:` | Handles the 'on commodity selected' signal callback. |
| `func _update_history(commodity: CommodityData) -> void:` | Updates update history from current data. |

## `Scripts/PhoneApps/CommodityExchangeApp/CommodityItemRow.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func setup(commodity: CommodityData) -> void:` | Initializes this object or row from provided data. |
| `func _apply_values() -> void:` | Applies apply values to current state. |
| `func _get_trend_text(commodity: CommodityData) -> String:` | Builds or returns get trend text for internal use. |
| `func _get_change_text(commodity: CommodityData) -> String:` | Builds or returns get change text for internal use. |
| `func _gui_input(event: InputEvent) -> void:` | Handles gui input behavior. |

## `Scripts/PhoneApps/NewsApp/NewsItemRow.gd`

| Function | Description |
| --- | --- |
| `func setup(news_item: NewsItem) -> void:` | Initializes this object or row from provided data. |

## `Scripts/PhoneApps/NewsApp/NewsPanel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _on_news_added(_news_item: NewsItem) -> void:` | Handles the 'on news added' signal callback. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |

## `Scripts/PhoneApps/SellApp/SellingItemRow.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func setup(new_item_data: ItemData, new_amount: int) -> void:` | Initializes this object or row from provided data. |
| `func _apply_values() -> void:` | Applies apply values to current state. |
| `func _on_sell_one_pressed() -> void:` | Handles the 'on sell one pressed' signal callback. |
| `func _on_sell_all_pressed() -> void:` | Handles the 'on sell all pressed' signal callback. |

## `Scripts/PhoneApps/SellApp/SellingPanel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func open() -> void:` | Opens . |
| `func close() -> void:` | Closes . |
| `func toggle() -> void:` | Toggles  between active and inactive states. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |
| `func _on_sell_one_requested(item_data: ItemData) -> void:` | Handles the 'on sell one requested' signal callback. |
| `func _on_commodity_prices_updated() -> void:` | Handles the 'on commodity prices updated' signal callback. |
| `func _on_sell_all_requested(item_data: ItemData) -> void:` | Handles the 'on sell all requested' signal callback. |
| `func _sell_item(item_data: ItemData, amount: int) -> void:` | Handles sell item behavior. |

## `Scripts/PhoneApps/ShopApp/ShopData.gd`

| Function | Description |
| --- | --- |
| `func get_available_items() -> Array[ShopItemData]:` | Returns the current available items. |

## `Scripts/PhoneApps/ShopApp/ShopItemRow.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func setup(shop_item: ShopItemData) -> void:` | Initializes this object or row from provided data. |
| `func _apply_values() -> void:` | Applies apply values to current state. |
| `func _on_buy_pressed() -> void:` | Handles the 'on buy pressed' signal callback. |

## `Scripts/PhoneApps/ShopApp/ShopPanel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |
| `func _on_buy_requested(shop_item: ShopItemData) -> void:` | Handles the 'on buy requested' signal callback. |
| `func _on_buy_prices_changed() -> void:` | Refreshes shop rows when event-driven buy-price modifiers change. |
| `func _refresh_game_ui() -> void:` | Refreshes refresh game ui from current data. |

## `Scripts/PhoneApps/WeatherApp/WeatherForecastRow.gd`

| Function | Description |
| --- | --- |
| `func setup(day_offset: int, weather: WeatherData, temperature: int, pattern: WeatherDayPatternData = null, rain_chance: int = 0) -> void:` | Displays one next-day forecast row; `day_offset == 1` is labeled `Tomorrow`, later rows use `Day +N`, and the row shows pattern name, temperature, and rain chance. |

## `Scripts/PhoneApps/WeatherApp/WeatherPanel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _on_weather_changed(_current_weather: WeatherData, _temperature: int) -> void:` | Handles the 'on weather changed' signal callback. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |
| `func _update_today() -> void:` | Updates the current day pattern and current weather summary. |
| `func _update_forecast() -> void:` | Rebuilds current-day phase rows and next-day forecast rows from `WeatherManager`. |

## `Scripts/Seasons/SeasonWeatherData.gd`

Resource only. Stores the season enum plus weather balancing fields: `temperature_modifier`, `rain_chance_modifier`, `storm_chance_modifier`, `rain_weight_modifier`, and `storm_weight_modifier`.

## `Scripts/Player/CharacterController.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _input(event: InputEvent) -> void:` | Handles raw input events routed to this node. |
| `func _physics_process(delta: float) -> void:` | Runs fixed-timestep movement or physics logic. |
| `func _rotate_camera(mouse_motion: InputEventMouseMotion) -> void:` | Handles rotate camera behavior. |
| `func _use_selected_tool() -> void:` | Handles use selected tool behavior. |
| `func _is_inventory_open() -> bool:` | Checks whether is inventory open is true for internal flow. |
| `func _is_phone_open() -> bool:` | Checks whether is phone open is true for internal flow. |
| `func _is_storage_open() -> bool:` | Checks whether is storage open is true for internal flow. |
| `func _is_any_game_menu_open() -> bool:` | Checks whether is any game menu open is true for internal flow. |
| `func _ensure_player_hud() -> void:` | Ensures ensure player hud exists before it is used. |

## `Scripts/Player/InteractionController.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _process(_delta: float) -> void:` | Runs per-frame update logic while the node is active. |
| `func _input(_event: InputEvent) -> void:` | Handles raw input events routed to this node. |
| `func _get_looked_at_tool_prompt() -> String:` | Builds or returns get looked at tool prompt for internal use. |
| `func _get_looked_at_interactable() -> Interactable:` | Builds or returns get looked at interactable for internal use. |
| `func _update_prompt_label() -> void:` | Updates update prompt label from current data. |
| `func _update_crosshair_color() -> void:` | Updates update crosshair color from current data. |
| `func _ensure_ui_nodes() -> void:` | Ensures ensure ui nodes exists before it is used. |
| `func _is_storage_open() -> bool:` | Checks whether is storage open is true for internal flow. |
| `func _is_any_game_menu_open() -> bool:` | Checks whether is any game menu open is true for internal flow. |

## `Scripts/Storage/StorageData.gd`

| Function | Description |
| --- | --- |
| `func add_item(item_data: ItemData, amount: int) -> void:` | Adds item and emits related updates when needed. |
| `func remove_item(item_data: ItemData, amount: int) -> bool:` | Removes item and emits related updates when needed. |
| `func has_item(item_data: ItemData, amount: int) -> bool:` | Returns whether item exists or is available. |
| `func get_item_amount(item_data: ItemData) -> int:` | Returns the current item amount. |
| `func get_item_by_id(item_id: String) -> ItemData:` | Returns the current item by id. |
| `func get_all_items() -> Array:` | Returns the current all items. |

## `Scripts/Storage/StorageItemRow.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func setup(new_item_data: ItemData, new_amount: int, new_source_type: String = "", new_inventory_slot_index: int = -1) -> void:` | Initializes this object or row from provided data. |
| `func _apply_values() -> void:` | Applies apply values to current state. |
| `func _gui_input(event: InputEvent) -> void:` | Handles gui input behavior. |
| `func _get_drag_data(_position: Vector2) -> Variant:` | Creates drag payload data and drag preview UI. |
| `func _can_drop_data(_position: Vector2, data: Variant) -> bool:` | Checks whether the current drag payload can be dropped here. |
| `func _drop_data(_position: Vector2, data: Variant) -> void:` | Applies the accepted drag-and-drop payload. |

## `Scripts/Storage/StorageTransferDropTarget.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _can_drop_data(_position: Vector2, data: Variant) -> bool:` | Checks whether the current drag payload can be dropped here. |
| `func _drop_data(_position: Vector2, data: Variant) -> void:` | Applies the accepted drag-and-drop payload. |
| `func _find_storage_panel() -> StoragePanel:` | Finds find storage panel from the provided context. |

## `Scripts/UIs/Menus/LaunchMenu/mainMenu.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func onStartButtonPressed() -> void:` | Handles on start button pressed behavior. |
| `func onLoadButtonPressed() -> void:` | Handles on load button pressed behavior. |
| `func onOptionsButtonPressed() -> void:` | Handles on options button pressed behavior. |
| `func onCreditsButtonPressed() -> void:` | Handles on credits button pressed behavior. |
| `func onExitButtonPressed() -> void:` | Handles on exit button pressed behavior. |
| `func onOptionsClosed() -> void:` | Handles on options closed behavior. |

## `Scripts/UIs/Menus/LaunchMenu/AdditionalMenus/LoadGamePanel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes slot buttons, back button, pause-safe processing, and button callbacks. |
| `func open() -> void:` | Shows the panel and refreshes save slot rows. |
| `func close() -> void:` | Hides the panel. |
| `func refresh() -> void:` | Refreshes save slot rows from `SaveManager.get_save_slot_info()`. |
| `func setContext(context: int) -> void:` | Applies main-menu or pause-menu background behavior. |
| `func _refresh_slots() -> void:` | Rebuilds all visible save slot buttons. |
| `func _update_slot_button(button: Button, slot: int) -> void:` | Updates one save slot button and disables it when the slot is empty. |
| `func _load_slot(slot: int) -> void:` | Selects the slot, starts gameplay, changes to the game scene, and defers save loading. |
| `func _on_back_pressed() -> void:` | Returns to the correct previous menu through `gamemanager.closeLoadGamePanel()`. |
| `func _load_game_deferred() -> void:` | Waits for the game scene to initialize before applying save data. |

## `Scripts/UIs/Menus/LaunchMenu/AdditionalMenus/NewGamePanel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Connects slot buttons, the back button, and overwrite-confirmation buttons to panel actions. |
| `func _notification(what: int) -> void:` | Refreshes visible save-slot labels when the panel becomes visible. |
| `func refresh() -> void:` | Refreshes new-game slot cards from `SaveManager.get_save_slot_info()`. |
| `func _update_slot_button(button: Button, slot: int) -> void:` | Updates one new-game slot card with empty or existing-save summary text. |
| `func _start_slot(slot: int) -> void:` | Starts a new game in the selected save slot, resets that slot, and changes to the gameplay scene. |
| `func _on_back_pressed() -> void:` | Returns from the new game slot picker to the main menu. |
| `func _on_slot_pressed(slot: int) -> void:` | Starts an empty slot immediately or opens overwrite confirmation for an occupied slot. |
| `func _show_overwrite_confirmation(slot: int) -> void:` | Shows the local overwrite prompt for the selected occupied slot. |
| `func _hide_overwrite_confirmation() -> void:` | Hides the overwrite prompt and clears the pending slot. |
| `func _on_overwrite_confirmed() -> void:` | Starts a new game in the pending slot after overwrite confirmation. |

## `Scripts/UIs/Menus/OptionsMenu/AdditionalMenus/control_bind_row.gd`

| Function | Description |
| --- | --- |
| `func setup(new_action_name: String, display_name: String) -> void:` | Initializes this object or row from provided data. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _on_bind_button_pressed() -> void:` | Handles the 'on bind button pressed' signal callback. |

## `Scripts/UIs/Menus/OptionsMenu/AdditionalMenus/controls.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func build_list() -> void:` | Builds list UI or runtime data. |
| `func _on_rebind_requested(action_name: String) -> void:` | Handles the 'on rebind requested' signal callback. |
| `func _input(event: InputEvent) -> void:` | Handles raw input events routed to this node. |
| `func _on_reset_button_pressed() -> void:` | Handles the 'on reset button pressed' signal callback. |
| `func _start_waiting_for_action(action_name: String) -> void:` | Handles start waiting for action behavior. |
| `func _notification(what: int) -> void:` | Handles notification behavior. |

## `Scripts/UIs/Menus/OptionsMenu/AdditionalMenus/graphics.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Styles graphics controls, builds dropdown options, loads current settings, and connects setting callbacks. |
| `func _build_resolution_options() -> void:` | Populates the resolution dropdown with supported presets and metadata. |
| `func _build_interface_scale_options() -> void:` | Populates the interface-scale dropdown with supported scale labels and metadata. |
| `func _load_values_from_settings() -> void:` | Selects current settings from `GraphicsSettingsManager` without reapplying them. |
| `func _find_resolution_index(target_resolution: Vector2i) -> int:` | Finds the dropdown index for a saved resolution, falling back to 1080p. |
| `func _find_interface_scale_index(target_interface_scale: String) -> int:` | Finds the dropdown index for a saved interface scale, falling back to Medium. |
| `func _on_resolution_selected(index: int) -> void:` | Applies a selected resolution through `GraphicsSettingsManager`. |
| `func _on_interface_scale_selected(index: int) -> void:` | Applies a selected interface scale through `GraphicsSettingsManager`. |
| `func _on_fullscreen_toggled(is_fullscreen: bool) -> void:` | Applies fullscreen state through `GraphicsSettingsManager`. |
| `func _update_fullscreen_text(_is_fullscreen: bool) -> void:` | Keeps the custom drawn fullscreen checkbox free of text. |
| `func _apply_graphics_control_styles() -> void:` | Applies local wooden-menu styling to graphics dropdowns and checkbox. |
| `func _apply_dropdown_style(option_button: OptionButton) -> void:` | Styles an `OptionButton` and its popup to match the wooden menu UI. |
| `func _apply_checkbox_style(check_button: Button) -> void:` | Configures the fullscreen control as a textless square toggle. |

## `Scripts/UIs/Menus/OptionsMenu/optionsMenu.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Connects root segment buttons and submenu back buttons, then shows the root Options panel. |
| `func _input(event: InputEvent) -> void:` | Routes pause/Escape input to options back navigation while Options is visible. |
| `func close() -> void:` | Closes Options and returns to the menu context that opened it. |
| `func handle_back_action() -> void:` | Returns from a submenu to the root Options panel, or closes Options from the root panel. |
| `func setContext(context: int) -> void:` | Applies main-menu or pause-menu background behavior and resets to the root Options panel. |
| `func _show_main_options() -> void:` | Shows the root Options segment list. |
| `func _show_sound_options() -> void:` | Shows the Sound submenu. |
| `func _show_controls_options() -> void:` | Shows the Controls submenu. |
| `func _show_graphics_options() -> void:` | Shows the Graphics submenu. |
| `func _show_feedback_options() -> void:` | Shows the Feedback submenu. |
| `func _set_active_panel(active_panel: Control) -> void:` | Sets exactly one Options panel visible. |

## `Scripts/UIs/Menus/OptionsMenu/OptionsCheckBox.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Configures the square toggle checkbox and connects redraw signals. |
| `func _draw() -> void:` | Draws the checkbox border, checked fill, and check mark using menu colors. |
| `func _on_mouse_entered() -> void:` | Switches the checkbox to hover color and redraws. |
| `func _on_mouse_exited() -> void:` | Restores the normal checkbox color and redraws. |
| `func _on_toggled(_is_pressed: bool) -> void:` | Redraws the check mark after the toggle state changes. |

## `Scripts/UIs/Menus/OptionsMenu/OptionsScrollLine.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Resolves the target `ScrollContainer`, connects to its vertical scrollbar, and prepares redraws. |
| `func _draw() -> void:` | Draws a black vertical line whose size and position follow the underlying scroll state. |
| `func _on_scroll_changed(_value: float) -> void:` | Redraws the custom scroll indicator after scrolling. |

## `Scripts/UIs/Menus/PauseMenu/pauseMenu.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Connects pause-menu buttons, confirmation buttons, and initial visibility state. |
| `func _input(event: InputEvent) -> void:` | Lets Escape close the active save/quit confirmation popup. |
| `func onPauseButtonPressed(paused: bool) -> void:` | Handles on pause button pressed behavior. |
| `func setMenuVisible(is_visible: bool) -> void:` | Handles set menu visible behavior. |
| `func showBlurOnly() -> void:` | Handles show blur only behavior. |
| `func onContinueButtonPressed() -> void:` | Handles on continue button pressed behavior. |
| `func onSaveGameButtonPressed() -> void:` | Opens confirmation before overwriting the current save slot. |
| `func onLoadGameButtonPressed() -> void:` | Handles on load game button pressed behavior. |
| `func onOptionsButtonPressed() -> void:` | Handles on options button pressed behavior. |
| `func onSaveAndQuitToMenuButtonPressed() -> void:` | Opens confirmation before saving and returning to the main menu. |
| `func onSaveAndQuitToDesktopButtonPressed() -> void:` | Opens confirmation before saving and quitting to desktop. |
| `func onOptionsClosed() -> void:` | Handles on options closed behavior. |
| `func _show_confirmation(action: ConfirmationAction, message: String) -> void:` | Shows the local save/quit confirmation popup and stores the pending action. |
| `func _hide_confirmation() -> void:` | Hides the confirmation popup and clears the pending action. |
| `func _on_confirmation_confirmed() -> void:` | Executes the pending save, save-and-quit-to-menu, or save-and-quit-to-desktop action. |

## `Scripts/UIs/Menus/WoodenMenuPanel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Ignores mouse input and redraws when the panel size changes. |
| `func _draw() -> void:` | Draws the shared wooden board background used by menu panels and confirmation popups. |

## `Scripts/UIs/PlayerHUD/inventory_panel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func open() -> void:` | Opens . |
| `func close() -> void:` | Closes . |
| `func toggle() -> void:` | Toggles  between active and inactive states. |
| `func is_open() -> bool:` | Returns whether open is true. |
| `func build_slots() -> void:` | Builds slots UI or runtime data. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |
| `func move_or_merge_slot(from_index: int, to_index: int) -> void:` | Moves or merge slot between source and target containers. |

## `Scripts/UIs/PlayerHUD/phone_panel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func open() -> void:` | Opens . |
| `func close() -> void:` | Closes . |
| `func toggle() -> void:` | Toggles  between active and inactive states. |
| `func is_open() -> bool:` | Returns whether open is true. |
| `func _on_sell_pressed() -> void:` | Handles the 'on sell pressed' signal callback. |
| `func _on_shop_pressed() -> void:` | Handles the 'on shop pressed' signal callback. |
| `func _hide_all_apps() -> void:` | Handles hide all apps behavior. |
| `func _on_exchange_pressed() -> void:` | Handles the 'on exchange pressed' signal callback. |
| `func _on_weather_pressed() -> void:` | Handles the 'on weather pressed' signal callback. |
| `func _on_news_pressed() -> void:` | Handles the 'on news pressed' signal callback. |

## `Scripts/UIs/PlayerHUD/player_hud.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func _update_layout() -> void:` | Recalculates HUD placement from the current viewport size. |
| `func _update_corner_panels(ui_scale: float, margin: float) -> void:` | Sizes and positions the date/time and money wood plaques in the top-right corner. |
| `func _update_bottom_panels(ui_scale: float, margin: float) -> void:` | Sizes bottom-left notification cards and the existing hotbar area without changing hotbar behavior. |
| `func _update_center_prompt(viewport_size: Vector2, min_axis: float) -> void:` | Positions the short white interaction prompt under the crosshair. |
| `func _set_rect(control: Control, left: float, top: float, width: float, height: float) -> void:` | Sets set rect for internal UI or gameplay state. |
| `func _set_top_right_rect(control: Control, right_margin: float, top: float, width: float, height: float) -> void:` | Sets set top right rect for internal UI or gameplay state. |
| `func _set_bottom_left_rect(control: Control, left: float, bottom_margin: float, width: float, height: float) -> void:` | Sets set bottom left rect for internal UI or gameplay state. |
| `func _set_bottom_center_rect(control: Control, bottom_margin: float, width: float, height: float) -> void:` | Sets set bottom center rect for internal UI or gameplay state. |
| `func _set_inventory_slot_sizes(slot_size: Vector2) -> void:` | Sets set inventory slot sizes for internal UI or gameplay state. |
| `func _update_inventory_label_fonts(font_size: int) -> void:` | Updates update inventory label fonts from current data. |
| `func _set_slot_label_font_size(slot: PanelContainer, font_size: int) -> void:` | Sets set slot label font size for internal UI or gameplay state. |
| `func _setup_starting_inventory() -> void:` | Handles setup starting inventory behavior. |
| `func open_inventory() -> void:` | Opens inventory. |
| `func close_inventory() -> void:` | Closes inventory. |
| `func toggle_inventory() -> void:` | Toggles inventory between active and inactive states. |
| `func is_inventory_open() -> bool:` | Returns whether inventory open is true. |
| `func open_phone() -> void:` | Opens phone. |
| `func close_phone() -> void:` | Closes phone. |
| `func toggle_phone() -> void:` | Toggles phone between active and inactive states. |
| `func is_phone_open() -> bool:` | Returns whether phone open is true. |
| `func open_storage() -> void:` | Opens storage. |
| `func close_storage() -> void:` | Closes storage. |
| `func toggle_storage() -> void:` | Toggles storage between active and inactive states. |
| `func is_storage_open() -> bool:` | Returns whether storage open is true. |
| `func is_any_game_menu_open() -> bool:` | Returns whether any game menu open is true. |
| `func show_event_message(message: String, duration: float = EVENT_MESSAGE_DURATION) -> void:` | Shows a temporary bottom-left HUD message; multiple active messages stack as separate lines. |
| `func _refresh_event_messages() -> void:` | Rebuilds the stacked HUD message label from active timed messages. |
| `func _hide_event_message() -> void:` | Clears all active HUD messages and hides the event message panel. |
| `func _on_time_changed() -> void:` | Handles the 'on time changed' signal callback. |
| `func _update_time_ui() -> void:` | Updates update time ui from current data. |
| `func _on_money_changed(_new_amount: int) -> void:` | Handles the 'on money changed' signal callback. |
| `func _update_money_ui() -> void:` | Updates update money ui from current data. |

## `Scripts/UIs/PlayerHUD/HUDPlaque.gd`

Drawn `ColorRect` helper for compact gameplay HUD plaques. It is used by `player_hud.tscn` for date/time, money, and bottom-left notifications.

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Makes the base `ColorRect` transparent and queues redraws when resized. |
| `func _draw() -> void:` | Draws either the wood or paper plaque variant based on `plaque_style`. |
| `func _draw_wood_plaque() -> void:` | Draws a small wooden HUD plaque with border, grain lines, and highlight. |
| `func _draw_paper_plaque() -> void:` | Draws a light paper notification card with border, subtle shadow, and guide line. |

## `Scripts/UIs/UIFormatHelper.gd`

RefCounted static helper only. It formats visible UI text without changing gameplay IDs, save data, market data, or economy values.

| Function | Description |
| --- | --- |
| `static func money_int(amount: int) -> String:` | Formats whole-money UI values as `$110`. |
| `static func money_float(amount: float) -> String:` | Formats market/history prices with two decimals, for example `$33.00`. |
| `static func money_each(amount: int) -> String:` | Formats per-item prices, for example `$12 each`. |
| `static func percent(value: float) -> String:` | Formats already-percent values as `+7.04%`, `-2.51%`, or `0.00%`. |
| `static func season_date(season: Variant, day: int, year: int) -> String:` | Formats seasonal dates as `Spring 3, Year 1`. |
| `static func display_product_name(value: Variant) -> String:` | Converts item resources or technical product IDs to visible product names. |
| `static func display_seed_name(value: Variant) -> String:` | Converts seed resources or seed IDs to visible seed names. |
| `static func display_market_trend(trend: Variant) -> String:` | Converts trend enums or strings to `Bullish`, `Bearish`, or `Neutral`. |
| `static func display_weather_name(value: Variant) -> String:` | Converts weather resources, patterns, or IDs to visible weather names. |
| `static func display_news_category(category: String) -> String:` | Converts news category IDs to display labels. |
| `static func input_event_text(event: InputEvent) -> String:` | Converts input event text to friendlier labels, including removing ` - Physical`. |

## `Scripts/UIs/PlayerHUD/quick_inventory_controller.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |
| `func _on_selected_slot_changed(slot_index: int) -> void:` | Handles the 'on selected slot changed' signal callback. |
| `func _update_highlight(active_slot: int) -> void:` | Updates update highlight from current data. |
| `func _setup_slot_ui(icon_rect: TextureRect, amount_label: Label) -> void:` | Handles setup slot ui behavior. |
| `func _update_watering_can_bar(slot_node: Control, item_data: ItemData) -> void:` | Updates update watering can bar from current data. |
| `func _ensure_watering_can_bar(slot_node: Control) -> void:` | Ensures ensure watering can bar exists before it is used. |

## `Scripts/UIs/PlayerHUD/storage_panel.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func open() -> void:` | Opens . |
| `func close() -> void:` | Closes . |
| `func toggle() -> void:` | Toggles  between active and inactive states. |
| `func refresh() -> void:` | Rebuilds or updates this UI from current backing data. |
| `func transfer_from_inventory_slot(slot_index: int) -> void:` | Handles transfer from inventory slot behavior. |
| `func is_open() -> bool:` | Returns whether open is true. |
| `func can_accept_transfer_drop(target_type: String, data: Variant) -> bool:` | Returns whether accept transfer drop is allowed in the current state. |
| `func drop_transfer_to(target_type: String, data: Variant) -> void:` | Handles drop transfer to behavior. |
| `func _can_drop_data(_position: Vector2, data: Variant) -> bool:` | Checks whether the current drag payload can be dropped here. |
| `func _drop_data(position: Vector2, data: Variant) -> void:` | Applies the accepted drag-and-drop payload. |
| `func _refresh_storage_items() -> void:` | Refreshes refresh storage items from current data. |
| `func _refresh_inventory_items() -> void:` | Refreshes refresh inventory items from current data. |
| `func _create_row(item_data: ItemData, amount: int, source_type: String, inventory_slot_index: int) -> StorageItemRow:` | Creates create row for UI or runtime use. |
| `func _on_row_transfer_requested(row: StorageItemRow) -> void:` | Handles the 'on row transfer requested' signal callback. |
| `func _on_row_item_dropped(target_row: StorageItemRow, payload: Dictionary) -> void:` | Handles the 'on row item dropped' signal callback. |
| `func _transfer_inventory_to_storage(slot_index: int) -> void:` | Handles transfer inventory to storage behavior. |
| `func _transfer_storage_to_inventory(item_data: ItemData) -> void:` | Handles transfer storage to inventory behavior. |
| `func _clear_container(container: Container) -> void:` | Clears clear container and related state. |
| `func _refresh_hotbar() -> void:` | Refreshes refresh hotbar from current data. |
| `func _is_transfer_payload(data: Variant) -> bool:` | Checks whether is transfer payload is true for internal flow. |

## `Scripts/World/DayNightController.gd`

| Function | Description |
| --- | --- |
| `func _ready() -> void:` | Initializes node state, connects required signals, and prepares initial data. |
| `func update_lighting() -> void:` | Updates lighting from current gameplay data. |
| `func _update_environment(sky_color: Color, ambient_color: Color) -> void:` | Updates update environment from current data. |
