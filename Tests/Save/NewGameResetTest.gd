extends RefCounted

var runner: TestRunner
var wheat: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")


func run() -> void:
	print("\n--- NewGameResetTest ---")

	var snapshot := _capture_state()
	_seed_old_runtime_state()

	SaveManager._reset_runtime_state_for_new_game()

	_assert_sales_reset()
	_assert_weather_reset()
	_assert_market_reset()
	_assert_small_runtime_state_reset()

	_restore_state(snapshot)


func _seed_old_runtime_state() -> void:
	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()
	SalesStatsManager.record_sale(wheat, 300)
	var old_sales_history_entry := {}
	old_sales_history_entry[wheat.id] = 200
	SalesStatsManager.sales_history.append(old_sales_history_entry)

	TimeManager.current_year = 2
	TimeManager.current_month = 3
	TimeManager.current_day = 14
	TimeManager.current_minute_of_day = 22 * 60

	WeatherManager.daily_weather_history.clear()
	WeatherManager.daily_weather_history.append({
		"year": 2,
		"season": int(SeasonData.Season.AUTUMN),
		"day": 13,
		"is_rainy": true,
		"base_temperature": 9.0,
		"pattern_id": "old_storm",
		"pattern_name": "Old Storm"
	})
	WeatherManager.forecast.clear()
	WeatherManager.today_phase_forecast.clear()
	WeatherManager.current_day_pattern = WeatherManager.get_day_pattern_by_id("stormy_day")
	WeatherManager.current_day_base_temperature = 3
	WeatherManager.current_day_phase = WeatherPhaseData.DayPhase.NIGHT
	WeatherManager.current_weather = WeatherManager.get_weather_by_name("Storm")
	WeatherManager.current_temperature = -5
	WeatherManager.current_phase_weather = null

	for i in range(CommodityMarketManager.commodities.size()):
		var commodity := CommodityMarketManager.commodities[i]
		if commodity == null:
			continue

		commodity.current_price = commodity.base_price + 42.0 + float(i)
		commodity.trend = CommodityData.MarketTrend.BULLISH
		commodity.trend_strength += 0.2
		commodity.volatility += 0.2
		commodity.price_history = [1.0, 42.42, 99.0]
		commodity.price_history_labels = ["Old Day 09:00", "Old Day 10:00", "Old Day 11:00"]

		if commodity.item_data != null:
			var item_id := commodity.item_data.id
			CommodityMarketManager._event_direction_by_item_id[item_id] = 1.0
			CommodityMarketManager._event_trend_strength_by_item_id[item_id] = 0.2
			CommodityMarketManager._event_volatility_by_item_id[item_id] = 0.2

	CommodityMarketManager.last_processed_day = 14
	CommodityMarketManager.last_processed_hour = 17

	if HotbarManager.hotbar_data != null:
		HotbarManager.hotbar_data.setup()
		HotbarManager.hotbar_data.selected_slot_index = 2
	HotbarManager.selected_slot = 3
	ToolManager.watering_can_water = 7


func _assert_sales_reset() -> void:
	runner.assert_eq(SalesStatsManager.current_day_sales.size(), 0, "New game clears current day sales")
	runner.assert_eq(SalesStatsManager.sales_history.size(), 0, "New game clears sales history")


func _assert_weather_reset() -> void:
	runner.assert_eq(WeatherManager.daily_weather_history.size(), 0, "New game clears completed weather history")
	runner.assert_eq(WeatherManager.forecast.size(), WeatherManager.FORECAST_DAYS, "New game creates seven-day forecast")
	runner.assert_eq(WeatherManager.today_phase_forecast.size(), 4, "New game creates current-day phase forecast")
	runner.assert_eq(
		int(WeatherManager.current_day_phase),
		int(WeatherPhaseData.DayPhase.DAWN),
		"New game weather phase matches 06:00"
	)
	runner.assert_true(WeatherManager.current_phase_weather != null, "New game applies a phase weather")
	runner.assert_eq(
		int(WeatherManager.current_phase_weather.phase),
		int(WeatherPhaseData.DayPhase.DAWN),
		"New game applies the Dawn phase weather"
	)
	runner.assert_true(WeatherManager.current_weather != null, "New game has current weather")
	runner.assert_true(WeatherManager.tomorrow_weather != null, "New game has tomorrow weather")
	runner.assert_eq(
		WeatherManager.current_weather,
		WeatherManager.current_phase_weather.weather,
		"Current weather matches applied phase weather"
	)
	runner.assert_eq(
		WeatherManager.current_temperature,
		WeatherManager.current_phase_weather.temperature,
		"Current temperature matches applied phase weather"
	)
	runner.assert_true(WeatherManager.current_day_pattern != null, "New game has a current day pattern")


func _assert_market_reset() -> void:
	runner.assert_eq(CommodityMarketManager.last_processed_day, -1, "New game clears last processed market day")
	runner.assert_eq(CommodityMarketManager.last_processed_hour, -1, "New game clears last processed market hour")

	for commodity in CommodityMarketManager.commodities:
		if commodity == null:
			continue

		runner.assert_eq(commodity.current_price, commodity.base_price, "New game resets commodity price to base")
		runner.assert_eq(int(commodity.trend), int(CommodityData.MarketTrend.NEUTRAL), "New game resets commodity trend")
		runner.assert_eq(commodity.price_history.size(), 1, "New game creates one starting price history entry")
		runner.assert_eq(commodity.price_history[0], commodity.base_price, "New game history starts at base price")
		runner.assert_eq(commodity.price_history_labels.size(), 1, "New game creates one starting price history label")
		runner.assert_true(not commodity.price_history.has(42.42), "New game removes old commodity history values")
		runner.assert_true(not commodity.price_history_labels.has("Old Day 10:00"), "New game removes old commodity history labels")

		if commodity.item_data == null:
			continue

		var item_id := commodity.item_data.id
		runner.assert_true(
			not CommodityMarketManager._event_direction_by_item_id.has(item_id),
			"New game clears event direction modifiers"
		)
		runner.assert_true(
			not CommodityMarketManager._event_trend_strength_by_item_id.has(item_id),
			"New game clears event trend modifiers"
		)
		runner.assert_true(
			not CommodityMarketManager._event_volatility_by_item_id.has(item_id),
			"New game clears event volatility modifiers"
		)


func _assert_small_runtime_state_reset() -> void:
	runner.assert_eq(HotbarManager.selected_slot, 1, "New game resets selected hotbar slot")

	if HotbarManager.hotbar_data != null:
		runner.assert_eq(
			HotbarManager.hotbar_data.selected_slot_index,
			0,
			"New game resets HotbarData selected slot index"
		)

	runner.assert_eq(ToolManager.watering_can_water, 0, "New game resets watering can water")


func _capture_state() -> Dictionary:
	return {
		"money": MoneyManager.get_money(),
		"time": {
			"year": TimeManager.current_year,
			"month": TimeManager.current_month,
			"day": TimeManager.current_day,
			"minute_of_day": TimeManager.current_minute_of_day,
			"minute_accumulator": TimeManager._minute_accumulator
		},
		"inventory": SaveManager._create_inventory_save_data(),
		"hotbar": SaveManager._create_hotbar_save_data(),
		"storage": SaveManager._create_storage_save_data(),
		"sales": SalesStatsManager.create_save_data(),
		"weather": _capture_weather_state(),
		"market": _capture_market_state(),
		"events": SaveManager._create_events_save_data(),
		"event_state": SaveManager._create_event_state_save_data(),
		"news": SaveManager._create_news_save_data(),
		"buy_price_modifiers": EconomyManager.buy_price_multipliers_by_item_id.duplicate(true),
		"tool_water": ToolManager.watering_can_water,
		"tool_capacity": ToolManager.watering_can_capacity
	}


func _capture_weather_state() -> Dictionary:
	return {
		"current_day_pattern": WeatherManager.current_day_pattern,
		"current_day_base_temperature": WeatherManager.current_day_base_temperature,
		"current_weather": WeatherManager.current_weather,
		"tomorrow_weather": WeatherManager.tomorrow_weather,
		"today_phase_forecast": WeatherManager.today_phase_forecast.duplicate(),
		"current_phase_weather": WeatherManager.current_phase_weather,
		"current_temperature": WeatherManager.current_temperature,
		"tomorrow_temperature": WeatherManager.tomorrow_temperature,
		"current_day_phase": WeatherManager.current_day_phase,
		"forecast": WeatherManager.forecast.duplicate(true),
		"daily_weather_history": WeatherManager.daily_weather_history.duplicate(true)
	}


func _capture_market_state() -> Dictionary:
	var commodity_states := []

	for commodity in CommodityMarketManager.commodities:
		if commodity == null:
			commodity_states.append(null)
			continue

		commodity_states.append({
			"current_price": commodity.current_price,
			"volatility": commodity.volatility,
			"trend": commodity.trend,
			"trend_strength": commodity.trend_strength,
			"price_history": commodity.price_history.duplicate(),
			"price_history_labels": commodity.price_history_labels.duplicate()
		})

	return {
		"commodities": commodity_states,
		"last_processed_day": CommodityMarketManager.last_processed_day,
		"last_processed_hour": CommodityMarketManager.last_processed_hour,
		"event_direction": CommodityMarketManager._event_direction_by_item_id.duplicate(true),
		"event_trend_strength": CommodityMarketManager._event_trend_strength_by_item_id.duplicate(true),
		"event_volatility": CommodityMarketManager._event_volatility_by_item_id.duplicate(true)
	}


func _restore_state(snapshot: Dictionary) -> void:
	MoneyManager.set_money(int(snapshot["money"]))

	var time_data := snapshot["time"] as Dictionary
	TimeManager.current_year = int(time_data["year"])
	TimeManager.current_month = int(time_data["month"])
	TimeManager.current_day = int(time_data["day"])
	TimeManager.current_minute_of_day = int(time_data["minute_of_day"])
	TimeManager._minute_accumulator = float(time_data["minute_accumulator"])

	SaveManager._apply_inventory_save_data(snapshot["inventory"] as Array)
	SaveManager._apply_hotbar_save_data(snapshot["hotbar"] as Dictionary)
	SaveManager._apply_storage_save_data(snapshot["storage"] as Dictionary)
	SalesStatsManager.apply_save_data(snapshot["sales"] as Dictionary)
	_restore_weather_state(snapshot["weather"] as Dictionary)
	SaveManager._apply_event_state_save_data(snapshot["event_state"] as Dictionary)
	SaveManager._apply_events_save_data(snapshot["events"] as Array)
	SaveManager._apply_news_save_data(snapshot["news"] as Array)
	_restore_market_state(snapshot["market"] as Dictionary)

	EconomyManager.buy_price_multipliers_by_item_id = (snapshot["buy_price_modifiers"] as Dictionary).duplicate(true)
	EconomyManager.buy_prices_changed.emit()
	ToolManager.watering_can_water = int(snapshot["tool_water"])
	ToolManager.watering_can_capacity = int(snapshot["tool_capacity"])
	ToolManager.watering_can_changed.emit()


func _restore_weather_state(weather_state: Dictionary) -> void:
	WeatherManager.current_day_pattern = weather_state["current_day_pattern"] as WeatherDayPatternData
	WeatherManager.current_day_base_temperature = int(weather_state["current_day_base_temperature"])
	WeatherManager.current_weather = weather_state["current_weather"] as WeatherData
	WeatherManager.tomorrow_weather = weather_state["tomorrow_weather"] as WeatherData
	WeatherManager.today_phase_forecast.clear()
	for phase_data in (weather_state["today_phase_forecast"] as Array):
		WeatherManager.today_phase_forecast.append(phase_data)
	WeatherManager.current_phase_weather = weather_state["current_phase_weather"] as WeatherPhaseData
	WeatherManager.current_temperature = int(weather_state["current_temperature"])
	WeatherManager.tomorrow_temperature = int(weather_state["tomorrow_temperature"])
	WeatherManager.current_day_phase = int(weather_state["current_day_phase"]) as WeatherPhaseData.DayPhase
	WeatherManager.forecast.clear()
	for entry in (weather_state["forecast"] as Array):
		WeatherManager.forecast.append(entry)
	WeatherManager.daily_weather_history.clear()
	for entry in (weather_state["daily_weather_history"] as Array):
		WeatherManager.daily_weather_history.append(entry)
	WeatherManager.weather_changed.emit(WeatherManager.current_weather, WeatherManager.current_temperature)


func _restore_market_state(market_state: Dictionary) -> void:
	var commodity_states := market_state["commodities"] as Array

	for i in range(CommodityMarketManager.commodities.size()):
		var commodity := CommodityMarketManager.commodities[i]
		if commodity == null or i >= commodity_states.size() or commodity_states[i] == null:
			continue

		var commodity_state := commodity_states[i] as Dictionary
		commodity.current_price = float(commodity_state["current_price"])
		commodity.volatility = float(commodity_state["volatility"])
		commodity.trend = int(commodity_state["trend"]) as CommodityData.MarketTrend
		commodity.trend_strength = float(commodity_state["trend_strength"])
		commodity.price_history = (commodity_state["price_history"] as Array).duplicate()
		commodity.price_history_labels = (commodity_state["price_history_labels"] as Array).duplicate()

	CommodityMarketManager.last_processed_day = int(market_state["last_processed_day"])
	CommodityMarketManager.last_processed_hour = int(market_state["last_processed_hour"])
	CommodityMarketManager._event_direction_by_item_id = (market_state["event_direction"] as Dictionary).duplicate(true)
	CommodityMarketManager._event_trend_strength_by_item_id = (market_state["event_trend_strength"] as Dictionary).duplicate(true)
	CommodityMarketManager._event_volatility_by_item_id = (market_state["event_volatility"] as Dictionary).duplicate(true)
	CommodityMarketManager.commodity_prices_updated.emit()
