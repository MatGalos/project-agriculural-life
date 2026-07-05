extends RefCounted

var runner: TestRunner

const DAYS_IN_YEAR: int = 120
const SIMULATION_SEEDS: Array[int] = [
	123456,
	234567,
	345678,
	456789,
	567890
]
const OUTPUT_DIRECTORY: String = "user://simulation_reports/"
const DAILY_REPORT_TEMPLATE: String = "full_year_daily_seed_%d.csv"
const EVENTS_REPORT_TEMPLATE: String = "full_year_events_seed_%d.csv"
const VALIDATION_REPORT_TEMPLATE: String = "full_year_validation_seed_%d.csv"
const MULTI_SEED_SUMMARY_NAME: String = "full_year_multi_seed_summary.csv"
const MULTI_SEED_AGGREGATE_NAME: String = "full_year_multi_seed_aggregate.csv"

var _daily_rows: Array[Dictionary] = []
var _daily_headers: Array[String] = []
var _validation_errors: Array[Dictionary] = []
var _balance_warnings: Array[String] = []
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
var _total_active_event_count: int = 0
var _event_category_activation_counts: Dictionary = {}
var _bullish_event_activations: int = 0
var _bearish_event_activations: int = 0
var _last_activation_day_by_event: Dictionary = {}
var _once_per_season_activation_keys: Dictionary = {}
var _previous_active_ids: Array[String] = []
var _day_durations_msec: Array[int] = []
var _total_duration_msec: int = 0
var _executed_days: int = 0
var _previous_commodity_logs_suppressed := false
var _previous_weather_logs_suppressed := false
var _previous_event_logs_suppressed := false


func run() -> void:
	print("\n--- FullYearSimulationTest ---")
	test_multiple_full_year_simulations()


func test_multiple_full_year_simulations() -> void:
	var all_results: Array[Dictionary] = []

	_suppress_production_logs()

	for simulation_seed: int in SIMULATION_SEEDS:
		var result := _run_single_year(simulation_seed)
		all_results.append(result)

	_restore_production_logs()

	_save_multi_seed_summary(all_results)
	_save_multi_seed_aggregate(all_results)

	var diversity_errors := _validate_seed_diversity(all_results)
	_print_multi_seed_summary(all_results, diversity_errors)

	runner.assert_eq(_get_failed_seed_count(all_results) + diversity_errors.size(), 0, "Full year multi-seed simulation validation")


func test_full_year_simulation() -> void:
	var result := _run_single_year(SIMULATION_SEEDS[0])
	runner.assert_eq(int(result["validation_error_count"]), 0, "Full year single-seed simulation validation")


func _run_single_year(simulation_seed: int) -> Dictionary:
	var start_time: int = Time.get_ticks_msec()

	_prepare_simulation(simulation_seed)
	_prepare_reports()
	_prepare_first_day_for_report()

	_collect_current_day_data(1)

	for simulation_day: int in range(2, DAYS_IN_YEAR + 1):
		_simulate_next_day(simulation_day)
		_collect_current_day_data(simulation_day)

		if simulation_day % 10 == 0:
			print("Simulation progress seed %d: %d/120" % [simulation_seed, simulation_day])

	_total_duration_msec = Time.get_ticks_msec() - start_time

	var validation_errors: Array[Dictionary] = _validate_simulation()
	_collect_balance_warnings()

	_save_daily_report(simulation_seed)
	_save_event_report(simulation_seed)
	_save_validation_report(simulation_seed)
	_print_summary(simulation_seed, validation_errors)

	return _create_seed_result(simulation_seed, validation_errors)


func _prepare_simulation(simulation_seed: int) -> void:
	seed(simulation_seed)

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
	EventManager.apply_event_activation_history_save_data({})
	EventManager.apply_once_per_season_state_save_data({})
	EventManager.apply_once_per_year_state_save_data({})
	EventManager._events_started_today = 0
	EventManager._market_events_started_today = 0
	EventManager._events_started_today_key = ""
	EventManager.process_day_synchronously_for_test = false
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


func _prepare_first_day_for_report() -> void:
	_started_today.clear()
	_ended_today.clear()
	EventManager._try_trigger_fixed_date_events_for_current_day()


func _prepare_reports() -> void:
	_daily_rows.clear()
	_validation_errors.clear()
	_balance_warnings.clear()
	_event_stats.clear()
	_product_stats.clear()
	_seed_stats.clear()
	_base_seed_prices.clear()
	_base_volatility_by_product.clear()
	_days_without_events = 0
	_max_simultaneous_events = 0
	_total_active_event_count = 0
	_event_category_activation_counts.clear()
	_bullish_event_activations = 0
	_bearish_event_activations = 0
	_last_activation_day_by_event.clear()
	_once_per_season_activation_keys.clear()
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
			"max_price_days": 0,
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
			"last_activation_day": 0,
			"category": _event_category_to_string(event_data.event_category),
			"trend_effect": _trend_to_string(event_data.trend_effect)
		}


func _collect_current_day_data(simulation_day: int) -> void:
	_collect_daily_data(simulation_day)
	_collect_event_statistics(simulation_day)


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
		"season_index": int(TimeManager.get_current_season()),
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
	_total_active_event_count += active_ids.size()

	for product_id in _product_ids:
		var commodity := _get_commodity_by_product_id(product_id)
		if commodity == null:
			_add_validation_error(simulation_day, "MISSING_COMMODITY", "Missing commodity for product %s" % product_id)
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
		_validate_activation_spacing(simulation_day, event_id)
		var stats := _event_stats[event_id] as Dictionary
		stats["activation_count"] = int(stats["activation_count"]) + 1
		_collect_event_activation_balance_stats(event_id)

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


func _validate_simulation() -> Array[Dictionary]:
	if _daily_rows.size() != DAYS_IN_YEAR:
		_add_global_validation_error(
			"WRONG_REPORTED_DAY_COUNT",
			"Expected %d reported days, got %d" % [DAYS_IN_YEAR, _daily_rows.size()]
		)

	_validate_reported_date_range()
	_validate_required_event_outcomes()
	_validate_seed_modifiers_cleared()
	_validate_news_count()
	_validate_volatility_reset_state()

	return _validation_errors


func _save_daily_report(simulation_seed: int) -> void:
	_save_csv(OUTPUT_DIRECTORY.path_join(DAILY_REPORT_TEMPLATE % simulation_seed), _daily_headers, _daily_rows)


func _save_event_report(simulation_seed: int) -> void:
	var rows: Array[Dictionary] = []
	var event_ids := _event_stats.keys()
	event_ids.sort()

	for event_id in event_ids:
		var stats := _event_stats[event_id] as Dictionary
		rows.append({
			"event_id": event_id,
			"category": stats.get("category", "unknown"),
			"trend_effect": stats.get("trend_effect", "unknown"),
			"activation_count": stats["activation_count"],
			"total_active_days": stats["total_active_days"],
			"first_activation_day": stats["first_activation_day"],
			"last_activation_day": stats["last_activation_day"]
		})

	_save_csv(
		OUTPUT_DIRECTORY.path_join(EVENTS_REPORT_TEMPLATE % simulation_seed),
		[
			"event_id",
			"category",
			"trend_effect",
			"activation_count",
			"total_active_days",
			"first_activation_day",
			"last_activation_day"
		],
		rows
	)


func _save_validation_report(simulation_seed: int) -> void:
	var rows: Array[Dictionary] = []
	var error_index := 1

	for error in _validation_errors:
		rows.append({
			"seed": simulation_seed,
			"error_index": error_index,
			"error_code": error.get("error_code", "UNKNOWN"),
			"error_message": error.get("error_message", ""),
			"simulation_day": error.get("simulation_day", -1),
			"year": error.get("year", -1),
			"season": error.get("season", ""),
			"season_day": error.get("season_day", -1)
		})
		error_index += 1

	_save_csv(
		OUTPUT_DIRECTORY.path_join(VALIDATION_REPORT_TEMPLATE % simulation_seed),
		[
			"seed",
			"error_index",
			"error_code",
			"error_message",
			"simulation_day",
			"year",
			"season",
			"season_day"
		],
		rows
	)


func _print_summary(simulation_seed: int, validation_errors: Array[Dictionary]) -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	print("Full year simulation completed")
	print("Seed: ", simulation_seed)
	print("Days simulated: ", _daily_rows.size())
	print("Executed day advances: ", _executed_days)
	print("Total simulation time: %d ms" % _total_duration_msec)
	print("Slowest simulated day: %d ms" % _get_slowest_day_duration_msec())
	print("Events activated: ", _get_total_event_activations())
	print("Days without events: ", _days_without_events)
	print("Average active events: %.2f" % _get_average_active_event_count())
	print("Maximum simultaneous events: ", _max_simultaneous_events)
	print("Event activations by category: ", _event_category_activation_counts)
	print("Bullish event activations: ", _bullish_event_activations)
	print("Bearish event activations: ", _bearish_event_activations)
	print("Validation errors: ", validation_errors.size())
	print("Daily report:")
	print(output_path.path_join(DAILY_REPORT_TEMPLATE % simulation_seed))
	print("Event report:")
	print(output_path.path_join(EVENTS_REPORT_TEMPLATE % simulation_seed))
	print("Validation report:")
	print(output_path.path_join(VALIDATION_REPORT_TEMPLATE % simulation_seed))

	for product_id in _product_ids:
		var stats := _product_stats[product_id] as Dictionary
		var days := maxi(int(stats["price_days"]), 1)
		print("%s:" % _display_name_for_item_id(product_id))
		print("min price: %.2f" % float(stats["min_price"]))
		print("max price: %.2f" % float(stats["max_price"]))
		print("average price: %.2f" % (float(stats["total_price"]) / float(days)))
		print("days at max price: %d" % int(stats["max_price_days"]))
		print("max volatility: %.4f" % float(stats["max_volatility"]))

	for warning in _balance_warnings:
		print("WARNING: ", warning)

	if not validation_errors.is_empty():
		for error in validation_errors:
			push_error("%s: %s" % [error.get("error_code", "UNKNOWN"), error.get("error_message", "")])


func _assert_result(validation_errors: Array[Dictionary]) -> void:
	runner.assert_eq(validation_errors.size(), 0, "Full year simulation validation")


func _create_seed_result(simulation_seed: int, validation_errors: Array[Dictionary]) -> Dictionary:
	return {
		"seed": simulation_seed,
		"days_simulated": _daily_rows.size(),
		"first_reported_year": _get_reported_date_value(0, "year", -1),
		"first_reported_season": _get_reported_date_value(0, "season", ""),
		"first_reported_day": _get_reported_date_value(0, "season_day", -1),
		"last_reported_year": _get_reported_date_value(_daily_rows.size() - 1, "year", -1),
		"last_reported_season": _get_reported_date_value(_daily_rows.size() - 1, "season", ""),
		"last_reported_day": _get_reported_date_value(_daily_rows.size() - 1, "season_day", -1),
		"total_event_activations": _get_total_event_activations(),
		"days_without_events": _days_without_events,
		"average_active_events": _get_average_active_event_count(),
		"max_active_events": _max_simultaneous_events,
		"event_stats": _event_stats.duplicate(true),
		"product_stats": _product_stats.duplicate(true),
		"event_category_activation_counts": _event_category_activation_counts.duplicate(true),
		"bullish_event_activations": _bullish_event_activations,
		"bearish_event_activations": _bearish_event_activations,
		"validation_error_count": validation_errors.size(),
		"validation_error_codes": _get_validation_error_codes(validation_errors),
		"validation_errors": validation_errors.duplicate(),
		"balance_warnings": _balance_warnings.duplicate(),
		"fingerprint": _create_simulation_fingerprint()
	}


func _save_multi_seed_summary(all_results: Array[Dictionary]) -> void:
	var headers: Array[String] = [
		"seed",
		"days_simulated",
		"first_reported_year",
		"first_reported_season",
		"first_reported_day",
		"last_reported_year",
		"last_reported_season",
		"last_reported_day",
		"reported_day_count",
		"total_event_activations",
		"days_without_events",
		"average_active_events",
		"max_active_events",
		"heavy_rain_activations",
		"winter_shortage_activations",
		"halloween_activations",
		"spring_planting_boom_activations",
		"validation_error_count",
		"validation_error_codes",
		"balance_warning_count"
	]

	for product_id in _product_ids:
		headers.append("%s_min_price" % product_id)
		headers.append("%s_max_price" % product_id)
		headers.append("%s_average_price" % product_id)
		headers.append("%s_days_at_max_price" % product_id)
		headers.append("%s_average_volatility" % product_id)
		headers.append("%s_max_volatility" % product_id)

	var rows: Array[Dictionary] = []

	for result in all_results:
		var event_stats := result["event_stats"] as Dictionary
		var product_stats := result["product_stats"] as Dictionary
		var row: Dictionary = {
			"seed": result["seed"],
			"days_simulated": result["days_simulated"],
			"first_reported_year": result["first_reported_year"],
			"first_reported_season": result["first_reported_season"],
			"first_reported_day": result["first_reported_day"],
			"last_reported_year": result["last_reported_year"],
			"last_reported_season": result["last_reported_season"],
			"last_reported_day": result["last_reported_day"],
			"reported_day_count": result["days_simulated"],
			"total_event_activations": result["total_event_activations"],
			"days_without_events": result["days_without_events"],
			"average_active_events": "%.4f" % float(result["average_active_events"]),
			"max_active_events": result["max_active_events"],
			"heavy_rain_activations": _get_event_activation_count(event_stats, "heavy_rain"),
			"winter_shortage_activations": _get_event_activation_count(event_stats, "winter_shortage"),
			"halloween_activations": _get_event_activation_count(event_stats, "halloween_pumpkin_demand"),
			"spring_planting_boom_activations": _get_event_activation_count(event_stats, "spring_planting_boom"),
			"validation_error_count": result["validation_error_count"],
			"validation_error_codes": result["validation_error_codes"],
			"balance_warning_count": (result["balance_warnings"] as Array).size()
		}

		for product_id in _product_ids:
			var stats := product_stats[product_id] as Dictionary
			var days := maxi(int(stats["price_days"]), 1)
			row["%s_min_price" % product_id] = "%.2f" % float(stats["min_price"])
			row["%s_max_price" % product_id] = "%.2f" % float(stats["max_price"])
			row["%s_average_price" % product_id] = "%.2f" % (float(stats["total_price"]) / float(days))
			row["%s_days_at_max_price" % product_id] = int(stats["max_price_days"])
			row["%s_average_volatility" % product_id] = "%.4f" % (float(stats["total_volatility"]) / float(days))
			row["%s_max_volatility" % product_id] = "%.4f" % float(stats["max_volatility"])

		rows.append(row)

	_save_csv(OUTPUT_DIRECTORY.path_join(MULTI_SEED_SUMMARY_NAME), headers, rows)


func _save_multi_seed_aggregate(all_results: Array[Dictionary]) -> void:
	var rows: Array[Dictionary] = []
	var result_count := maxi(all_results.size(), 1)
	var event_ids := _event_stats.keys()
	event_ids.sort()

	for event_id in event_ids:
		var min_activations := INF
		var max_activations := -INF
		var total_activations := 0.0

		for result in all_results:
			var event_stats := result["event_stats"] as Dictionary
			var activations := _get_event_activation_count(event_stats, String(event_id))
			min_activations = minf(min_activations, float(activations))
			max_activations = maxf(max_activations, float(activations))
			total_activations += float(activations)

		rows.append({
			"metric": "event_activations",
			"id": event_id,
			"average": "%.4f" % (total_activations / float(result_count)),
			"minimum": int(min_activations),
			"maximum": int(max_activations)
		})

	var total_days_without_events := 0.0
	var total_average_active_events := 0.0

	for result in all_results:
		total_days_without_events += float(result["days_without_events"])
		total_average_active_events += float(result["average_active_events"])

	rows.append({
		"metric": "days_without_events",
		"id": "all_seeds",
		"average": "%.4f" % (total_days_without_events / float(result_count)),
		"minimum": "",
		"maximum": ""
	})
	rows.append({
		"metric": "average_active_events",
		"id": "all_seeds",
		"average": "%.4f" % (total_average_active_events / float(result_count)),
		"minimum": "",
		"maximum": ""
	})

	for product_id in _product_ids:
		var total_average_price := 0.0
		var total_days_at_max_price := 0.0

		for result in all_results:
			var product_stats := result["product_stats"] as Dictionary
			var stats := product_stats[product_id] as Dictionary
			var days := maxi(int(stats["price_days"]), 1)
			total_average_price += float(stats["total_price"]) / float(days)
			total_days_at_max_price += float(stats["max_price_days"])

		rows.append({
			"metric": "product_average_price",
			"id": product_id,
			"average": "%.4f" % (total_average_price / float(result_count)),
			"minimum": "",
			"maximum": ""
		})
		rows.append({
			"metric": "product_days_at_max_price",
			"id": product_id,
			"average": "%.4f" % (total_days_at_max_price / float(result_count)),
			"minimum": "",
			"maximum": ""
		})

	_save_csv(
		OUTPUT_DIRECTORY.path_join(MULTI_SEED_AGGREGATE_NAME),
		["metric", "id", "average", "minimum", "maximum"],
		rows
	)


func _validate_seed_diversity(all_results: Array[Dictionary]) -> Array[String]:
	var errors: Array[String] = []
	var fingerprint_to_seed: Dictionary = {}
	var identical_pairs := 0

	for result in all_results:
		var simulation_seed := int(result["seed"])
		var fingerprint := String(result["fingerprint"])

		if fingerprint_to_seed.has(fingerprint):
			var previous_seed := int(fingerprint_to_seed[fingerprint])
			identical_pairs += 1
			print("WARNING: Seeds %d and %d generated identical simulation output." % [previous_seed, simulation_seed])
		else:
			fingerprint_to_seed[fingerprint] = simulation_seed

	if all_results.size() > 1 and fingerprint_to_seed.size() == 1:
		errors.append("All seeds generated identical simulation output; seed is not propagated to all random generators.")

	for error in errors:
		push_error(error)

	return errors


func _print_multi_seed_summary(all_results: Array[Dictionary], diversity_errors: Array[String]) -> void:
	var completed := all_results.size()
	var failed := _get_failed_seed_count(all_results)
	var passed := completed - failed

	print("Seeds completed: %d/%d" % [completed, SIMULATION_SEEDS.size()])
	print("Seeds passed: ", passed)
	print("Seeds failed: ", failed)
	print("Total reported days: ", _get_total_reported_days(all_results))
	print("Seed diversity errors: ", diversity_errors.size())
	print("Multi-seed summary:")
	print(ProjectSettings.globalize_path(OUTPUT_DIRECTORY).path_join(MULTI_SEED_SUMMARY_NAME))
	print("Multi-seed aggregate:")
	print(ProjectSettings.globalize_path(OUTPUT_DIRECTORY).path_join(MULTI_SEED_AGGREGATE_NAME))


func _get_failed_seed_count(all_results: Array[Dictionary]) -> int:
	var failed := 0

	for result in all_results:
		if int(result["validation_error_count"]) > 0:
			failed += 1

	return failed


func _get_total_reported_days(all_results: Array[Dictionary]) -> int:
	var total := 0

	for result in all_results:
		total += int(result["days_simulated"])

	return total


func _get_event_activation_count(event_stats: Dictionary, event_id: String) -> int:
	var stats := event_stats.get(event_id, {}) as Dictionary
	return int(stats.get("activation_count", 0))


func _create_simulation_fingerprint() -> String:
	var parts: Array[String] = []

	for row in _daily_rows:
		parts.append(str(row.get("weather", "")))
		parts.append(str(row.get("started_events", "")))

		for product_id in _product_ids:
			parts.append("%.2f" % float(row.get("%s_price" % product_id, 0.0)))

	return "|".join(parts)


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

	var max_price := commodity.base_price * commodity.max_price_multiplier
	if commodity.current_price >= max_price - 0.01:
		stats["max_price_days"] = int(stats["max_price_days"]) + 1

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
		_add_validation_error(simulation_day, "MISSING_COMMODITY", "Commodity without item_data")
		return

	var product_id := commodity.item_data.id
	var price := commodity.current_price
	var volatility := commodity.volatility

	if is_nan(price) or is_inf(price):
		_add_validation_error(simulation_day, "INVALID_PRICE", "%s price is not finite" % product_id)

	if price < 0.0:
		_add_validation_error(simulation_day, "INVALID_PRICE", "%s price is negative" % product_id)

	var min_price := commodity.base_price * commodity.min_price_multiplier
	var max_price := commodity.base_price * commodity.max_price_multiplier

	if price < min_price - 0.01:
		_add_validation_error(simulation_day, "INVALID_PRICE", "%s price %.2f below min %.2f" % [product_id, price, min_price])

	if price > max_price + 0.01:
		_add_validation_error(simulation_day, "INVALID_PRICE", "%s price %.2f above max %.2f" % [product_id, price, max_price])

	if is_nan(volatility) or is_inf(volatility):
		_add_validation_error(simulation_day, "INVALID_VOLATILITY", "%s volatility is not finite" % product_id)

	if volatility < 0.0:
		_add_validation_error(simulation_day, "INVALID_VOLATILITY", "%s volatility is negative" % product_id)


func _validate_seed_price(simulation_day: int, seed_id: String, buy_price: int) -> void:
	if buy_price < 0:
		_add_validation_error(simulation_day, "INVALID_PRICE", "%s buy price is negative" % seed_id)


func _validate_reported_date_range() -> void:
	if _daily_rows.is_empty():
		_add_global_validation_error("WRONG_REPORTED_DAY_COUNT", "No reported days were collected")
		return

	var first_row := _daily_rows[0]
	var last_row := _daily_rows[_daily_rows.size() - 1]

	if int(first_row.get("year", -1)) != 1 or int(first_row.get("season_index", -1)) != int(SeasonData.Season.SPRING) or int(first_row.get("season_day", -1)) != 1:
		_add_row_validation_error(
			first_row,
			"WRONG_START_DATE",
			"First reported day must be Year 1 Spring 1"
		)

	if int(last_row.get("year", -1)) != 1 or int(last_row.get("season_index", -1)) != int(SeasonData.Season.WINTER) or int(last_row.get("season_day", -1)) != TimeManager.DAYS_PER_MONTH:
		_add_row_validation_error(
			last_row,
			"WRONG_END_DATE",
			"Last reported day must be Year 1 Winter 30"
		)

	var seen_dates := {}
	var season_counts := {
		int(SeasonData.Season.SPRING): 0,
		int(SeasonData.Season.SUMMER): 0,
		int(SeasonData.Season.AUTUMN): 0,
		int(SeasonData.Season.WINTER): 0
	}
	var previous_day_index := 0

	for row in _daily_rows:
		var year := int(row.get("year", -1))
		var season_index := int(row.get("season_index", -1))
		var season_day := int(row.get("season_day", -1))
		var simulation_day := int(row.get("simulation_day", -1))

		if year != 1:
			_add_row_validation_error(row, "DATE_OUTSIDE_YEAR", "Reported day belongs to year %d" % year)

		var date_key := "%d:%d:%d" % [year, season_index, season_day]
		if seen_dates.has(date_key):
			_add_row_validation_error(row, "DUPLICATE_DATE", "Duplicate reported date %s" % date_key)
		seen_dates[date_key] = true

		if season_counts.has(season_index):
			season_counts[season_index] = int(season_counts[season_index]) + 1

		var day_index := _get_day_of_year_index(season_index, season_day)
		if day_index < 1 or day_index > DAYS_IN_YEAR:
			_add_row_validation_error(row, "INVALID_DATE_INDEX", "Invalid day-of-year index %d" % day_index)

		if simulation_day != day_index:
			_add_row_validation_error(
				row,
				"CALENDAR_GAP",
				"Simulation day %d does not match calendar index %d" % [simulation_day, day_index]
			)

		if previous_day_index > 0 and day_index != previous_day_index + 1:
			_add_row_validation_error(
				row,
				"CALENDAR_GAP",
				"Calendar index jumped from %d to %d" % [previous_day_index, day_index]
			)

		previous_day_index = day_index

	for season_index in season_counts.keys():
		if int(season_counts[season_index]) != TimeManager.DAYS_PER_MONTH:
			_add_global_validation_error(
				"WRONG_SEASON_DAY_COUNT",
				"Season %d expected %d records, got %d" % [
					int(season_index),
					TimeManager.DAYS_PER_MONTH,
					int(season_counts[season_index])
				]
			)


func _validate_active_events(simulation_day: int) -> void:
	var seen_ids := {}

	for active_event in EventManager.get_active_market_events():
		if active_event == null:
			_add_validation_error(simulation_day, "EVENT_DURATION_INVALID", "Null active event")
			continue

		if active_event.event_data == null:
			_add_validation_error(simulation_day, "EVENT_DURATION_INVALID", "Active event without event_data")
			continue

		var event_id := active_event.event_data.event_id

		if seen_ids.has(event_id):
			_add_validation_error(simulation_day, "DUPLICATE_ACTIVE_EVENT", "Duplicate active event %s" % event_id)

		seen_ids[event_id] = true

		if active_event.remaining_days < 0:
			_add_validation_error(simulation_day, "EVENT_DURATION_INVALID", "%s has negative remaining_days" % event_id)

		if active_event.remaining_days > active_event.event_data.duration_days:
			_add_validation_error(simulation_day, "EVENT_DURATION_INVALID", "%s remaining_days exceeds declared duration" % event_id)

	if EventManager.get_active_market_events().size() > 8:
		_add_validation_error(simulation_day, "EVENT_DURATION_INVALID", "Too many simultaneous active events")


func _validate_daily_event_rules(simulation_day: int) -> void:
	for event_id in _started_today:
		var event_data := EventManager.get_event_by_id(event_id)
		if event_data == null:
			continue

		if event_data.requires_season and not event_data.required_seasons.has(TimeManager.get_current_season()):
			_add_validation_error(simulation_day, "EVENT_OUTSIDE_SEASON", "%s started outside required season" % event_id)

		if event_data.requires_day_range:
			if TimeManager.current_day < event_data.start_day or TimeManager.current_day > event_data.end_day:
				_add_validation_error(simulation_day, "EVENT_OUTSIDE_DATE_RANGE", "%s started outside day range" % event_id)

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
				_add_validation_error(simulation_day, "DUPLICATE_FIXED_EVENT", "%s started more than once on %s" % [event_id, day_key])


func _validate_activation_spacing(simulation_day: int, event_id: String) -> void:
	var event_data := EventManager.get_event_by_id(event_id)
	if event_data == null:
		return

	if event_data.cooldown_days > 0 and _last_activation_day_by_event.has(event_id):
		var previous_day := int(_last_activation_day_by_event[event_id])
		var minimum_gap := event_data.duration_days + event_data.cooldown_days

		if simulation_day - previous_day < minimum_gap:
			_add_validation_error(
				simulation_day,
				"COOLDOWN_INVALID",
				"%s restarted before cooldown elapsed" % event_id
			)

	_last_activation_day_by_event[event_id] = simulation_day

	if event_data.once_per_season:
		var season_key := "%s:%d:%d" % [
			event_id,
			TimeManager.current_year,
			int(TimeManager.get_current_season())
		]

		if _once_per_season_activation_keys.has(season_key):
			_add_validation_error(
				simulation_day,
				"ONCE_PER_SEASON_INVALID",
				"%s started more than once in the same season" % event_id
			)

		_once_per_season_activation_keys[season_key] = true


func _validate_required_event_outcomes() -> void:
	var halloween := _event_stats.get("halloween_pumpkin_demand", {}) as Dictionary
	var halloween_count := int(halloween.get("activation_count", 0))

	if halloween_count != 1:
		_add_global_validation_error("WRONG_EVENT_COUNT", "Halloween expected exactly 1 activation, got %d" % halloween_count)

	var spring := _event_stats.get("spring_planting_boom", {}) as Dictionary
	var spring_count := int(spring.get("activation_count", 0))

	if spring_count != 1:
		_add_global_validation_error("WRONG_EVENT_COUNT", "Spring Planting Boom expected exactly 1 activation, got %d" % spring_count)

	if spring_count == 1:
		var first_day := int(spring.get("first_activation_day", 0))
		if first_day < 1 or first_day > 7:
			_add_global_validation_error("EVENT_OUTSIDE_DATE_RANGE", "Spring Planting Boom started outside expected simulation day range 1-7")

	var autumn := _event_stats.get("autumn_harvest_festival", {}) as Dictionary
	var autumn_count := int(autumn.get("activation_count", 0))
	if autumn_count != 1:
		_add_global_validation_error("WRONG_EVENT_COUNT", "Autumn Harvest Festival expected exactly 1 activation, got %d" % autumn_count)

	var winter_shortage := _event_stats.get("winter_shortage", {}) as Dictionary
	var winter_shortage_count := int(winter_shortage.get("activation_count", 0))
	if winter_shortage_count > 1:
		_add_global_validation_error("ONCE_PER_SEASON_INVALID", "Winter Shortage expected at most 1 activation, got %d" % winter_shortage_count)


func _validate_seed_modifiers_cleared() -> void:
	for seed_id in _seed_ids:
		var seed_item := SaveManager._get_item_by_id(seed_id)
		var current_price := EconomyManager.get_buy_price(seed_item)
		var base_price := int(_base_seed_prices.get(seed_id, current_price))

		if current_price != base_price:
			_add_global_validation_error("SEED_PRICE_NOT_RESET", "%s buy price did not return to base after events" % seed_id)

	if not EconomyManager.buy_price_multipliers_by_item_id.is_empty():
		_add_global_validation_error("SEED_PRICE_NOT_RESET", "Runtime buy price modifiers remain active after simulation")


func _validate_news_count() -> void:
	if NewsManager.news_items.size() > NewsManager.MAX_NEWS_COUNT:
		_add_global_validation_error("NEWS_COUNT_INVALID", "News count exceeded MAX_NEWS_COUNT")


func _validate_volatility_reset_state() -> void:
	for commodity in CommodityMarketManager.commodities:
		if commodity == null or commodity.item_data == null:
			continue

		if _is_product_modified_by_active_event(commodity.item_data.id):
			continue

		var base_volatility := float(_base_volatility_by_product.get(commodity.item_data.id, commodity.volatility))
		if absf(commodity.volatility - base_volatility) > 0.0001:
			_add_global_validation_error("INVALID_VOLATILITY", "%s volatility did not return to base without active event" % commodity.item_data.id)


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
		_add_global_validation_error("CSV_WRITE_FAILED", "Could not create report directory: %s" % absolute_directory)
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_add_global_validation_error("CSV_WRITE_FAILED", "Could not open CSV for writing: %s error=%d" % [path, FileAccess.get_open_error()])
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
		"last_activation_day": 0,
		"category": "unknown",
		"trend_effect": "unknown"
	}

	var event_data := EventManager.get_event_by_id(event_id)
	if event_data != null:
		var stats := _event_stats[event_id] as Dictionary
		stats["category"] = _event_category_to_string(event_data.event_category)
		stats["trend_effect"] = _trend_to_string(event_data.trend_effect)


func _get_total_event_activations() -> int:
	var total := 0

	for event_id in _event_stats.keys():
		var stats := _event_stats[event_id] as Dictionary
		total += int(stats["activation_count"])

	return total


func _get_average_active_event_count() -> float:
	if _daily_rows.is_empty():
		return 0.0

	return float(_total_active_event_count) / float(_daily_rows.size())


func _collect_event_activation_balance_stats(event_id: String) -> void:
	var event_data := EventManager.get_event_by_id(event_id)
	if event_data == null:
		return

	var category := _event_category_to_string(event_data.event_category)
	_event_category_activation_counts[category] = int(_event_category_activation_counts.get(category, 0)) + 1

	match event_data.trend_effect:
		CommodityData.MarketTrend.BULLISH:
			_bullish_event_activations += 1
		CommodityData.MarketTrend.BEARISH:
			_bearish_event_activations += 1
		CommodityData.MarketTrend.NEUTRAL:
			pass


func _collect_balance_warnings() -> void:
	_balance_warnings.clear()

	var heavy_rain := _event_stats.get("heavy_rain", {}) as Dictionary
	if int(heavy_rain.get("activation_count", 0)) > 10:
		_balance_warnings.append("Heavy Rain activated more than 10 times.")

	for product_id in _product_ids:
		var stats := _product_stats[product_id] as Dictionary
		if int(stats.get("max_price_days", 0)) > DAYS_IN_YEAR / 4:
			_balance_warnings.append("%s remained at max price for more than 25%% of the year." % product_id)

	if _days_without_events < int(ceil(float(DAYS_IN_YEAR) * 0.1)):
		_balance_warnings.append("Less than 10%% of simulated days had no active events.")


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


func _event_category_to_string(category: MarketEventData.EventCategory) -> String:
	match category:
		MarketEventData.EventCategory.MARKET:
			return "market"
		MarketEventData.EventCategory.WEATHER:
			return "weather"
		MarketEventData.EventCategory.SEASONAL:
			return "seasonal"
		_:
			return "unknown"


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


func _add_validation_error(simulation_day: int, error_code: String, message: String) -> void:
	var row := _get_daily_row_by_simulation_day(simulation_day)

	if row.is_empty():
		_validation_errors.append(_create_validation_error(error_code, message, simulation_day, -1, "", -1))
		return

	_add_row_validation_error(row, error_code, message)


func _add_row_validation_error(row: Dictionary, error_code: String, message: String) -> void:
	_validation_errors.append(_create_validation_error(
		error_code,
		message,
		int(row.get("simulation_day", -1)),
		int(row.get("year", -1)),
		String(row.get("season", "")),
		int(row.get("season_day", -1))
	))


func _add_global_validation_error(error_code: String, message: String) -> void:
	_validation_errors.append(_create_validation_error(error_code, message, -1, -1, "", -1))


func _create_validation_error(
	error_code: String,
	message: String,
	simulation_day: int,
	year: int,
	season: String,
	season_day: int
) -> Dictionary:
	return {
		"error_code": error_code,
		"error_message": message,
		"simulation_day": simulation_day,
		"year": year,
		"season": season,
		"season_day": season_day
	}


func _get_daily_row_by_simulation_day(simulation_day: int) -> Dictionary:
	for row in _daily_rows:
		if int(row.get("simulation_day", -1)) == simulation_day:
			return row

	return {}


func _get_day_of_year_index(season_index: int, season_day: int) -> int:
	return season_index * TimeManager.DAYS_PER_MONTH + season_day


func _get_reported_date_value(row_index: int, key: String, default_value):
	if row_index < 0 or row_index >= _daily_rows.size():
		return default_value

	return _daily_rows[row_index].get(key, default_value)


func _get_validation_error_codes(validation_errors: Array[Dictionary]) -> String:
	var codes: Array[String] = []

	for error in validation_errors:
		var code := String(error.get("error_code", "UNKNOWN"))
		if not codes.has(code):
			codes.append(code)

	codes.sort()
	return "|".join(codes)


func _on_market_event_started(event_data: MarketEventData) -> void:
	if event_data == null:
		return

	_started_today.append(event_data.event_id)


func _on_market_event_ended(event_data: MarketEventData) -> void:
	if event_data == null:
		return

	_ended_today.append(event_data.event_id)
