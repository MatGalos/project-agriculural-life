extends RefCounted

var runner: TestRunner

const SALES_SIMULATION_SEED: int = 918273
const OUTPUT_DIRECTORY: String = "user://simulation_reports/oversupply/"
const DETAIL_REPORT_PATH: String = "user://simulation_reports/oversupply/oversupply_sales_simulation.csv"
const SUMMARY_REPORT_PATH: String = "user://simulation_reports/oversupply/oversupply_sales_summary.csv"
const THRESHOLD_REPORT_PATH: String = "user://simulation_reports/oversupply/oversupply_threshold_analysis.csv"
const MASS_SIMULATION_DAYS: int = 30
const EMPTY_CELL: String = ""

var _results: Array[Dictionary] = []
var _threshold_rows: Array[Dictionary] = []
var _validation_errors: Array[String] = []
var _warnings: Array[String] = []
var _activation_counts: Dictionary = {}
var _first_trigger_day_by_event: Dictionary = {}
var _last_trigger_day_by_event: Dictionary = {}
var _active_days_by_event: Dictionary = {}
var _previous_commodity_logs_suppressed := false
var _previous_event_logs_suppressed := false
var _previous_weather_logs_suppressed := false
var _saved_possible_market_events: Array[MarketEventData] = []


func run() -> void:
	print("\n--- OversupplySalesSimulationTest ---")
	test_oversupply_sales_simulation()


func test_oversupply_sales_simulation() -> void:
	_prepare_test()

	for product in _get_test_products():
		_validate_oversupply_resource_balance(product)
		_run_product_scenarios(product)

	_run_isolation_scenario()
	_run_save_load_scenario(_get_product_by_id("wheat"))
	_assert_report_integrity()
	_save_reports()
	_print_summary()
	_restore_production_logs()

	runner.assert_eq(_validation_errors.size(), 0, "Oversupply sales simulation validation")


func _prepare_test() -> void:
	_results.clear()
	_threshold_rows.clear()
	_validation_errors.clear()
	_warnings.clear()
	_saved_possible_market_events = EventManager.possible_market_events.duplicate()
	_suppress_production_logs()


func _get_test_products() -> Array[Dictionary]:
	_restore_possible_market_events()
	var products: Array[Dictionary] = []

	for commodity in CommodityMarketManager.commodities:
		if commodity == null or commodity.item_data == null:
			continue

		var event_data := EventManager.get_event_by_id("%s_oversupply" % commodity.item_data.id)
		if event_data == null:
			_add_error("MISSING_EVENT", "Missing oversupply event for %s" % commodity.item_data.id)
			continue

		products.append({
			"product_id": commodity.item_data.id,
			"item": commodity.item_data,
			"event": event_data,
			"commodity": commodity
		})

	products.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["product_id"]) < String(b["product_id"])
	)
	return products


func _get_product_by_id(product_id: String) -> Dictionary:
	for product in _get_test_products():
		if String(product["product_id"]) == product_id:
			return product

	return {}


func _run_product_scenarios(product: Dictionary) -> void:
	_run_no_sales_scenario(product)
	_run_below_threshold_scenario(product)
	_run_exact_threshold_scenario(product)
	_run_above_threshold_scenario(product)
	_run_distributed_sales_scenario(product)
	_run_small_regular_sales_scenario(product)
	_run_mass_sales_scenario(product)
	_collect_threshold_analysis(product)


func _validate_oversupply_resource_balance(product: Dictionary) -> void:
	var product_id := String(product["product_id"])
	var event_data := product["event"] as MarketEventData
	var crop := SaveManager._get_crop_by_id(product_id)

	if crop == null:
		_add_error("MISSING_CROP", "Missing crop data for %s" % product_id)
		return

	var yield_per_crop := maxi(crop.harvest_amount, 1)
	var expected_threshold := yield_per_crop * 200

	if event_data.recent_sales_threshold != expected_threshold:
		_add_error(
			"OVERSUPPLY_RESOURCE_BALANCE_INVALID",
			"%s threshold expected %d from yield %d, got %d" % [
				product_id,
				expected_threshold,
				yield_per_crop,
				event_data.recent_sales_threshold
			]
		)

	if event_data.cooldown_days != 5:
		_add_error(
			"OVERSUPPLY_RESOURCE_BALANCE_INVALID",
			"%s cooldown expected 5, got %d" % [product_id, event_data.cooldown_days]
		)


func _run_no_sales_scenario(product: Dictionary) -> void:
	_reset_state()
	var event_data := product["event"] as MarketEventData
	var item := product["item"] as ItemData
	_limit_possible_events([event_data])
	var result := _base_result(product, "no_sales")

	for day in range(1, event_data.recent_sales_days + 1):
		_track_condition(result, event_data, item, day)
		_advance_day()

	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	result["condition_met"] = result["condition_ever_met"]
	result["event_triggered"] = _count_active_event(event_data.event_id) > 0
	_fill_market_result(result)

	if bool(result["condition_ever_met"]):
		_fail_result(result, "OVERSUPPLY_VALIDATION", "Oversupply condition met without sales")
	if bool(result["event_triggered"]):
		_fail_result(result, "OVERSUPPLY_VALIDATION", "Oversupply activated without sales")

	_results.append(result)


func _run_below_threshold_scenario(product: Dictionary) -> void:
	_reset_state()
	var event_data := product["event"] as MarketEventData
	var item := product["item"] as ItemData
	_limit_possible_events([event_data])
	var amount := maxi(event_data.recent_sales_threshold - 1, 0)
	var result := _base_result(product, "below_threshold")

	_record_sales_for_day(item, amount)
	_track_condition(result, event_data, item, 1)

	result["total_sold"] = amount
	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	result["condition_met"] = result["condition_ever_met"]
	result["event_triggered"] = _count_active_event(event_data.event_id) > 0
	result["recent_sales_total"] = SalesStatsManager.get_recent_sales_amount(item.id, event_data.recent_sales_days)
	_fill_market_result(result)

	if int(result["recent_sales_total"]) != amount:
		_fail_result(result, "SALES_WINDOW_WRONG", "Recent sales total below threshold is wrong")
	if bool(result["condition_ever_met"]):
		_fail_result(result, "OVERSUPPLY_VALIDATION", "Oversupply condition met below threshold")
	if bool(result["event_triggered"]):
		_fail_result(result, "OVERSUPPLY_VALIDATION", "Oversupply activated below threshold")

	_results.append(result)


func _run_exact_threshold_scenario(product: Dictionary) -> void:
	_reset_state()
	var event_data := product["event"] as MarketEventData
	var item := product["item"] as ItemData
	_limit_possible_events([event_data])
	var result := _base_result(product, "exact_threshold")

	_apply_snapshot(result, "before_event", _capture_market_snapshot(item.id, event_data.event_id))
	_record_sales_for_day(item, event_data.recent_sales_threshold)
	_track_condition(result, event_data, item, 1)

	result["total_sold"] = event_data.recent_sales_threshold
	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	result["condition_met"] = result["condition_ever_met"]
	result["recent_sales_total"] = SalesStatsManager.get_recent_sales_amount(item.id, event_data.recent_sales_days)

	if not bool(result["condition_ever_met"]):
		_fail_result(result, "SALES_WINDOW_WRONG", "Oversupply condition is not met at exact >= threshold")

	result["event_triggered"] = _trigger_and_record_event(event_data.event_id, 1)
	EventManager._apply_market_event_effects()
	_apply_snapshot(result, "immediately_after_trigger", _capture_market_snapshot(item.id, event_data.event_id))
	_validate_active_snapshot(result, event_data, "immediately_after_trigger")
	_fill_market_result(result)
	_results.append(result)


func _run_above_threshold_scenario(product: Dictionary) -> void:
	_reset_state()
	var event_data := product["event"] as MarketEventData
	var item := product["item"] as ItemData
	_limit_possible_events([event_data])
	var amount := int(ceil(float(event_data.recent_sales_threshold) * 1.5))
	var result := _base_result(product, "above_threshold")

	_apply_snapshot(result, "before_event", _capture_market_snapshot(item.id, event_data.event_id))
	_record_sales_for_day(item, amount)
	_track_condition(result, event_data, item, 1)

	result["total_sold"] = amount
	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	result["condition_met"] = result["condition_ever_met"]

	if not bool(result["condition_ever_met"]):
		_fail_result(result, "SALES_WINDOW_WRONG", "Oversupply condition is not met above threshold")

	result["event_triggered"] = _trigger_and_record_event(event_data.event_id, 1)
	EventManager._apply_market_event_effects()
	_apply_snapshot(result, "immediately_after_trigger", _capture_market_snapshot(item.id, event_data.event_id))
	_validate_active_snapshot(result, event_data, "immediately_after_trigger")

	CommodityMarketManager.update_market_for_test_day(_absolute_day(), CommodityMarketManager.MARKET_CLOSE_HOUR)
	_apply_snapshot(result, "after_market_update", _capture_market_snapshot(item.id, event_data.event_id))
	_collect_valid_price_sample(result, float(result["after_market_update_current_price"]))

	EventManager._apply_market_event_effects()
	_apply_snapshot(result, "after_reapply", _capture_market_snapshot(item.id, event_data.event_id))
	_validate_reapply_snapshot(result)

	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()
	_advance_through_event_duration(result, event_data, item)
	_apply_snapshot(result, "after_event_end", _capture_market_snapshot(item.id, event_data.event_id))
	_validate_end_snapshot(result)

	_observe_recovery(result, event_data, item)
	_fill_market_result(result)
	_validate_price_fields(result)
	_results.append(result)


func _run_distributed_sales_scenario(product: Dictionary) -> void:
	_reset_state()
	var event_data := product["event"] as MarketEventData
	var item := product["item"] as ItemData
	_limit_possible_events([event_data])
	var total := 0
	var result := _base_result(product, "distributed_sales")

	for day in range(1, 6):
		_record_sales_for_day(item, 200)
		total += 200
		_track_condition(result, event_data, item, day)
		if day < 5:
			_advance_day()

	result["total_sold"] = total
	result["recent_sales_total"] = SalesStatsManager.get_recent_sales_amount(item.id, event_data.recent_sales_days)
	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	result["condition_met"] = result["condition_ever_met"]

	if int(result["recent_sales_total"]) != total:
		_fail_result(result, "SALES_WINDOW_WRONG", "Distributed sales sum is wrong")
	if not bool(result["condition_ever_met"]):
		_fail_result(result, "SALES_WINDOW_WRONG", "Distributed sales did not meet threshold on day 5")

	for _day in range(event_data.recent_sales_days):
		_advance_day()

	result["recent_sales_after_window"] = SalesStatsManager.get_recent_sales_amount(item.id, event_data.recent_sales_days)
	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	if int(result["recent_sales_after_window"]) != 0:
		_fail_result(result, "SALES_WINDOW_WRONG", "Sales older than recent_sales_days are still counted")
	if not bool(result["condition_ever_met"]):
		_fail_result(result, "SALES_WINDOW_WRONG", "condition_ever_met was reset after sales left the window")

	_fill_market_result(result)
	_results.append(result)


func _run_small_regular_sales_scenario(product: Dictionary) -> void:
	_reset_state()
	var event_data := product["event"] as MarketEventData
	var item := product["item"] as ItemData
	_limit_possible_events([event_data])
	var daily_amount := maxi(int(floor(float(event_data.recent_sales_threshold - 1) / float(event_data.recent_sales_days))), 1)
	var total := 0
	var result := _base_result(product, "small_regular_sales")

	for day in range(1, MASS_SIMULATION_DAYS + 1):
		_record_sales_for_day(item, daily_amount)
		total += daily_amount
		_track_condition(result, event_data, item, day)
		_advance_day()

	result["total_sold"] = total
	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	result["condition_met"] = result["condition_ever_met"]
	result["event_triggered"] = _get_activation_count(event_data.event_id) > 0
	_fill_market_result(result)

	if bool(result["event_triggered"]):
		_fail_result(result, "OVERSUPPLY_VALIDATION", "Small regular sales triggered Oversupply")
		_warn("Small regular sales triggered Oversupply for %s" % item.id)

	_results.append(result)


func _run_mass_sales_scenario(product: Dictionary) -> void:
	_reset_state()
	var event_data := product["event"] as MarketEventData
	var item := product["item"] as ItemData
	_limit_possible_events([event_data])
	var daily_amount := event_data.recent_sales_threshold
	var total := 0
	var days_at_min := 0
	var recovery_days := -1
	var result := _base_result(product, "mass_regular_sales")

	_apply_snapshot(result, "before_event", _capture_market_snapshot(item.id, event_data.event_id))

	for day in range(1, MASS_SIMULATION_DAYS + 1):
		_record_sales_for_day(item, daily_amount)
		total += daily_amount
		_track_condition(result, event_data, item, day)

		if EventManager._does_event_meet_requirements(event_data) and _count_active_event(event_data.event_id) == 0:
			if _trigger_and_record_event(event_data.event_id, day):
				result["event_triggered"] = true
				_apply_snapshot(result, "immediately_after_trigger", _capture_market_snapshot(item.id, event_data.event_id))

		EventManager._apply_market_event_effects()
		CommodityMarketManager.update_market_for_test_day(_absolute_day(), CommodityMarketManager.MARKET_CLOSE_HOUR)
		var snapshot := _capture_market_snapshot(item.id, event_data.event_id)
		_collect_valid_price_sample(result, float(snapshot["current_price"]))
		if bool(snapshot["event_active"]):
			result["event_active_days"] = int(result.get("event_active_days", 0)) + 1
		if _is_price_at_min(snapshot):
			days_at_min += 1
		_advance_day()

	result["total_sold"] = total
	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	result["condition_met"] = result["condition_ever_met"]
	result["days_at_min_price"] = days_at_min
	result["price_at_end"] = _get_current_price_for_item(item.id)
	result["price_after_sales_end"] = result["price_at_end"]

	var stopped_price := float(result["price_at_end"])
	for day in range(1, 8):
		_advance_day()
		var recovery_snapshot := _capture_market_snapshot(item.id, event_data.event_id)
		_collect_valid_price_sample(result, float(recovery_snapshot["current_price"]))
		if recovery_days < 0 and float(recovery_snapshot["current_price"]) > stopped_price + 0.01:
			recovery_days = day
		if day == 3:
			_apply_snapshot(result, "three_days_after", recovery_snapshot)
		if day == 7:
			_apply_snapshot(result, "seven_days_after", recovery_snapshot)

	result["recovery_days"] = recovery_days
	_fill_market_result(result)

	if not bool(result["event_triggered"]):
		_fail_result(result, "EVENT_NOT_ACTIVE_AFTER_TRIGGER", "Mass sales did not trigger Oversupply")
		_warn("Mass sales did not trigger any Oversupply for %s" % item.id)
	if int(result["activation_count"]) > 3:
		_warn("Oversupply activated more than 3 times in 30 days for %s" % item.id)
	if days_at_min > 7:
		_warn("Price stayed at min_price for more than 7 days for %s" % item.id)
	if recovery_days < 0:
		_warn("Price did not show recovery within 7 days for %s" % item.id)

	_validate_price_fields(result)
	_results.append(result)


func _run_isolation_scenario() -> void:
	var product_ids := ["wheat", "tomatoe"]

	for source_id in product_ids:
		_reset_state()
		var source := _get_product_by_id(source_id)
		var source_event := source["event"] as MarketEventData
		var source_item := source["item"] as ItemData
		var control_id := "carrot" if source_id != "carrot" else "wheat"
		var control := _get_product_by_id(control_id)
		var control_event := control["event"] as MarketEventData
		_limit_possible_events([source_event, control_event])
		var result := _base_result(source, "product_isolation_%s" % source_id)

		_record_sales_for_day(source_item, source_event.recent_sales_threshold + 500)
		_track_condition(result, source_event, source_item, 1)

		result["total_sold"] = source_event.recent_sales_threshold + 500
		result["condition_met_at_end"] = EventManager._does_event_meet_requirements(source_event)
		result["condition_met"] = result["condition_ever_met"]
		result["control_condition_met"] = EventManager._does_event_meet_requirements(control_event)
		result["event_triggered"] = _trigger_and_record_event(source_event.event_id, 1)
		EventManager._apply_market_event_effects()
		_apply_snapshot(result, "immediately_after_trigger", _capture_market_snapshot(source_item.id, source_event.event_id))
		_fill_market_result(result)

		var control_snapshot := _capture_market_snapshot(control_id, control_event.event_id)
		if not bool(result["condition_ever_met"]):
			_fail_result(result, "SALES_WINDOW_WRONG", "%s Oversupply condition was not met" % source_id)
		if bool(result["control_condition_met"]):
			_fail_result(result, "WRONG_PRODUCT_EVENT", "%s sales met %s condition" % [source_id, control_id])
		if int(control_snapshot["current_trend"]) == int(CommodityData.MarketTrend.BEARISH):
			_fail_result(result, "WRONG_PRODUCT_EVENT", "%s Oversupply modified %s commodity" % [source_id, control_id])

		_results.append(result)


func _run_save_load_scenario(product: Dictionary) -> void:
	if product.is_empty():
		_add_error("SAVE_LOAD_FAILED", "Wheat product is missing")
		return

	_reset_state()
	var event_data := product["event"] as MarketEventData
	var item := product["item"] as ItemData
	_limit_possible_events([event_data])
	var result := _base_result(product, "save_load")

	_apply_snapshot(result, "before_event", _capture_market_snapshot(item.id, event_data.event_id))
	_record_sales_for_day(item, 300)
	_advance_day()
	_record_sales_for_day(item, 400)
	_advance_day()
	_record_sales_for_day(item, 500)
	_track_condition(result, event_data, item, 3)

	var current_sales_before := int(SalesStatsManager.current_day_sales.get(item.id, 0))
	var recent_before := SalesStatsManager.get_recent_sales_amount(item.id, event_data.recent_sales_days)
	var triggered := _trigger_and_record_event(event_data.event_id, 3)
	EventManager._apply_market_event_effects()
	var after_trigger := _capture_market_snapshot(item.id, event_data.event_id)
	var remaining_before := int(after_trigger["remaining_days"])
	var volatility_after_trigger := float(after_trigger["volatility"])
	var news_count_before := NewsManager.news_items.size()
	var activation_count_before := _get_activation_count(event_data.event_id)
	var first_trigger_day_before := int(_first_trigger_day_by_event.get(event_data.event_id, 0))
	var last_trigger_day_before := int(_last_trigger_day_by_event.get(event_data.event_id, 0))
	var save_data := SaveManager._create_save_data()

	_reset_state()
	SaveManager._apply_save_data(save_data)
	_restore_test_activation_metrics(
		event_data.event_id,
		activation_count_before,
		first_trigger_day_before,
		last_trigger_day_before
	)

	result["total_sold"] = recent_before
	result["condition_met_at_end"] = EventManager._does_event_meet_requirements(event_data)
	result["condition_met"] = result["condition_ever_met"]
	result["event_triggered"] = triggered
	result["current_day_sales_restored"] = int(SalesStatsManager.current_day_sales.get(item.id, 0))
	result["recent_sales_total"] = SalesStatsManager.get_recent_sales_amount(item.id, event_data.recent_sales_days)
	result["remaining_days_restored"] = _get_active_remaining_days(event_data.event_id)
	result["news_before_load"] = news_count_before
	result["news_after_load"] = NewsManager.news_items.size()
	_apply_snapshot(result, "immediately_after_trigger", _capture_market_snapshot(item.id, event_data.event_id))
	_fill_market_result(result)

	if int(result["current_day_sales_restored"]) != current_sales_before:
		_fail_result(result, "SAVE_LOAD_FAILED", "Save/load lost current_day_sales")
	if int(result["recent_sales_total"]) != recent_before:
		_fail_result(result, "SAVE_LOAD_FAILED", "Save/load lost sales history")
	if int(result["remaining_days_restored"]) != remaining_before:
		_fail_result(result, "SAVE_LOAD_FAILED", "Save/load lost active event remaining_days")
	if absf(float(result["volatility_after_trigger"]) - volatility_after_trigger) > 0.0001:
		_fail_result(result, "SAVE_LOAD_FAILED", "Save/load duplicated or lost volatility modifier")
	if int(result["news_after_load"]) != news_count_before:
		_fail_result(result, "SAVE_LOAD_FAILED", "Save/load duplicated active event news")
	if not _snapshot_is_bearish(result, "immediately_after_trigger"):
		_fail_result(result, "SAVE_LOAD_FAILED", "Save/load did not reapply bearish modifier")

	_results.append(result)


func _reset_state() -> void:
	seed(SALES_SIMULATION_SEED)
	_activation_counts.clear()
	_first_trigger_day_by_event.clear()
	_last_trigger_day_by_event.clear()
	_active_days_by_event.clear()

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

	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()
	NewsManager.clear_news()
	EconomyManager.reset_buy_price_modifiers()
	CommodityMarketManager.last_processed_day = -1
	CommodityMarketManager.last_processed_hour = -1
	CommodityMarketManager.reset_event_modifiers()
	_reset_commodity_runtime_values()
	EventManager._apply_market_event_effects()


func _record_sales_for_day(item_data: ItemData, amount: int) -> void:
	SalesStatsManager.record_sale(item_data, amount)


func _advance_day() -> void:
	TimeManager.advance_day_for_test()
	_record_active_event_days()


func _trigger_and_record_event(event_id: String, simulation_day: int) -> bool:
	var was_active := _count_active_event(event_id) > 0
	var started := EventManager.trigger_event_by_id(event_id)
	var is_active := _count_active_event(event_id) > 0

	if started and is_active and not was_active:
		_record_activation(event_id, simulation_day)
		return true

	return false


func _record_activation(event_id: String, simulation_day: int) -> void:
	_activation_counts[event_id] = int(_activation_counts.get(event_id, 0)) + 1
	if not _first_trigger_day_by_event.has(event_id):
		_first_trigger_day_by_event[event_id] = simulation_day
	_last_trigger_day_by_event[event_id] = simulation_day


func _restore_test_activation_metrics(
	event_id: String,
	activation_count: int,
	first_trigger_day: int,
	last_trigger_day: int
) -> void:
	if activation_count > 0:
		_activation_counts[event_id] = activation_count
	if first_trigger_day > 0:
		_first_trigger_day_by_event[event_id] = first_trigger_day
	if last_trigger_day > 0:
		_last_trigger_day_by_event[event_id] = last_trigger_day


func _record_active_event_days() -> void:
	for active_event in EventManager.get_active_market_events():
		if active_event == null or active_event.event_data == null:
			continue
		var event_id := active_event.event_data.event_id
		_active_days_by_event[event_id] = int(_active_days_by_event.get(event_id, 0)) + 1


func _capture_market_snapshot(product_id: String, event_id: String) -> Dictionary:
	var commodity := _get_commodity_by_product_id(product_id)
	if commodity == null:
		return {
			"product_id": product_id,
			"has_market_snapshot": false,
			"current_price": NAN,
			"current_trend": int(CommodityData.MarketTrend.NEUTRAL),
			"trend_name": "missing",
			"trend_strength_modifier": 0.0,
			"directional_modifier": 0.0,
			"volatility": NAN,
			"event_active": false,
			"remaining_days": 0
		}

	var directional_modifier := float(CommodityMarketManager._event_direction_by_item_id.get(product_id, 0.0))
	var trend_strength_modifier := float(CommodityMarketManager._event_trend_strength_by_item_id.get(product_id, 0.0))
	return {
		"product_id": product_id,
		"has_market_snapshot": true,
		"current_price": commodity.current_price,
		"current_trend": int(commodity.trend),
		"trend_name": _trend_to_string(commodity.trend),
		"trend_strength_modifier": trend_strength_modifier,
		"directional_modifier": directional_modifier,
		"volatility": commodity.volatility,
		"event_active": _count_active_event(event_id) > 0,
		"remaining_days": _get_active_remaining_days(event_id)
	}


func _apply_snapshot(result: Dictionary, prefix: String, snapshot: Dictionary) -> void:
	result["%s_has_market_snapshot" % prefix] = bool(snapshot.get("has_market_snapshot", false))
	result["%s_current_price" % prefix] = snapshot.get("current_price", EMPTY_CELL)
	result["%s_current_trend" % prefix] = snapshot.get("current_trend", EMPTY_CELL)
	result["%s_trend_name" % prefix] = snapshot.get("trend_name", EMPTY_CELL)
	result["%s_trend_strength_modifier" % prefix] = snapshot.get("trend_strength_modifier", EMPTY_CELL)
	result["%s_directional_modifier" % prefix] = snapshot.get("directional_modifier", EMPTY_CELL)
	result["%s_volatility" % prefix] = snapshot.get("volatility", EMPTY_CELL)
	result["%s_event_active" % prefix] = snapshot.get("event_active", false)
	result["%s_remaining_days" % prefix] = snapshot.get("remaining_days", 0)

	if prefix == "before_event":
		result["price_before"] = snapshot.get("current_price", EMPTY_CELL)
		result["base_volatility"] = snapshot.get("volatility", EMPTY_CELL)
		result["volatility_before"] = snapshot.get("volatility", EMPTY_CELL)
	elif prefix == "immediately_after_trigger":
		result["price_at_trigger"] = snapshot.get("current_price", EMPTY_CELL)
		result["volatility_after_trigger"] = snapshot.get("volatility", EMPTY_CELL)
		result["trend_after_trigger"] = snapshot.get("trend_name", EMPTY_CELL)
		result["event_active_after_trigger"] = snapshot.get("event_active", false)
	elif prefix == "after_reapply":
		result["volatility_after_reapply"] = snapshot.get("volatility", EMPTY_CELL)
	elif prefix == "after_event_end":
		result["price_at_end"] = snapshot.get("current_price", EMPTY_CELL)
		result["volatility_after_end"] = snapshot.get("volatility", EMPTY_CELL)
		result["final_volatility"] = snapshot.get("volatility", EMPTY_CELL)
	elif prefix == "three_days_after":
		result["price_after_3_days"] = snapshot.get("current_price", EMPTY_CELL)
	elif prefix == "seven_days_after":
		result["price_after_7_days"] = snapshot.get("current_price", EMPTY_CELL)

	var price_value = snapshot.get("current_price", null)
	if price_value != null and _is_valid_price_value(float(price_value)):
		_collect_valid_price_sample(result, float(price_value))


func _advance_through_event_duration(result: Dictionary, event_data: MarketEventData, item: ItemData) -> void:
	for _day in range(event_data.duration_days):
		_advance_day()
		var snapshot := _capture_market_snapshot(item.id, event_data.event_id)
		var price := float(snapshot["current_price"])
		_collect_valid_price_sample(result, price)
		if _is_price_at_min(snapshot):
			result["days_at_min_price"] = int(result.get("days_at_min_price", 0)) + 1

	if _count_active_event(event_data.event_id) > 0:
		_fail_result(result, "EVENT_DURATION_INVALID", "Oversupply did not end after duration_days")


func _observe_recovery(result: Dictionary, event_data: MarketEventData, item: ItemData) -> void:
	var price_at_end := float(result.get("price_at_end", 0.0))
	var recovery_days := -1

	for day in range(1, 8):
		_advance_day()
		var snapshot := _capture_market_snapshot(item.id, event_data.event_id)
		var price := float(snapshot["current_price"])
		_collect_valid_price_sample(result, price)
		if recovery_days < 0 and price > price_at_end + 0.01:
			recovery_days = day
		if day == 3:
			_apply_snapshot(result, "three_days_after", snapshot)
		if day == 7:
			_apply_snapshot(result, "seven_days_after", snapshot)

	result["recovery_days"] = recovery_days


func _track_condition(result: Dictionary, event_data: MarketEventData, item: ItemData, simulation_day: int) -> void:
	var recent_sales := SalesStatsManager.get_recent_sales_amount(item.id, event_data.recent_sales_days)
	var condition_met := EventManager._does_event_meet_requirements(event_data)
	result["recent_sales_total"] = recent_sales

	if condition_met:
		result["condition_days_met"] = int(result.get("condition_days_met", 0)) + 1
		if not bool(result.get("condition_ever_met", false)):
			result["condition_ever_met"] = true
			result["first_condition_met_day"] = simulation_day


func _base_result(product: Dictionary, scenario: String) -> Dictionary:
	var event_data := product["event"] as MarketEventData
	return {
		"product_id": String(product["product_id"]),
		"event_id": event_data.event_id,
		"scenario": scenario,
		"threshold": event_data.recent_sales_threshold,
		"recent_sales_days": event_data.recent_sales_days,
		"total_sold": 0,
		"condition_met": false,
		"condition_ever_met": false,
		"condition_met_at_end": false,
		"first_condition_met_day": 0,
		"condition_days_met": 0,
		"event_triggered": false,
		"activation_count": 0,
		"cooldown_days": event_data.cooldown_days,
		"price_before": EMPTY_CELL,
		"price_at_trigger": EMPTY_CELL,
		"min_price_during": EMPTY_CELL,
		"price_at_end": EMPTY_CELL,
		"price_after_3_days": EMPTY_CELL,
		"price_after_7_days": EMPTY_CELL,
		"days_at_min_price": 0,
		"base_volatility": EMPTY_CELL,
		"max_volatility": EMPTY_CELL,
		"final_volatility": EMPTY_CELL,
		"volatility_before": EMPTY_CELL,
		"volatility_after_trigger": EMPTY_CELL,
		"volatility_after_reapply": EMPTY_CELL,
		"volatility_after_end": EMPTY_CELL,
		"trend_after_trigger": EMPTY_CELL,
		"event_active_after_trigger": false,
		"first_trigger_day": 0,
		"last_trigger_day": 0,
		"event_active_days": 0,
		"recovery_days": EMPTY_CELL,
		"valid_price_sample_count": 0,
		"validation_status": "PASS",
		"validation_error_codes": "",
		"validation_errors": ""
	}


func _fill_market_result(result: Dictionary) -> void:
	var event_id := String(result["event_id"])
	result["activation_count"] = _get_activation_count(event_id)
	result["first_trigger_day"] = int(_first_trigger_day_by_event.get(event_id, result.get("first_trigger_day", 0)))
	result["last_trigger_day"] = int(_last_trigger_day_by_event.get(event_id, result.get("last_trigger_day", 0)))
	result["event_active_days"] = maxi(int(result.get("event_active_days", 0)), int(_active_days_by_event.get(event_id, 0)))
	result["condition_met"] = result.get("condition_ever_met", false)

	if int(result.get("valid_price_sample_count", 0)) > 0:
		result["min_price_during"] = result.get("min_price_during", EMPTY_CELL)


func _validate_active_snapshot(result: Dictionary, event_data: MarketEventData, prefix: String) -> void:
	if not bool(result.get("%s_event_active" % prefix, false)):
		_fail_result(result, "EVENT_NOT_ACTIVE_AFTER_TRIGGER", "Expected Oversupply to be active after trigger")
	if not _snapshot_is_bearish(result, prefix):
		_fail_result(result, "TREND_NOT_BEARISH", "Oversupply trend is not bearish during active event")

	var before_volatility := float(result.get("volatility_before", result.get("base_volatility", 0.0)))
	var expected_volatility := before_volatility + event_data.volatility_modifier
	var actual_volatility := float(result.get("%s_volatility" % prefix, 0.0))
	if absf(actual_volatility - expected_volatility) > 0.0001:
		_fail_result(result, "VOLATILITY_MODIFIER_MISSING", "Oversupply volatility modifier is missing")


func _validate_reapply_snapshot(result: Dictionary) -> void:
	var after_trigger := float(result.get("volatility_after_trigger", 0.0))
	var after_reapply := float(result.get("volatility_after_reapply", 0.0))
	if absf(after_trigger - after_reapply) > 0.0001:
		_fail_result(result, "VOLATILITY_ACCUMULATED", "Oversupply volatility accumulated after reapply")


func _validate_end_snapshot(result: Dictionary) -> void:
	var before := float(result.get("volatility_before", result.get("base_volatility", 0.0)))
	var after_end := float(result.get("volatility_after_end", 0.0))
	if absf(after_end - before) > 0.0001:
		_fail_result(result, "VOLATILITY_NOT_RESET", "Volatility did not return to base after Oversupply ended")
	if _snapshot_is_bearish(result, "after_event_end"):
		_fail_result(result, "TREND_NOT_RESET", "Bearish trend remained after Oversupply ended")


func _snapshot_is_bearish(result: Dictionary, prefix: String) -> bool:
	var directional_modifier := float(result.get("%s_directional_modifier" % prefix, 0.0))
	if directional_modifier < -0.0001:
		return true
	return int(result.get("%s_current_trend" % prefix, CommodityData.MarketTrend.NEUTRAL)) == int(CommodityData.MarketTrend.BEARISH)


func _validate_price_fields(result: Dictionary) -> void:
	var keys := [
		"price_before",
		"price_at_trigger",
		"min_price_during",
		"price_at_end",
		"price_after_3_days",
		"price_after_7_days"
	]

	for key in keys:
		if not result.has(key):
			continue
		var value = result[key]
		if value is String and String(value).is_empty():
			continue
		if not _is_valid_price_value(float(value)):
			_fail_result(result, "INVALID_PRICE_SAMPLE", "%s is not a valid positive price sample" % key)


func _collect_valid_price_sample(result: Dictionary, price: float) -> void:
	if not _is_valid_price_value(price):
		return

	var current_min = result.get("min_price_during", EMPTY_CELL)
	if current_min is String and String(current_min).is_empty():
		result["min_price_during"] = price
	else:
		result["min_price_during"] = minf(float(current_min), price)

	result["valid_price_sample_count"] = int(result.get("valid_price_sample_count", 0)) + 1


func _is_valid_price_value(price: float) -> bool:
	return not is_nan(price) and not is_inf(price) and price > 0.0


func _is_price_at_min(snapshot: Dictionary) -> bool:
	var price := float(snapshot.get("current_price", NAN))
	if not _is_valid_price_value(price):
		return false

	var product_id := String(snapshot.get("product_id", ""))
	if product_id.is_empty():
		return false

	var commodity := _get_commodity_by_product_id(product_id)
	if commodity == null:
		return false

	var min_price := commodity.base_price * commodity.min_price_multiplier
	return price <= min_price + 0.01


func _fail_result(result: Dictionary, code: String, message: String) -> void:
	result["validation_status"] = "FAIL"
	result["validation_error_codes"] = _append_unique_token(String(result.get("validation_error_codes", "")), code)
	var errors := String(result.get("validation_errors", ""))
	if not errors.is_empty():
		errors += "|"
	errors += message
	result["validation_errors"] = errors
	_add_error(code, "%s %s: %s" % [result.get("product_id", ""), result.get("scenario", ""), message])


func _append_unique_token(existing: String, token: String) -> String:
	if existing.is_empty():
		return token
	var tokens := existing.split("|", false)
	if not tokens.has(token):
		tokens.append(token)
	return "|".join(tokens)


func _add_error(code: String, message: String) -> void:
	_validation_errors.append("%s: %s" % [code, message])


func _warn(message: String) -> void:
	_warnings.append("WARNING: %s" % message)


func _save_reports() -> void:
	_restore_possible_market_events()
	_save_detailed_report(_results)
	_save_summary_report(_results)
	_save_threshold_report(_threshold_rows)


func _save_detailed_report(rows: Array[Dictionary]) -> void:
	_save_csv(DETAIL_REPORT_PATH, [
		"product_id",
		"scenario",
		"threshold",
		"recent_sales_days",
		"total_sold",
		"condition_met",
		"condition_ever_met",
		"condition_met_at_end",
		"first_condition_met_day",
		"condition_days_met",
		"event_triggered",
		"activation_count",
		"cooldown_days",
		"price_before",
		"price_at_trigger",
		"min_price_during",
		"price_at_end",
		"price_after_3_days",
		"price_after_7_days",
		"price_after_sales_end",
		"days_at_min_price",
		"base_volatility",
		"max_volatility",
		"final_volatility",
		"volatility_before",
		"volatility_after_trigger",
		"volatility_after_reapply",
		"volatility_after_end",
		"trend_after_trigger",
		"event_active_after_trigger",
		"first_trigger_day",
		"last_trigger_day",
		"event_active_days",
		"recovery_days",
		"valid_price_sample_count",
		"validation_status",
		"validation_error_codes",
		"validation_errors"
	], rows)


func _save_summary_report(rows: Array[Dictionary]) -> void:
	var summary_rows: Array[Dictionary] = []

	for product in _get_test_products():
		var product_id := String(product["product_id"])
		var event_data := product["event"] as MarketEventData
		var product_rows := _rows_for_product(rows, product_id)
		summary_rows.append({
			"product_id": product_id,
			"threshold": event_data.recent_sales_threshold,
			"small_sales_activations": _scenario_activation_count(product_rows, "small_regular_sales"),
			"large_sales_activations": _scenario_activation_count(product_rows, "above_threshold"),
			"mass_sales_activations": _scenario_activation_count(product_rows, "mass_regular_sales"),
			"min_price_observed": _min_valid_price(product_rows),
			"max_recovery_days": _max_valid_recovery_days(product_rows),
			"save_load_status": _save_load_status(product_id),
			"valid_price_sample_count": _valid_price_sample_count(product_rows),
			"validation_error_count": _validation_error_count(product_rows),
			"validation_error_codes": _validation_error_codes(product_rows)
		})

	_save_csv(SUMMARY_REPORT_PATH, [
		"product_id",
		"threshold",
		"small_sales_activations",
		"large_sales_activations",
		"mass_sales_activations",
		"min_price_observed",
		"max_recovery_days",
		"save_load_status",
		"valid_price_sample_count",
		"validation_error_count",
		"validation_error_codes"
	], summary_rows)


func _save_threshold_report(rows: Array[Dictionary]) -> void:
	_save_csv(THRESHOLD_REPORT_PATH, [
		"product_id",
		"current_threshold",
		"growth_days",
		"yield_per_crop",
		"estimated_crops_required",
		"estimated_harvests_required",
		"threshold_reachability"
	], rows)


func _collect_threshold_analysis(product: Dictionary) -> void:
	var product_id := String(product["product_id"])
	var event_data := product["event"] as MarketEventData
	var crop := SaveManager._get_crop_by_id(product_id)

	if crop == null:
		_threshold_rows.append({
			"product_id": product_id,
			"current_threshold": event_data.recent_sales_threshold,
			"growth_days": EMPTY_CELL,
			"yield_per_crop": EMPTY_CELL,
			"estimated_crops_required": EMPTY_CELL,
			"estimated_harvests_required": EMPTY_CELL,
			"threshold_reachability": "Unknown: crop data not found"
		})
		return

	var yield_per_crop := maxi(crop.harvest_amount, 1)
	var crops_required := int(ceil(float(event_data.recent_sales_threshold) / float(yield_per_crop)))
	var harvests_required := crops_required
	var reachability := "Unknown: farm field capacity not available"
	if crop.days_to_ready > event_data.recent_sales_days:
		reachability = "Unlikely within %d days from fresh planting; growth takes %d days" % [event_data.recent_sales_days, crop.days_to_ready]

	_threshold_rows.append({
		"product_id": product_id,
		"current_threshold": event_data.recent_sales_threshold,
		"growth_days": crop.days_to_ready,
		"yield_per_crop": yield_per_crop,
		"estimated_crops_required": crops_required,
		"estimated_harvests_required": harvests_required,
		"threshold_reachability": reachability
	})


func _assert_report_integrity() -> void:
	for row in _results:
		if bool(row.get("event_triggered", false)):
			if int(row.get("activation_count", 0)) <= 0:
				_fail_result(row, "REPORTING_INVALID", "Triggered event has activation_count = 0")
			if int(row.get("first_trigger_day", 0)) <= 0:
				_fail_result(row, "REPORTING_INVALID", "Triggered event has no first_trigger_day")

		if int(row.get("valid_price_sample_count", 0)) > 0:
			var min_price = row.get("min_price_during", EMPTY_CELL)
			if min_price is String and String(min_price).is_empty():
				_fail_result(row, "REPORTING_INVALID", "Valid price samples exist but min_price_during is empty")
			elif not _is_valid_price_value(float(min_price)):
				_fail_result(row, "INVALID_PRICE_SAMPLE", "Valid price sample aggregation produced invalid min price")

		if String(row.get("scenario", "")) == "distributed_sales":
			if not bool(row.get("condition_ever_met", false)):
				_fail_result(row, "REPORTING_INVALID", "condition_ever_met did not remain true")

	var summary_rows := _create_summary_rows_for_assertions()
	for row in summary_rows:
		if String(row["product_id"]) != "wheat" and String(row["save_load_status"]) != "not_tested":
			_add_error("REPORTING_INVALID", "%s save_load_status should be not_tested" % row["product_id"])
		var min_price_observed = row["min_price_observed"]
		if not (min_price_observed is String and String(min_price_observed).is_empty()) and not _is_valid_price_value(float(min_price_observed)):
			_add_error("INVALID_PRICE_SAMPLE", "%s summary min_price_observed is invalid" % row["product_id"])

	for row in _results:
		if String(row.get("scenario", "")) == "above_threshold":
			if absf(float(row.get("volatility_after_trigger", 0.0)) - float(row.get("volatility_after_reapply", 0.0))) > 0.0001:
				_fail_result(row, "VOLATILITY_ACCUMULATED", "Report integrity found volatility reapply mismatch")
			if absf(float(row.get("volatility_after_end", 0.0)) - float(row.get("volatility_before", 0.0))) > 0.0001:
				_fail_result(row, "VOLATILITY_NOT_RESET", "Report integrity found volatility did not reset")


func _create_summary_rows_for_assertions() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for product in _get_test_products():
		var product_id := String(product["product_id"])
		var product_rows := _rows_for_product(_results, product_id)
		rows.append({
			"product_id": product_id,
			"min_price_observed": _min_valid_price(product_rows),
			"save_load_status": _save_load_status(product_id)
		})
	return rows


func _save_csv(path: String, headers: Array[String], rows: Array[Dictionary]) -> void:
	var absolute_directory := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if dir_error != OK:
		_add_error("CSV_WRITE_FAILED", "Could not create report directory: %s" % absolute_directory)
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_add_error("CSV_WRITE_FAILED", "Could not open CSV for writing: %s error=%d" % [path, FileAccess.get_open_error()])
		return

	file.store_line(_csv_line(headers))
	for row in rows:
		var values: Array[String] = []
		for header in headers:
			values.append(_csv_value(row.get(header, EMPTY_CELL)))
		file.store_line(_csv_line(values))
	file.close()


func _csv_value(value) -> String:
	if value == null:
		return EMPTY_CELL
	if value is float and (is_nan(value) or is_inf(value)):
		return EMPTY_CELL
	return str(value)


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


func _rows_for_product(rows: Array[Dictionary], product_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in rows:
		if String(row.get("product_id", "")) == product_id:
			result.append(row)
	return result


func _scenario_activation_count(rows: Array[Dictionary], scenario: String) -> int:
	for row in rows:
		if String(row.get("scenario", "")) == scenario:
			return int(row.get("activation_count", 0))
	return 0


func _min_valid_price(rows: Array[Dictionary]):
	var value := INF
	var found := false
	for row in rows:
		for key in ["min_price_during", "price_before", "price_at_trigger", "price_at_end", "price_after_3_days", "price_after_7_days"]:
			var sample = row.get(key, EMPTY_CELL)
			if sample is String and String(sample).is_empty():
				continue
			var price := float(sample)
			if _is_valid_price_value(price):
				value = minf(value, price)
				found = true
	if found:
		return value
	return EMPTY_CELL


func _max_valid_recovery_days(rows: Array[Dictionary]):
	var value := -1
	for row in rows:
		var sample = row.get("recovery_days", EMPTY_CELL)
		if sample is String and String(sample).is_empty():
			continue
		value = maxi(value, int(sample))
	if value >= 0:
		return value
	return EMPTY_CELL


func _save_load_status(product_id: String) -> String:
	for row in _results:
		if String(row.get("product_id", "")) == product_id and String(row.get("scenario", "")) == "save_load":
			return "passed" if String(row.get("validation_status", "FAIL")) == "PASS" else "failed"
	return "not_tested"


func _valid_price_sample_count(rows: Array[Dictionary]) -> int:
	var count := 0
	for row in rows:
		count += int(row.get("valid_price_sample_count", 0))
	return count


func _validation_error_count(rows: Array[Dictionary]) -> int:
	var count := 0
	for row in rows:
		if String(row.get("validation_status", "PASS")) != "PASS":
			count += 1
	return count


func _validation_error_codes(rows: Array[Dictionary]) -> String:
	var codes: Array[String] = []
	for row in rows:
		var row_codes := String(row.get("validation_error_codes", ""))
		if row_codes.is_empty():
			continue
		for code in row_codes.split("|", false):
			if not codes.has(code):
				codes.append(code)
	codes.sort()
	return "|".join(codes)


func _reset_commodity_runtime_values() -> void:
	for commodity in CommodityMarketManager.commodities:
		if commodity == null:
			continue

		commodity.current_price = commodity.base_price
		commodity.trend = CommodityData.MarketTrend.NEUTRAL
		commodity.price_history.clear()
		commodity.price_history_labels.clear()
		commodity.price_history.append(commodity.current_price)
		commodity.price_history_labels.append("%s %s" % [TimeManager.get_date_string(), TimeManager.get_time_string()])


func _get_commodity_by_product_id(product_id: String) -> CommodityData:
	for commodity in CommodityMarketManager.commodities:
		if commodity != null and commodity.item_data != null and commodity.item_data.id == product_id:
			return commodity
	return null


func _get_current_price_for_item(product_id: String):
	var commodity := _get_commodity_by_product_id(product_id)
	if commodity == null:
		return EMPTY_CELL
	return commodity.current_price


func _count_active_event(event_id: String) -> int:
	var count := 0
	for active_event in EventManager.active_market_events:
		if active_event != null and active_event.event_data != null and active_event.event_data.event_id == event_id:
			count += 1
	return count


func _get_active_remaining_days(event_id: String) -> int:
	for active_event in EventManager.active_market_events:
		if active_event != null and active_event.event_data != null and active_event.event_data.event_id == event_id:
			return active_event.remaining_days
	return 0


func _get_activation_count(event_id: String) -> int:
	return int(_activation_counts.get(event_id, 0))


func _absolute_day() -> int:
	return (
		(TimeManager.current_year - 1) * TimeManager.MONTHS_PER_YEAR * TimeManager.DAYS_PER_MONTH
		+ (TimeManager.current_month - 1) * TimeManager.DAYS_PER_MONTH
		+ TimeManager.current_day
	)


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


func _suppress_production_logs() -> void:
	_previous_commodity_logs_suppressed = CommodityMarketManager.suppress_logs
	_previous_event_logs_suppressed = EventManager.suppress_logs
	_previous_weather_logs_suppressed = WeatherManager.suppress_logs
	CommodityMarketManager.suppress_logs = true
	EventManager.suppress_logs = true
	WeatherManager.suppress_logs = true


func _restore_production_logs() -> void:
	_restore_possible_market_events()
	CommodityMarketManager.suppress_logs = _previous_commodity_logs_suppressed
	EventManager.suppress_logs = _previous_event_logs_suppressed
	WeatherManager.suppress_logs = _previous_weather_logs_suppressed


func _limit_possible_events(events: Array) -> void:
	var limited: Array[MarketEventData] = []
	for event_data in events:
		if event_data != null:
			limited.append(event_data as MarketEventData)
	EventManager.possible_market_events = limited


func _restore_possible_market_events() -> void:
	if _saved_possible_market_events.is_empty():
		return
	EventManager.possible_market_events = _saved_possible_market_events.duplicate()


func _print_summary() -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	print("Oversupply sales simulation completed")
	print("Products tested: ", _get_test_products().size())
	print("Rows written: ", _results.size())
	print("Validation errors: ", _validation_errors.size())
	print("Detailed report: ", output_path.path_join("oversupply_sales_simulation.csv"))
	print("Summary report: ", output_path.path_join("oversupply_sales_summary.csv"))
	print("Threshold report: ", output_path.path_join("oversupply_threshold_analysis.csv"))

	for warning in _warnings:
		print(warning)

	for error in _validation_errors:
		push_error(error)
