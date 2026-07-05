extends RefCounted

var runner: TestRunner

const DAYS_IN_YEAR: int = 120
const SIMULATION_SEED: int = 123456
const OUTPUT_DIRECTORY: String = "user://simulation_reports/"
const DAILY_REPORT_NAME: String = "full_year_daily.csv"
const EVENTS_REPORT_NAME: String = "full_year_events.csv"

var _daily_rows: Array[Dictionary] = []
var _daily_headers: Array[String] = []
var _validation_errors: Array[String] = []
var _product_ids: Array[String] = []
var _seed_ids: Array[String] = []
var _base_seed_prices: Dictionary = {}
var _base_volatility_by_product: Dictionary = {}
var _event_stats: Dictionary = {}
var _product_stats: Dictionary = {}
var _seed_stats: Dictionary = {}
var _started_today: Array[String] = []
var _ended_today: Array[String] = []
var _days_without_events: int = 0
var _max_simultaneous_events: int = 0
var _previous_active_ids: Array[String] = []
var _day_durations_msec: Array[int] = []
var _total_duration_msec: int = 0
var _executed_days: int = 0
var _previous_commodity_logs_suppressed := false
var _previous_weather_logs_suppressed := false
var _previous_event_logs_suppressed := false


func run() -> void:
	print("\n--- FullYearSimulationTest ---")
	test_full_year_simulation()


func test_full_year_simulation() -> void:
	var start_time: int = Time.get_ticks_msec()

	_prepare_simulation()
	_prepare_reports()
	_suppress_production_logs()

	for simulation_day: int in range(1, DAYS_IN_YEAR + 1):
		_simulate_next_day(simulation_day)
		_collect_daily_data(simulation_day)
		_collect_event_statistics(simulation_day)

		if simulation_day % 10 == 0:
			print("Simulation progress: %d/120" % simulation_day)

	_restore_production_logs()
	_total_duration_msec = Time.get_ticks_msec() - start_time

	var validation_errors: Array[String] = _validate_simulation()

	_save_daily_report()
	_save_event_report()
	_print_summary(validation_errors)
	_assert_result(validation_errors)


func _prepare_simulation() -> void:
	seed(SIMULATION_SEED)

	TimeManager.is_time_running = false
	TimeManager.current_year = 1
	TimeManager.current_month = 1
	TimeManager.current_day = 1
	TimeManager.current_minute_of_day = 6 * 60
	TimeManager._minute_accumulator = 0.0
	TimeManager.time_changed.emit()

	WeatherManager.apply_weather_history_save_data([])
	WeatherManager._generate_initial_forecast()
	WeatherManager._apply_new_day_weather()
	WeatherManager._generate_today_phase_forecast()
	WeatherManager.current_day_phase = WeatherManager.get_current_day_phase()
	WeatherManager._apply_current_phase_weather()

	EventManager.active_market_events.clear()
	EventManager.apply_calendar_event_state_save_data({})
	EventManager.apply_daily_event_limit_save_data({})
	EventManager._events_started_today = 0
	EventManager._events_started_today_key = ""
	EventManager._apply_market_event_effects()
	EventManager.market_events_changed.emit()

	CommodityMarketManager.last_processed_day = -1
	CommodityMarketManager.last_processed_hour = -1
	CommodityMarketManager.reset_event_modifiers()
	_reset_commodity_runtime_values()

	EconomyManager.reset_buy_price_modifiers()
	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()
	NewsManager.clear_news()

	if not EventManager.market_event_started.is_connected(_on_market_event_started):
		EventManager.market_event_started.connect(_on_market_event_started)

	if not EventManager.market_event_ended.is_connected(_on_market_event_ended):
		EventManager.market_event_ended.connect(_on_market_event_ended)

	_started_today.clear()
	_ended_today.clear()
	_previous_active_ids = _get_active_event_ids()


func _prepare_reports() -> void:
	_daily_rows.clear()
	_validation_errors.clear()
	_event_stats.clear()
	_product_stats.clear()
	_seed_stats.clear()
	_base_seed_prices.clear()
	_base_volatility_by_product.clear()
	_days_without_events = 0
	_max_simultaneous_events = 0
	_day_durations_msec.clear()
	_total_duration_msec = 0
	_executed_days = 0

	_product_ids = _get_sorted_product_ids()
	_seed_ids = _get_sorted_seed_ids()

	_daily_headers = [
		"simulation_day",
		"year",
		"season",
		"season_day",
		"weather",
		"temperature",
		"active_events",
		"started_events",
		"ended_events",
		"active_event_count"
	]

	for product_id in _product_ids:
		_daily_headers.append("%s_price" % product_id)
		_daily_headers.append("%s_trend" % product_id)
		_daily_headers.append("%s_volatility" % product_id)
		_product_stats[product_id] = {
			"min_price": INF,
			"max_price": -INF,
			"total_price": 0.0,
			"price_days": 0,
			"bullish_days": 0,
			"bearish_days": 0,
			"neutral_days": 0,
			"max_volatility": 0.0,
			"total_volatility": 0.0
		}

	for seed_id in _seed_ids:
		_daily_headers.append("%s_buy_price" % seed_id)
		var seed_item := SaveManager._get_item_by_id(seed_id)
		var base_price := EconomyManager.get_buy_price(seed_item)
		_base_seed_prices[seed_id] = base_price
		_seed_stats[seed_id] = {
			"base_price": base_price,
			"min_price": INF,
			"max_price": -INF,
			"modified_days": 0
		}

	for commodity in CommodityMarketManager.commodities:
		if commodity != null and commodity.item_data != null:
			_base_volatility_by_product[commodity.item_data.id] = commodity.volatility

	for event_data in EventManager.possible_market_events:
		if event_data == null:
			continue

		_event_stats[event_data.event_id] = {
			"activation_count": 0,
			"total_active_days": 0,
			"first_activation_day": 0,
			"last_activation_day": 0
		}


func _simulate_next_day(simulation_day: int) -> void:
	var start_time: int = Time.get_ticks_msec()

	_started_today.clear()
	_ended_today.clear()
	TimeManager.advance_day_for_test()
	_executed_days += 1

	var duration_msec := Time.get_ticks_msec() - start_time
	_day_durations_msec.append(duration_msec)


func _collect_daily_data(simulation_day: int) -> void:
	var active_ids := _get_active_event_ids()
	active_ids.sort()
	_started_today.sort()
	_ended_today.sort()

	var row: Dictionary = {
		"simulation_day": simulation_day,
		"year": TimeManager.current_year,
		"season": TimeManager.get_current_season_display_name(),
		"season_day": TimeManager.current_day,
		"weather": WeatherManager.get_current_weather_name(),
		"temperature": WeatherManager.current_temperature,
		"active_events": "|".join(active_ids),
		"started_events": "|".join(_started_today),
		"ended_events": "|".join(_ended_today),
		"active_event_count": active_ids.size()
	}

	if active_ids.is_empty():
		_days_without_events += 1

	_max_simultaneous_events = maxi(_max_simultaneous_events, active_ids.size())

	for product_id in _product_ids:
		var commodity := _get_commodity_by_product_id(product_id)
		if commodity == null:
			_add_validation_error(simulation_day, "Missing commodity for product %s" % product_id)
			continue

		row["%s_price" % product_id] = commodity.current_price
		row["%s_trend" % product_id] = _trend_to_string(commodity.trend)
		row["%s_volatility" % product_id] = commodity.volatility
		_collect_product_stats(product_id, commodity)
		_validate_commodity(simulation_day, commodity)

	for seed_id in _seed_ids:
		var seed_item := SaveManager._get_item_by_id(seed_id)
		var buy_price := EconomyManager.get_buy_price(seed_item)
		row["%s_buy_price" % seed_id] = buy_price
		_collect_seed_stats(seed_id, buy_price)
		_validate_seed_price(simulation_day, seed_id, buy_price)

	_daily_rows.append(row)
	_validate_active_events(simulation_day)
	_validate_daily_event_rules(simulation_day)


func _collect_event_statistics(simulation_day: int) -> void:
	for event_id in _started_today:
		_ensure_event_stat(event_id)
		var stats := _event_stats[event_id] as Dictionary
		stats["activation_count"] = int(stats["activation_count"]) + 1

		if int(stats["first_activation_day"]) == 0:
			stats["first_activation_day"] = simulation_day

		stats["last_activation_day"] = simulation_day

	for active_event in EventManager.get_active_market_events():
		if active_event == null or active_event.event_data == null:
			continue

		var event_id := active_event.event_data.event_id
		_ensure_event_stat(event_id)
		var stats := _event_stats[event_id] as Dictionary
		stats["total_active_days"] = int(stats["total_active_days"]) + 1

	_previous_active_ids = _get_active_event_ids()


func _validate_simulation() -> Array[String]:
	if _daily_rows.size() != DAYS_IN_YEAR:
		_validation_errors.append("Expected %d simulated days, got %d" % [DAYS_IN_YEAR, _daily_rows.size()])

	if TimeManager.current_year != 2 or TimeManager.current_month != 1 or TimeManager.current_day != 1:
		_validation_errors.append(
			"Calendar expected Year 2 Spring day 1 after 120 advances, got year=%d month=%d day=%d" % [
				TimeManager.current_year,
				TimeManager.current_month,
				TimeManager.current_day
			]
		)

	_validate_required_event_outcomes()
	_validate_seed_modifiers_cleared()
	_validate_news_count()
	_validate_volatility_reset_state()

	return _validation_errors


func _save_daily_report() -> void:
	_save_csv(OUTPUT_DIRECTORY.path_join(DAILY_REPORT_NAME), _daily_headers, _daily_rows)


func _save_event_report() -> void:
	var rows: Array[Dictionary] = []
	var event_ids := _event_stats.keys()
	event_ids.sort()

	for event_id in event_ids:
		var stats := _event_stats[event_id] as Dictionary
		rows.append({
			"event_id": event_id,
			"activation_count": stats["activation_count"],
			"total_active_days": stats["total_active_days"],
			"first_activation_day": stats["first_activation_day"],
			"last_activation_day": stats["last_activation_day"]
		})

	_save_csv(
		OUTPUT_DIRECTORY.path_join(EVENTS_REPORT_NAME),
		[
			"event_id",
			"activation_count",
			"total_active_days",
			"first_activation_day",
			"last_activation_day"
		],
		rows
	)


func _print_summary(validation_errors: Array[String]) -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	print("Full year simulation completed")
	print("Seed: ", SIMULATION_SEED)
	print("Days simulated: ", _daily_rows.size())
	print("Executed day advances: ", _executed_days)
	print("Total simulation time: %d ms" % _total_duration_msec)
	print("Slowest simulated day: %d ms" % _get_slowest_day_duration_msec())
	print("Events activated: ", _get_total_event_activations())
	print("Days without events: ", _days_without_events)
	print("Maximum simultaneous events: ", _max_simultaneous_events)
	print("Validation errors: ", validation_errors.size())
	print("Daily report:")
	print(output_path.path_join(DAILY_REPORT_NAME))
	print("Event report:")
	print(output_path.path_join(EVENTS_REPORT_NAME))

	for product_id in _product_ids:
		var stats := _product_stats[product_id] as Dictionary
		var days := maxi(int(stats["price_days"]), 1)
		print("%s:" % _display_name_for_item_id(product_id))
		print("min price: %.2f" % float(stats["min_price"]))
		print("max price: %.2f" % float(stats["max_price"]))
		print("average price: %.2f" % (float(stats["total_price"]) / float(days)))
		print("max volatility: %.4f" % float(stats["max_volatility"]))

	if not validation_errors.is_empty():
		for error in validation_errors:
			push_error(error)


func _assert_result(validation_errors: Array[String]) -> void:
	runner.assert_eq(validation_errors.size(), 0, "Full year simulation validation")


func _reset_commodity_runtime_values() -> void:
	for commodity in CommodityMarketManager.commodities:
		if commodity == null:
			continue

		commodity.current_price = commodity.base_price
		commodity.trend = CommodityData.MarketTrend.NEUTRAL
		commodity.price_history.clear()
		commodity.price_history_labels.clear()

		if commodity.item_data != null:
			var label := "%s %s" % [TimeManager.get_date_string(), TimeManager.get_time_string()]
			commodity.price_history.append(commodity.current_price)
			commodity.price_history_labels.append(label)


func _collect_product_stats(product_id: String, commodity: CommodityData) -> void:
	var stats := _product_stats[product_id] as Dictionary
	stats["min_price"] = minf(float(stats["min_price"]), commodity.current_price)
	stats["max_price"] = maxf(float(stats["max_price"]), commodity.current_price)
	stats["total_price"] = float(stats["total_price"]) + commodity.current_price
	stats["price_days"] = int(stats["price_days"]) + 1
	stats["max_volatility"] = maxf(float(stats["max_volatility"]), commodity.volatility)
	stats["total_volatility"] = float(stats["total_volatility"]) + commodity.volatility

	match commodity.trend:
		CommodityData.MarketTrend.BULLISH:
			stats["bullish_days"] = int(stats["bullish_days"]) + 1
		CommodityData.MarketTrend.BEARISH:
			stats["bearish_days"] = int(stats["bearish_days"]) + 1
		CommodityData.MarketTrend.NEUTRAL:
			stats["neutral_days"] = int(stats["neutral_days"]) + 1


func _collect_seed_stats(seed_id: String, buy_price: int) -> void:
	var stats := _seed_stats[seed_id] as Dictionary
	stats["min_price"] = minf(float(stats["min_price"]), float(buy_price))
	stats["max_price"] = maxf(float(stats["max_price"]), float(buy_price))

	if buy_price != int(_base_seed_prices.get(seed_id, buy_price)):
		stats["modified_days"] = int(stats["modified_days"]) + 1


func _validate_commodity(simulation_day: int, commodity: CommodityData) -> void:
	if commodity.item_data == null:
		_add_validation_error(simulation_day, "Commodity without item_data")
		return

	var product_id := commodity.item_data.id
	var price := commodity.current_price
	var volatility := commodity.volatility

	if is_nan(price) or is_inf(price):
		_add_validation_error(simulation_day, "%s price is not finite" % product_id)

	if price < 0.0:
		_add_validation_error(simulation_day, "%s price is negative" % product_id)

	var min_price := commodity.base_price * commodity.min_price_multiplier
	var max_price := commodity.base_price * commodity.max_price_multiplier

	if price < min_price - 0.01:
		_add_validation_error(simulation_day, "%s price %.2f below min %.2f" % [product_id, price, min_price])

	if price > max_price + 0.01:
		_add_validation_error(simulation_day, "%s price %.2f above max %.2f" % [product_id, price, max_price])

	if is_nan(volatility) or is_inf(volatility):
		_add_validation_error(simulation_day, "%s volatility is not finite" % product_id)

	if volatility < 0.0:
		_add_validation_error(simulation_day, "%s volatility is negative" % product_id)


func _validate_seed_price(simulation_day: int, seed_id: String, buy_price: int) -> void:
	if buy_price < 0:
		_add_validation_error(simulation_day, "%s buy price is negative" % seed_id)


func _validate_active_events(simulation_day: int) -> void:
	var seen_ids := {}

	for active_event in EventManager.get_active_market_events():
		if active_event == null:
			_add_validation_error(simulation_day, "Null active event")
			continue

		if active_event.event_data == null:
			_add_validation_error(simulation_day, "Active event without event_data")
			continue

		var event_id := active_event.event_data.event_id

		if seen_ids.has(event_id):
			_add_validation_error(simulation_day, "Duplicate active event %s" % event_id)

		seen_ids[event_id] = true

		if active_event.remaining_days < 0:
			_add_validation_error(simulation_day, "%s has negative remaining_days" % event_id)

		if active_event.remaining_days > active_event.event_data.duration_days:
			_add_validation_error(simulation_day, "%s remaining_days exceeds declared duration" % event_id)

	if EventManager.get_active_market_events().size() > 8:
		_add_validation_error(simulation_day, "Too many simultaneous active events")


func _validate_daily_event_rules(simulation_day: int) -> void:
	for event_id in _started_today:
		var event_data := EventManager.get_event_by_id(event_id)
		if event_data == null:
			continue

		if event_data.requires_season and not event_data.required_seasons.has(TimeManager.get_current_season()):
			_add_validation_error(simulation_day, "%s started outside required season" % event_id)

		if event_data.requires_day_range:
			if TimeManager.current_day < event_data.start_day or TimeManager.current_day > event_data.end_day:
				_add_validation_error(simulation_day, "%s started outside day range" % event_id)

		if event_data.trigger_mode == MarketEventData.TriggerMode.FIXED_DATE:
			var day_key := "%s:%d:%d:%d" % [
				event_id,
				TimeManager.current_year,
				TimeManager.current_month,
				TimeManager.current_day
			]
			var duplicate_count := 0
			for started_id in _started_today:
				if started_id == event_id:
					duplicate_count += 1

			if duplicate_count > 1:
				_add_validation_error(simulation_day, "%s started more than once on %s" % [event_id, day_key])


func _validate_required_event_outcomes() -> void:
	var halloween := _event_stats.get("halloween_pumpkin_demand", {}) as Dictionary
	var halloween_count := int(halloween.get("activation_count", 0))

	if halloween_count != 1:
		_validation_errors.append("Halloween expected exactly 1 activation, got %d" % halloween_count)

	var spring := _event_stats.get("spring_planting_boom", {}) as Dictionary
	var spring_count := int(spring.get("activation_count", 0))

	if spring_count != 1:
		_validation_errors.append("Spring Planting Boom expected exactly 1 activation, got %d" % spring_count)

	if spring_count == 1:
		var first_day := int(spring.get("first_activation_day", 0))
		if first_day < 1 or first_day > 7:
			_validation_errors.append("Spring Planting Boom started outside expected simulation day range 1-7")


func _validate_seed_modifiers_cleared() -> void:
	for seed_id in _seed_ids:
		var seed_item := SaveManager._get_item_by_id(seed_id)
		var current_price := EconomyManager.get_buy_price(seed_item)
		var base_price := int(_base_seed_prices.get(seed_id, current_price))

		if current_price != base_price:
			_validation_errors.append("%s buy price did not return to base after events" % seed_id)

	if not EconomyManager.buy_price_multipliers_by_item_id.is_empty():
		_validation_errors.append("Runtime buy price modifiers remain active after simulation")


func _validate_news_count() -> void:
	if NewsManager.news_items.size() > NewsManager.MAX_NEWS_COUNT:
		_validation_errors.append("News count exceeded MAX_NEWS_COUNT")


func _validate_volatility_reset_state() -> void:
	for commodity in CommodityMarketManager.commodities:
		if commodity == null or commodity.item_data == null:
			continue

		if _is_product_modified_by_active_event(commodity.item_data.id):
			continue

		var base_volatility := float(_base_volatility_by_product.get(commodity.item_data.id, commodity.volatility))
		if absf(commodity.volatility - base_volatility) > 0.0001:
			_validation_errors.append("%s volatility did not return to base without active event" % commodity.item_data.id)


func _is_product_modified_by_active_event(product_id: String) -> bool:
	for active_event in EventManager.get_active_market_events():
		if active_event == null or active_event.event_data == null:
			continue

		for item in active_event.event_data.get_affected_items():
			if item != null and item.id == product_id:
				return true

	return false


func _save_csv(path: String, headers: Array[String], rows: Array[Dictionary]) -> void:
	var absolute_directory := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_directory)

	if dir_error != OK:
		_validation_errors.append("Could not create report directory: %s" % absolute_directory)
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_validation_errors.append("Could not open CSV for writing: %s error=%d" % [path, FileAccess.get_open_error()])
		return

	file.store_line(_csv_line(headers))

	for row in rows:
		var values: Array[String] = []
		for header in headers:
			values.append(str(row.get(header, "")))
		file.store_line(_csv_line(values))

	file.close()


func _csv_line(values: Array[String]) -> String:
	var escaped: Array[String] = []

	for value in values:
		escaped.append(_csv_escape(value))

	return ",".join(escaped)


func _csv_escape(value: String) -> String:
	var escaped := value.replace("\"", "\"\"")

	if escaped.contains(",") or escaped.contains("\"") or escaped.contains("\n") or escaped.contains("\r"):
		return "\"%s\"" % escaped

	return escaped


func _get_sorted_product_ids() -> Array[String]:
	var ids: Array[String] = []

	for commodity in CommodityMarketManager.commodities:
		if commodity != null and commodity.item_data != null:
			ids.append(commodity.item_data.id)

	ids.sort()
	return ids


func _get_sorted_seed_ids() -> Array[String]:
	var ids: Array[String] = []

	for price_data in EconomyManager.price_data_list:
		if price_data == null or price_data.item_data == null:
			continue

		if price_data.item_data.category == ItemData.ItemCategory.SEED:
			ids.append(price_data.item_data.id)

	ids.sort()
	return ids


func _get_commodity_by_product_id(product_id: String) -> CommodityData:
	for commodity in CommodityMarketManager.commodities:
		if commodity != null and commodity.item_data != null and commodity.item_data.id == product_id:
			return commodity

	return null


func _get_active_event_ids() -> Array[String]:
	var ids: Array[String] = []

	for active_event in EventManager.get_active_market_events():
		if active_event != null and active_event.event_data != null:
			ids.append(active_event.event_data.event_id)

	return ids


func _ensure_event_stat(event_id: String) -> void:
	if _event_stats.has(event_id):
		return

	_event_stats[event_id] = {
		"activation_count": 0,
		"total_active_days": 0,
		"first_activation_day": 0,
		"last_activation_day": 0
	}


func _get_total_event_activations() -> int:
	var total := 0

	for event_id in _event_stats.keys():
		var stats := _event_stats[event_id] as Dictionary
		total += int(stats["activation_count"])

	return total


func _get_slowest_day_duration_msec() -> int:
	var slowest := 0

	for duration in _day_durations_msec:
		slowest = maxi(slowest, duration)

	return slowest


func _suppress_production_logs() -> void:
	_previous_commodity_logs_suppressed = CommodityMarketManager.suppress_logs
	_previous_weather_logs_suppressed = WeatherManager.suppress_logs
	_previous_event_logs_suppressed = EventManager.suppress_logs

	CommodityMarketManager.suppress_logs = true
	WeatherManager.suppress_logs = true
	EventManager.suppress_logs = true


func _restore_production_logs() -> void:
	CommodityMarketManager.suppress_logs = _previous_commodity_logs_suppressed
	WeatherManager.suppress_logs = _previous_weather_logs_suppressed
	EventManager.suppress_logs = _previous_event_logs_suppressed


func _trend_to_string(trend: CommodityData.MarketTrend) -> String:
	match trend:
		CommodityData.MarketTrend.BEARISH:
			return "bearish"
		CommodityData.MarketTrend.BULLISH:
			return "bullish"
		CommodityData.MarketTrend.NEUTRAL:
			return "neutral"
		_:
			return "unknown"


func _display_name_for_item_id(item_id: String) -> String:
	var item := SaveManager._get_item_by_id(item_id)
	if item != null and not item.display_name.is_empty():
		return item.display_name

	return item_id.capitalize()


func _add_validation_error(simulation_day: int, message: String) -> void:
	_validation_errors.append("Day %d: %s" % [simulation_day, message])


func _on_market_event_started(event_data: MarketEventData) -> void:
	if event_data == null:
		return

	_started_today.append(event_data.event_id)


func _on_market_event_ended(event_data: MarketEventData) -> void:
	if event_data == null:
		return

	_ended_today.append(event_data.event_id)
