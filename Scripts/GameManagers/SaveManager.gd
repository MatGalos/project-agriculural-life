extends Node

const SAVE_SLOT_COUNT := 3
const SAVE_PATH_TEMPLATE := "user://save_slot_%d.json"

var current_save_slot: int = 1
const MAX_NEWS_SAVE_COUNT := 20

var item_database: Array[ItemData] = [
	preload("res://Data/Items/Crops/beetroot_item.tres"),
	preload("res://Data/Items/Crops/cabbage_item.tres"),
	preload("res://Data/Items/Crops/carrot_item.tres"),
	preload("res://Data/Items/Crops/corn_item.tres"),
	preload("res://Data/Items/Crops/lettuce_item.tres"),
	preload("res://Data/Items/Crops/potatoe_item.tres"),
	preload("res://Data/Items/Crops/pumpkin_item.tres"),
	preload("res://Data/Items/Crops/strawberry_item.tres"),
	preload("res://Data/Items/Crops/tomatoe_item.tres"),
	preload("res://Data/Items/Crops/wheat_item.tres"),
	preload("res://Data/Items/Seeds/beetroot_seed_item.tres"),
	preload("res://Data/Items/Seeds/cabbage_seed_item.tres"),
	preload("res://Data/Items/Seeds/carrot_seed_item.tres"),
	preload("res://Data/Items/Seeds/corn_seed_item.tres"),
	preload("res://Data/Items/Seeds/lettuce_seed_item.tres"),
	preload("res://Data/Items/Seeds/potatoe_seed_item.tres"),
	preload("res://Data/Items/Seeds/pumpkin_seed_item.tres"),
	preload("res://Data/Items/Seeds/strawberry_seed_item.tres"),
	preload("res://Data/Items/Seeds/tomatoe_seed_item.tres"),
	preload("res://Data/Items/Seeds/wheat_seed_item.tres"),
	preload("res://Data/Items/Tools/hoe_item.tres"),
	preload("res://Data/Items/Tools/watering_can_item.tres"),
	preload("res://Data/Items/Tools/scythe_item.tres"),
	preload("res://Data/Items/Tools/seed_bag_item.tres")
]

var crop_database: Array[CropData] = [
	preload("res://Data/Crops/beetroot_crop.tres"),
	preload("res://Data/Crops/cabbage_crop.tres"),
	preload("res://Data/Crops/carrot_crop.tres"),
	preload("res://Data/Crops/corn_crop.tres"),
	preload("res://Data/Crops/lettuce_crop.tres"),
	preload("res://Data/Crops/potatoe_crop.tres"),
	preload("res://Data/Crops/pumpkin_crop.tres"),
	preload("res://Data/Crops/strawberry_crop.tres"),
	preload("res://Data/Crops/tomatoe_crop.tres"),
	preload("res://Data/Crops/wheat_crop.tres")
]

var _item_cache: Dictionary = {}
var silo_storage: StorageData = preload("res://Data/Storage/silo_storage.tres")

func _get_item_by_id(item_id: String) -> ItemData:
	if _item_cache.has(item_id):
		return _item_cache[item_id] as ItemData

	for item in item_database:
		if item != null and item.id == item_id:
			_item_cache[item_id] = item
			return item

	var found_item := _find_item_by_id_in_directory(item_id, "res://Data/Items")
	if found_item != null:
		_item_cache[item_id] = found_item

	return found_item


func _find_item_by_id_in_directory(item_id: String, directory_path: String) -> ItemData:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return null

	for file_name in directory.get_files():
		if not file_name.ends_with(".tres") and not file_name.ends_with(".res"):
			continue

		var item := load(directory_path.path_join(file_name)) as ItemData
		if item != null and item.id == item_id:
			return item

	for subdirectory_name in directory.get_directories():
		var item := _find_item_by_id_in_directory(item_id, directory_path.path_join(subdirectory_name))
		if item != null:
			return item

	return null

func save_game() -> void:
	var save_data := _create_save_data()

	var json_string := JSON.stringify(save_data, "\t")

	var file := FileAccess.open(get_save_path(), FileAccess.WRITE)
	if file == null:
		print("Save failed")
		return

	file.store_string(json_string)
	file.close()

	print("Game saved")


func load_game() -> void:
	if not FileAccess.file_exists(get_save_path()):
		print("No save file found")
		return

	var file := FileAccess.open(get_save_path(), FileAccess.READ)
	if file == null:
		print("Load failed")
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)

	if error != OK:
		print("Save parse error")
		return

	if not (json.data is Dictionary):
		print("Save data is invalid")
		return

	var save_data := json.data as Dictionary

	_clear_runtime_events_before_load()
	NewsManager.clear_news()
	_apply_save_data(save_data)

	print("Game loaded")


func _clear_runtime_events_before_load() -> void:
	EventManager.active_market_events.clear()
	EventManager.apply_calendar_event_state_save_data({})
	EventManager.apply_daily_event_limit_save_data({})
	EventManager.apply_event_activation_history_save_data({})
	EventManager.apply_once_per_season_state_save_data({})
	EventManager.apply_once_per_year_state_save_data({})
	EventManager._apply_market_event_effects()
	EventManager.market_events_changed.emit()


func _create_save_data() -> Dictionary:
	return {
		"version": 1,

		"player": {
			"money": MoneyManager.get_money(),
			"position": _create_player_position_save_data(),
			"inventory": _create_inventory_save_data(),
			"hotbar": _create_hotbar_save_data()
		},

		"time": {
			"year": TimeManager.current_year,
			"month": TimeManager.current_month,
			"day": TimeManager.current_day,
			"minute_of_day": TimeManager.current_minute_of_day
		},

		"weather": _create_weather_save_data(),

		"storage": _create_storage_save_data(),

		"market": _create_market_save_data(),

		"events": _create_events_save_data(),
		"event_state": _create_event_state_save_data(),

		"news": _create_news_save_data(),

		"world": _create_world_save_data(),
		
		"sales_stats": _create_sales_stats_save_data(),
	}


func _apply_save_data(save_data: Dictionary) -> void:
	if save_data.has("player") and save_data["player"] is Dictionary:
		var player_data := save_data["player"] as Dictionary

		if player_data.has("money"):
			MoneyManager.set_money(int(player_data["money"]))

		if player_data.has("inventory") and player_data["inventory"] is Array:
			_apply_inventory_save_data(player_data["inventory"] as Array)

		if player_data.has("hotbar") and player_data["hotbar"] is Dictionary:
			_apply_hotbar_save_data(player_data["hotbar"] as Dictionary)
			
		if player_data.has("position") and player_data["position"] is Dictionary:
			_apply_player_position_save_data(player_data["position"] as Dictionary)
			
	elif save_data.has("money"):
		MoneyManager.set_money(int(save_data["money"]))

	if save_data.has("time") and save_data["time"] is Dictionary:
		_apply_time_data(save_data["time"] as Dictionary)

	if save_data.has("storage") and save_data["storage"] is Dictionary:
		_apply_storage_save_data(save_data["storage"] as Dictionary)

	if save_data.has("weather") and save_data["weather"] is Dictionary:
		_apply_weather_save_data(save_data["weather"] as Dictionary)
	
	if save_data.has("sales_stats") and save_data["sales_stats"] is Dictionary:
		_apply_sales_stats_save_data(save_data["sales_stats"] as Dictionary)

	if save_data.has("event_state") and save_data["event_state"] is Dictionary:
		_apply_event_state_save_data(save_data["event_state"] as Dictionary)
	
	var has_saved_news := save_data.has("news") and save_data["news"] is Array
	var has_saved_market := save_data.has("market") and save_data["market"] is Dictionary

	if has_saved_market:
		_apply_market_save_data(save_data["market"] as Dictionary)

	if save_data.has("events") and save_data["events"] is Array:
		_apply_events_save_data(save_data["events"] as Array, not has_saved_news)

	if save_data.has("world") and save_data["world"] is Dictionary:
		_apply_world_save_data(save_data["world"] as Dictionary)

	if save_data.has("news") and save_data["news"] is Array:
		_apply_news_save_data(save_data["news"] as Array)
	elif save_data.has("events") and save_data["events"] is Array:
		NewsManager.sync_active_market_event_news()


func _apply_time_data(time_data: Dictionary) -> void:
	TimeManager.current_year = maxi(int(time_data.get("year", 1)), 1)
	TimeManager.current_month = clampi(int(time_data.get("month", 1)), 1, TimeManager.MONTHS_PER_YEAR)
	TimeManager.current_day = clampi(int(time_data.get("day", 1)), 1, TimeManager.DAYS_PER_MONTH)

	if time_data.has("minute_of_day"):
		TimeManager.current_minute_of_day = clampi(
			int(time_data["minute_of_day"]),
			0,
			TimeManager.GAME_MINUTES_PER_DAY - 1
		)
	else:
		var hour := clampi(int(time_data.get("hour", 6)), 0, 23)
		var minute := clampi(int(time_data.get("minute", 0)), 0, 59)
		TimeManager.current_minute_of_day = hour * 60 + minute

	TimeManager._minute_accumulator = 0.0
	TimeManager.time_changed.emit()

func _create_inventory_save_data() -> Array:
	var result := []

	var inventory: InventoryData = HotbarManager.inventory_data

	if inventory == null:
		return result

	inventory.setup()

	for i in range(inventory.slots.size()):
		var slot := inventory.slots[i]

		if slot == null or slot.is_empty():
			continue

		result.append({
			"slot_index": i,
			"item_id": slot.item_data.id,
			"amount": slot.amount
		})

	return result

func _apply_inventory_save_data(inventory_data: Array) -> void:
	var inventory: InventoryData = HotbarManager.inventory_data

	if inventory == null:
		return

	inventory.setup()
	inventory.clear_inventory()

	for entry in inventory_data:
		if not (entry is Dictionary):
			continue

		var slot_data := entry as Dictionary
		var slot_index := int(slot_data.get("slot_index", -1))
		var item_id := String(slot_data.get("item_id", ""))
		var amount := int(slot_data.get("amount", 0))

		if slot_index < 0 or slot_index >= inventory.slots.size():
			continue

		var item_data := _get_item_by_id(item_id)

		if item_data == null:
			print("Unknown item id in save: ", item_id)
			continue

		var slot := inventory.slots[slot_index]
		slot.item_data = item_data
		slot.amount = amount

	inventory.inventory_changed.emit()

	var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")
	if inventory_panel:
		inventory_panel.refresh()

	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui:
		hotbar_ui.refresh()


func _create_hotbar_save_data() -> Dictionary:
	if HotbarManager.hotbar_data == null:
		return {}

	HotbarManager.hotbar_data.setup()

	return {
		"inventory_slot_indexes": HotbarManager.hotbar_data.inventory_slot_indexes.duplicate(),
		"selected_slot_index": HotbarManager.hotbar_data.selected_slot_index,
		"selected_slot": HotbarManager.selected_slot
	}

func _create_storage_save_data() -> Dictionary:
	if silo_storage == null:
		return {
			"silo_inventory": {}
		}

	return {
		"silo_inventory": silo_storage.stored_items.duplicate(true)
	}

func _apply_hotbar_save_data(hotbar_save_data: Dictionary) -> void:
	if HotbarManager.hotbar_data == null:
		return

	if hotbar_save_data.has("inventory_slot_indexes") and hotbar_save_data["inventory_slot_indexes"] is Array:
		var indexes: Array[int] = []
		var saved_indexes := hotbar_save_data["inventory_slot_indexes"] as Array

		for index in saved_indexes:
			indexes.append(int(index))

		HotbarManager.hotbar_data.inventory_slot_indexes = indexes

	HotbarManager.hotbar_data.selected_slot_index = int(hotbar_save_data.get("selected_slot_index", 0))
	HotbarManager.hotbar_data.setup()

	var fallback_selected_slot := HotbarManager.hotbar_data.selected_slot_index + 1
	HotbarManager.selected_slot = clampi(
		int(hotbar_save_data.get("selected_slot", fallback_selected_slot)),
		1,
		HotbarManager.hotbar_data.hotbar_size
	)

	HotbarManager.selected_slot_changed.emit(HotbarManager.selected_slot)
	HotbarManager.selected_item_changed.emit(HotbarManager.get_selected_item())

	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui:
		hotbar_ui.refresh()

func _apply_storage_save_data(storage_data: Dictionary) -> void:
	if silo_storage == null:
		return

	silo_storage.stored_items.clear()

	if not (storage_data.get("silo_inventory", {}) is Dictionary):
		silo_storage.storage_changed.emit()
		return

	var silo_inventory := storage_data.get("silo_inventory", {}) as Dictionary

	for item_id in silo_inventory.keys():
		silo_storage.stored_items[String(item_id)] = int(silo_inventory[item_id])

	silo_storage.storage_changed.emit()

	var storage_panel = get_tree().get_first_node_in_group("storage_panel")
	if storage_panel:
		storage_panel.refresh()

	var selling_panel = get_tree().get_first_node_in_group("selling_panel")
	if selling_panel:
		selling_panel.refresh()

func _create_weather_save_data() -> Dictionary:
	var forecast_data := []

	for entry in WeatherManager.get_forecast():
		if not (entry is Dictionary):
			continue

		var forecast_entry := entry as Dictionary
		var weather: WeatherData = forecast_entry.get("weather", null)
		var temperature := int(forecast_entry.get("temperature", 20))
		var pattern := forecast_entry.get("pattern", null) as WeatherDayPatternData
		var base_temperature := int(forecast_entry.get("base_temperature", temperature))
		var rain_chance := int(forecast_entry.get("rain_chance", 0))

		if weather == null:
			continue

		forecast_data.append({
			"weather_name": weather.display_name,
			"temperature": temperature,
			"pattern_id": pattern.pattern_id if pattern != null else "",
			"base_temperature": base_temperature,
			"rain_chance": rain_chance
		})

	return {
		"current_weather": WeatherManager.get_current_weather_name(),
		"current_temperature": WeatherManager.current_temperature,
		"forecast": forecast_data,
		"daily_history": WeatherManager.create_weather_history_save_data()
	}

func _apply_weather_save_data(weather_data: Dictionary) -> void:
	var current_weather_name := String(weather_data.get("current_weather", "Sunny"))
	var current_weather := WeatherManager.get_weather_by_name(current_weather_name)

	if current_weather != null:
		WeatherManager.current_weather = current_weather

	WeatherManager.current_temperature = int(weather_data.get("current_temperature", 20))

	WeatherManager.forecast.clear()

	if not (weather_data.get("forecast", []) is Array):
		if weather_data.has("daily_history") and weather_data["daily_history"] is Array:
			WeatherManager.apply_weather_history_save_data(weather_data["daily_history"] as Array)
		else:
			WeatherManager.apply_weather_history_save_data([])

		WeatherManager.weather_changed.emit(
			WeatherManager.current_weather,
			WeatherManager.current_temperature
		)
		return

	var forecast_data := weather_data.get("forecast", []) as Array

	for entry in forecast_data:
		if not (entry is Dictionary):
			continue

		var forecast_entry := entry as Dictionary
		var weather_name := String(forecast_entry.get("weather_name", "Sunny"))
		var weather := WeatherManager.get_weather_by_name(weather_name)
		var temperature := int(forecast_entry.get("temperature", 20))
		var pattern_id := String(forecast_entry.get("pattern_id", ""))
		var pattern := WeatherManager.get_day_pattern_by_id(pattern_id)
		var base_temperature := int(forecast_entry.get("base_temperature", temperature))
		var rain_chance := int(forecast_entry.get("rain_chance", 0))

		if weather == null:
			continue

		WeatherManager.forecast.append({
			"weather": weather,
			"temperature": temperature,
			"pattern": pattern,
			"base_temperature": base_temperature,
			"rain_chance": rain_chance
		})

	if WeatherManager.forecast.size() > 0:
		WeatherManager.tomorrow_weather = WeatherManager.forecast[0]["weather"]
		WeatherManager.tomorrow_temperature = int(WeatherManager.forecast[0]["temperature"])

	if weather_data.has("daily_history") and weather_data["daily_history"] is Array:
		WeatherManager.apply_weather_history_save_data(weather_data["daily_history"] as Array)
	else:
		WeatherManager.apply_weather_history_save_data([])

	WeatherManager.weather_changed.emit(
		WeatherManager.current_weather,
		WeatherManager.current_temperature
	)

func _create_market_save_data() -> Dictionary:
	var commodity_data := []

	for commodity in CommodityMarketManager.commodities:
		if commodity == null or commodity.item_data == null:
			continue

		commodity_data.append({
			"item_id": commodity.item_data.id,
			"current_price": commodity.current_price,
			"volatility": commodity.volatility,
			"trend": int(commodity.trend),
			"trend_strength": commodity.trend_strength,
			"price_history": commodity.price_history.duplicate(),
			"price_history_labels": commodity.price_history_labels.duplicate()
		})

	return {
		"commodities": commodity_data
	}

func _apply_market_save_data(market_data: Dictionary) -> void:
	var commodities_data: Array = market_data.get("commodities", [])

	for entry in commodities_data:
		if not entry is Dictionary:
			continue

		var item_id := String(entry.get("item_id", ""))
		var item_data := _get_item_by_id(item_id)

		if item_data == null:
			continue

		var commodity := CommodityMarketManager.get_commodity_for_item(item_data)

		if commodity == null:
			continue

		commodity.current_price = float(entry.get("current_price", commodity.base_price))
		commodity.volatility = float(entry.get("volatility", commodity.volatility))
		commodity.trend = int(entry.get("trend", CommodityData.MarketTrend.NEUTRAL))
		commodity.trend_strength = float(entry.get("trend_strength", commodity.trend_strength))

		commodity.price_history.clear()
		var history: Array = entry.get("price_history", [])

		for value in history:
			commodity.price_history.append(float(value))

		commodity.price_history_labels.clear()
		var labels: Array = entry.get("price_history_labels", [])

		for label in labels:
			commodity.price_history_labels.append(String(label))

	CommodityMarketManager.commodity_prices_updated.emit()

func _create_events_save_data() -> Array:
	var result := []

	for active_event in EventManager.active_market_events:
		if active_event == null or active_event.event_data == null:
			continue

		result.append({
			"event_id": active_event.event_data.event_id,
			"remaining_days": active_event.remaining_days
		})

	return result

func _apply_events_save_data(events_data: Array, emit_change: bool = true) -> void:
	EventManager.active_market_events.clear()

	for entry in events_data:
		if not entry is Dictionary:
			continue

		var event_id := String(entry.get("event_id", ""))
		var event_data := EventManager.get_event_by_id(event_id)

		if event_data == null:
			continue

		var active_event := ActiveMarketEvent.new()
		active_event.setup(event_data)
		active_event.remaining_days = int(entry.get("remaining_days", event_data.duration_days))

		EventManager.active_market_events.append(active_event)

	EventManager._apply_market_event_effects()

	if emit_change:
		EventManager.market_events_changed.emit()


func _create_event_state_save_data() -> Dictionary:
	return {
		"triggered_fixed_events": EventManager.create_calendar_event_state_save_data(),
		"daily_event_limit": EventManager.create_daily_event_limit_save_data(),
		"event_activation_history": EventManager.create_event_activation_history_save_data(),
		"once_per_season_events": EventManager.create_once_per_season_state_save_data(),
		"once_per_year_events": EventManager.create_once_per_year_state_save_data()
	}


func _apply_event_state_save_data(event_state_data: Dictionary) -> void:
	if event_state_data.has("triggered_fixed_events") and event_state_data["triggered_fixed_events"] is Dictionary:
		EventManager.apply_calendar_event_state_save_data(event_state_data["triggered_fixed_events"] as Dictionary)
	else:
		EventManager.apply_calendar_event_state_save_data({})

	if event_state_data.has("daily_event_limit") and event_state_data["daily_event_limit"] is Dictionary:
		EventManager.apply_daily_event_limit_save_data(event_state_data["daily_event_limit"] as Dictionary)
	else:
		EventManager.apply_daily_event_limit_save_data({})

	if event_state_data.has("event_activation_history") and event_state_data["event_activation_history"] is Dictionary:
		EventManager.apply_event_activation_history_save_data(event_state_data["event_activation_history"] as Dictionary)
	else:
		EventManager.apply_event_activation_history_save_data({})

	if event_state_data.has("once_per_season_events") and event_state_data["once_per_season_events"] is Dictionary:
		EventManager.apply_once_per_season_state_save_data(event_state_data["once_per_season_events"] as Dictionary)
	else:
		EventManager.apply_once_per_season_state_save_data({})

	if event_state_data.has("once_per_year_events") and event_state_data["once_per_year_events"] is Dictionary:
		EventManager.apply_once_per_year_state_save_data(event_state_data["once_per_year_events"] as Dictionary)
	else:
		EventManager.apply_once_per_year_state_save_data({})


func _create_news_save_data() -> Array:
	var result := []
	var news_items := NewsManager.news_items

	var count := mini(news_items.size(), MAX_NEWS_SAVE_COUNT)

	for i in range(count):
		var news_item: NewsItem = news_items[i]

		if news_item == null:
			continue

		result.append({
			"title": news_item.title,
			"body": news_item.body,
			"day": news_item.day,
			"month": news_item.month,
			"year": news_item.year,
			"category": news_item.category
		})

	return result


func _apply_news_save_data(news_data: Array) -> void:
	var saved_news_items: Array[NewsItem] = []

	for entry in news_data:
		if not (entry is Dictionary):
			continue

		var news_entry := entry as Dictionary
		var news := NewsItem.new()

		news.title = String(news_entry.get("title", ""))
		news.body = String(news_entry.get("body", ""))
		news.day = int(news_entry.get("day", 1))
		news.month = int(news_entry.get("month", 1))
		news.year = int(news_entry.get("year", 1))
		news.category = String(news_entry.get("category", "Market"))

		saved_news_items.append(news)

		if saved_news_items.size() >= NewsManager.MAX_NEWS_COUNT:
			break

	NewsManager.replace_news_items(saved_news_items)
	EventManager.market_events_changed.emit()

	var news_panel = get_tree().get_first_node_in_group("news_panel")
	if news_panel:
		news_panel.refresh()

func _get_crop_by_id(crop_id: String) -> CropData:
	for crop in crop_database:
		if crop != null and crop.crop_id == crop_id:
			return crop

	return null

func _create_world_save_data() -> Dictionary:
	var tiles_data := []

	var world_manager = get_tree().get_first_node_in_group("world_manager")

	if world_manager == null:
		return {
			"tiles": tiles_data
		}

	for tile in world_manager.get_all_farm_tiles():
		if tile == null:
			continue

		var tile_data := {
			"tile_id": tile.tile_id,
			"state": int(tile.current_state),
			"crop_id": "",
			"crop_growth_days": 0
		}

		if tile.has_crop():
			tile_data["crop_id"] = tile.crop_data.crop_id
			tile_data["crop_growth_days"] = tile.crop_growth_days

		tiles_data.append(tile_data)

	return {
		"tiles": tiles_data
	}

func _apply_world_save_data(world_data: Dictionary) -> void:
	var world_manager = get_tree().get_first_node_in_group("world_manager")

	if world_manager == null:
		print("SaveManager: WorldManager not found")
		return

	var tiles_data: Array = world_data.get("tiles", [])

	for entry in tiles_data:
		if not (entry is Dictionary):
			continue

		var tile_entry := entry as Dictionary
		var tile_id := String(tile_entry.get("tile_id", ""))
		var tile: FarmTile = world_manager.get_tile_by_id(tile_id)

		if tile == null:
			continue

		var state := int(tile_entry.get("state", FarmTile.TileState.GRASS))
		tile.set_state(state)

		var crop_id := String(tile_entry.get("crop_id", ""))
		var growth_days := int(tile_entry.get("crop_growth_days", 0))

		tile.clear_crop()

		if crop_id != "":
			var crop_data := _get_crop_by_id(crop_id)

			if crop_data != null:
				tile.load_crop(crop_data, growth_days)

func _create_player_position_save_data() -> Dictionary:
	var player := get_tree().get_first_node_in_group("player") as Node3D

	if player == null:
		return {}

	return {
		"x": player.global_position.x,
		"y": player.global_position.y,
		"z": player.global_position.z
	}

func _apply_player_position_save_data(position_data: Dictionary) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D

	if player == null:
		return

	player.global_position = Vector3(
		float(position_data.get("x", player.global_position.x)),
		float(position_data.get("y", player.global_position.y)),
		float(position_data.get("z", player.global_position.z))
	)

func get_save_path(slot: int = current_save_slot) -> String:
	slot = clampi(slot, 1, SAVE_SLOT_COUNT)
	return SAVE_PATH_TEMPLATE % slot

func set_current_save_slot(slot: int) -> void:
	current_save_slot = clampi(slot, 1, SAVE_SLOT_COUNT)


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))


func delete_save(slot: int) -> void:
	var path := get_save_path(slot)

	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func start_new_game(slot: int) -> void:
	set_current_save_slot(slot)
	delete_save(slot)
	_reset_runtime_state_for_new_game()
	save_game()
	print("New game started in slot ", slot)

func _reset_runtime_state_for_new_game() -> void:
	MoneyManager.set_money(100)

	TimeManager.current_year = 1
	TimeManager.current_month = 1
	TimeManager.current_day = 1
	TimeManager.current_minute_of_day = 6 * 60
	TimeManager._minute_accumulator = 0.0
	TimeManager.time_changed.emit()

	_reset_inventory()
	_reset_storage()
	_reset_world_tiles()

	WeatherManager._generate_initial_forecast()
	WeatherManager._apply_new_day_weather()

	EventManager.active_market_events.clear()
	EventManager.apply_calendar_event_state_save_data({})
	EventManager.apply_daily_event_limit_save_data({})
	EventManager.apply_event_activation_history_save_data({})
	EventManager.apply_once_per_season_state_save_data({})
	EventManager.apply_once_per_year_state_save_data({})
	EventManager._apply_market_event_effects()
	EventManager.market_events_changed.emit()

	NewsManager.clear_news()

	CommodityMarketManager.reset_event_modifiers()
	CommodityMarketManager.commodity_prices_updated.emit()

func _reset_inventory() -> void:
	var inventory := HotbarManager.inventory_data

	if inventory == null:
		return

	inventory.setup()
	inventory.clear_inventory()

	inventory.add_item(_get_item_by_id("hoe"), 1)
	inventory.add_item(_get_item_by_id("watering_can"), 1)
	inventory.add_item(_get_item_by_id("scythe"), 1)
	inventory.add_item(_get_item_by_id("wheat_seed"), 10)

	inventory.inventory_changed.emit()

func _reset_storage() -> void:
	if silo_storage == null:
		return

	silo_storage.stored_items.clear()
	silo_storage.storage_changed.emit()

func _reset_world_tiles() -> void:
	var world_manager = get_tree().get_first_node_in_group("world_manager")

	if world_manager == null:
		return

	for tile in world_manager.get_all_farm_tiles():
		if tile == null:
			continue

		tile.clear_crop()
		tile.set_state(FarmTile.TileState.GRASS)

func get_save_slot_info(slot: int) -> Dictionary:
	var path := get_save_path(slot)

	if not FileAccess.file_exists(path):
		return {
			"exists": false
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"exists": false
		}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {
			"exists": false
		}

	if not (json.data is Dictionary):
		return {
			"exists": false
		}

	var save_data := json.data as Dictionary
	var player_data := save_data.get("player", {}) as Dictionary
	var time_data := save_data.get("time", {}) as Dictionary

	return {
		"exists": true,
		"money": int(player_data.get("money", 0)),
		"year": int(time_data.get("year", 1)),
		"month": int(time_data.get("month", 1)),
		"day": int(time_data.get("day", 1)),
		"minute_of_day": int(time_data.get("minute_of_day", 0))
	}

func get_season_name_from_month(month: int) -> String:
	match month:
		1:
			return "Spring"
		2:
			return "Summer"
		3:
			return "Autumn"
		4:
			return "Winter"
		_:
			return "Unknown"

func _create_sales_stats_save_data() -> Dictionary:
	return SalesStatsManager.create_save_data()

func _apply_sales_stats_save_data(sales_data: Dictionary) -> void:
	SalesStatsManager.apply_save_data(sales_data)
