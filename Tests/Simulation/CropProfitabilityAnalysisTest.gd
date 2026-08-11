extends RefCounted

var runner: TestRunner

const OUTPUT_DIRECTORY := "user://simulation_reports/crop_profitability/"
const PROFITABILITY_REPORT_PATH := "user://simulation_reports/crop_profitability/crop_profitability_report.csv"
const SUGGESTIONS_REPORT_PATH := "user://simulation_reports/crop_profitability/crop_profitability_suggestions.csv"
const SUMMARY_REPORT_PATH := "user://simulation_reports/crop_profitability/crop_profitability_summary.csv"
const SEED_PRICE_BALANCE_REPORT_PATH := "user://simulation_reports/crop_profitability/seed_price_balance_report.csv"
const SEED_PRICE_BALANCE_SUMMARY_PATH := "user://simulation_reports/crop_profitability/seed_price_balance_summary.csv"

const EXPECTED_CROP_IDS: Array[String] = [
	"beetroot",
	"cabbage",
	"carrot",
	"corn",
	"lettuce",
	"potatoe",
	"pumpkin",
	"strawberry",
	"tomatoe",
	"wheat"
]

const TARGET_PROFIT_PER_DAY_FAST_MIN := 2.25
const TARGET_PROFIT_PER_DAY_FAST_MAX := 3.25
const TARGET_PROFIT_PER_DAY_MEDIUM_MIN := 2.75
const TARGET_PROFIT_PER_DAY_MEDIUM_MAX := 3.75
const TARGET_PROFIT_PER_DAY_SLOW_MIN := 3.0
const TARGET_PROFIT_PER_DAY_SLOW_MAX := 4.25
const TARGET_PROFIT_PER_DAY_HIGH_YIELD_MIN := 3.5
const TARGET_PROFIT_PER_DAY_HIGH_YIELD_MAX := 5.25
const TARGET_PROFIT_PER_DAY_EVENT_SPECIALIST_MIN := 2.25
const TARGET_PROFIT_PER_DAY_EVENT_SPECIALIST_MAX := 3.5

const BEAR_PRICE_MULTIPLIER := 0.8
const BASE_PRICE_MULTIPLIER := 1.0
const BULL_PRICE_MULTIPLIER := 1.2
const LARGE_CHANGE_REVIEW_PERCENT := 25.0
const LARGE_CHANGE_LIMIT_PERCENT := 50.0
const EXTREME_CHANGE_PERCENT := 100.0
const OVERSUPPLY_HIGH_CROP_EQUIVALENT := 100.0
const OVERSUPPLY_MODERATE_CROP_EQUIVALENT := 200.0
const TARGET_BEST_TO_WORST_RATIO_MAX := 2.0
const WARNING_BEST_TO_WORST_RATIO_MAX := 2.5
const WORLD_SCENE_PATH := "res://Scenes/Game/world.tscn"
const SEED_PRICE_RECOMMENDATIONS := {
	"beetroot": 8,
	"cabbage": 12,
	"carrot": 5,
	"corn": 9,
	"lettuce": 8,
	"potatoe": 8,
	"pumpkin": 8,
	"strawberry": 11,
	"tomatoe": 10,
	"wheat": 5
}

var _validation_errors: Array[String] = []
var _balance_warnings: Array[String] = []


func run() -> void:
	print("\n--- CropProfitabilityAnalysisTest ---")
	test_crop_profitability_analysis()


func test_crop_profitability_analysis() -> void:
	_prepare_analysis()

	var crops: Array[Dictionary] = _collect_crop_entries()
	var results: Array[Dictionary] = _analyze_crops(crops)
	var suggestions: Array[Dictionary] = _generate_suggestions(results)
	var summary: Dictionary = _build_summary(results, suggestions)
	var seed_balance_rows: Array[Dictionary] = _build_seed_price_balance_rows(results)
	var seed_balance_summary: Dictionary = _build_seed_price_balance_summary(seed_balance_rows)

	_validate_results(results)
	_validate_seed_price_balance_rows(seed_balance_rows)
	_assert_analyzer_invariants(results, suggestions, summary)
	_write_profitability_report(results)
	_write_suggestions_report(suggestions)
	_write_summary_report(summary)
	_write_seed_price_balance_report(seed_balance_rows)
	_write_seed_price_balance_summary_report(seed_balance_summary)
	_print_analysis_summary(results, summary)

	runner.assert_eq(_validation_errors.size(), 0, "Crop profitability analysis data validation")


func _prepare_analysis() -> void:
	_validation_errors.clear()
	_balance_warnings.clear()


func _collect_crop_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var seen_ids: Dictionary = {}

	for commodity in CommodityMarketManager.commodities:
		if commodity == null or commodity.item_data == null:
			_add_validation_error("MISSING_MARKET_DATA", "Commodity entry without item_data")
			continue

		var crop_id: String = commodity.item_data.id
		if seen_ids.has(crop_id):
			_add_validation_error("DUPLICATE_CROP_ID", "Duplicate commodity crop id: %s" % crop_id)
			continue
		seen_ids[crop_id] = true

		var crop: CropData = SaveManager._get_crop_by_id(crop_id)
		var seed_item: SeedItemData = null
		var harvest_item: CropItemData = null
		if crop != null:
			seed_item = crop.seed_item
			harvest_item = crop.harvest_item
		var seed_price_data: ItemPriceData = _find_price_data(seed_item)
		var product_price_data: ItemPriceData = _find_price_data(harvest_item)
		var oversupply: MarketEventData = EventManager.get_event_by_id("%s_oversupply" % crop_id)

		entries.append({
			"crop_id": crop_id,
			"crop": crop,
			"seed": seed_item,
			"harvest_item": harvest_item,
			"commodity": commodity,
			"seed_price_data": seed_price_data,
			"product_price_data": product_price_data,
			"oversupply": oversupply
		})

	for expected_id in EXPECTED_CROP_IDS:
		if not seen_ids.has(expected_id):
			_add_validation_error("MISSING_CROP_DATA", "Expected crop missing from commodity list: %s" % expected_id)

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["crop_id"]) < str(b["crop_id"])
	)
	return entries


func _find_price_data(item_data: ItemData) -> ItemPriceData:
	if item_data == null:
		return null

	for price_data in EconomyManager.price_data_list:
		if price_data != null and price_data.item_data != null and price_data.item_data.id == item_data.id:
			return price_data

	return null


func _analyze_crops(crops: Array[Dictionary]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for entry in crops:
		var result: Dictionary = _analyze_crop(entry)
		results.append(result)

	_apply_relative_analysis(results)
	return results


func _analyze_crop(entry: Dictionary) -> Dictionary:
	var crop_id: String = str(entry["crop_id"])
	var crop: CropData = entry["crop"] as CropData
	var seed_item: SeedItemData = entry["seed"] as SeedItemData
	var harvest_item: CropItemData = entry["harvest_item"] as CropItemData
	var commodity: CommodityData = entry["commodity"] as CommodityData
	var seed_price_data: ItemPriceData = entry["seed_price_data"] as ItemPriceData
	var oversupply: MarketEventData = entry["oversupply"] as MarketEventData

	var result: Dictionary = {
		"crop_id": crop_id,
		"warning_codes": "",
		"balance_status": "BALANCED",
		"validation_status": "PASS"
	}

	if crop == null:
		_fail_result(result, "MISSING_CROP_DATA", "Missing CropData for %s" % crop_id)
		return result
	if seed_item == null:
		_fail_result(result, "MISSING_SEED_DATA", "Missing seed data for %s" % crop_id)
	if harvest_item == null:
		_fail_result(result, "MISSING_PRODUCT_DATA", "Missing harvest item for %s" % crop_id)
	if commodity == null:
		_fail_result(result, "MISSING_MARKET_DATA", "Missing commodity for %s" % crop_id)
	if seed_price_data == null:
		_fail_result(result, "MISSING_SEED_PRICE", "Missing seed price for %s" % crop_id)

	var growth_days: int = crop.days_to_ready
	var yield_per_crop: int = crop.harvest_amount
	var seed_price: int = -1
	if seed_price_data != null:
		seed_price = seed_price_data.buy_price

	var base_sell_price := 0.0
	if commodity != null:
		base_sell_price = commodity.base_price
	var season_length := TimeManager.DAYS_PER_MONTH
	var tile_size := 1

	result["seasons"] = _season_list_to_string(crop.allowed_seasons)
	result["growth_days"] = growth_days
	result["yield_per_crop"] = yield_per_crop
	result["seed_price"] = seed_price
	result["base_sell_price"] = base_sell_price
	result["season_length"] = season_length
	result["tile_size"] = tile_size
	result["multi_harvest"] = false

	_validate_crop_entry(result)

	var role: String = _classify_crop_role(result)
	result["role"] = role

	_calculate_harvest_metrics(result)
	var target: Dictionary = _determine_target_range(result)
	result["target_profit_min"] = target["min"]
	result["target_profit_mid"] = target["mid"]
	result["target_profit_max"] = target["max"]
	result["nearest_target_profit"] = _nearest_value_in_range(
		float(result.get("profit_per_growth_day", 0.0)),
		float(target["min"]),
		float(target["max"])
	)
	_calculate_season_metrics(result)
	_calculate_market_scenarios(result)
	_calculate_oversupply_metrics(result, oversupply)
	_calculate_starting_capital_metrics(result)
	_determine_balance_status(result)
	return result


func _validate_crop_entry(result: Dictionary) -> void:
	var crop_id := str(result["crop_id"])

	if int(result.get("growth_days", 0)) <= 0:
		_fail_result(result, "INVALID_GROWTH_DAYS", "%s growth_days <= 0" % crop_id)
	if int(result.get("yield_per_crop", 0)) <= 0:
		_fail_result(result, "INVALID_YIELD", "%s yield <= 0" % crop_id)
	if int(result.get("seed_price", -1)) < 0:
		_fail_result(result, "INVALID_SEED_PRICE", "%s seed_price < 0" % crop_id)
	if float(result.get("base_sell_price", 0.0)) <= 0.0:
		_fail_result(result, "INVALID_SELL_PRICE", "%s base sell price <= 0" % crop_id)


func _calculate_harvest_metrics(result: Dictionary) -> void:
	var yield_per_crop := float(result["yield_per_crop"])
	var seed_price := float(result["seed_price"])
	var base_sell_price := float(result["base_sell_price"])
	var growth_days := float(result["growth_days"])

	var revenue_per_harvest := base_sell_price * yield_per_crop
	var profit_per_harvest := revenue_per_harvest - seed_price
	var profit_per_growth_day := profit_per_harvest / growth_days
	var break_even_sell_price := seed_price / yield_per_crop
	var profit_margin := profit_per_harvest / revenue_per_harvest

	result["revenue_per_harvest"] = revenue_per_harvest
	result["profit_per_harvest"] = profit_per_harvest
	result["profit_per_growth_day"] = profit_per_growth_day
	if seed_price > 0.0:
		result["roi"] = profit_per_harvest / seed_price
	else:
		result["roi"] = "N/A"
	result["profit_margin"] = profit_margin
	result["break_even_sell_price"] = break_even_sell_price

	if seed_price <= 0.0:
		_fail_result(result, "INVALID_SEED_PRICE", "%s seed_price <= 0 for ROI" % result["crop_id"])
	if profit_per_harvest < 0.0:
		_add_warning(result, "NEGATIVE_PROFIT")


func _calculate_season_metrics(result: Dictionary) -> void:
	var growth_days := int(result["growth_days"])
	var yield_per_crop := int(result["yield_per_crop"])
	var seed_price := float(result["seed_price"])
	var base_sell_price := float(result["base_sell_price"])
	var season_length := int(result["season_length"])

	var possible_harvests := int(floor(float(season_length) / float(growth_days)))
	var total_products := possible_harvests * yield_per_crop
	var season_seed_cost := float(possible_harvests) * seed_price
	var season_revenue := float(total_products) * base_sell_price
	var season_profit := season_revenue - season_seed_cost
	var unused_days := season_length - possible_harvests * growth_days
	var occupied_tile_days: int = maxi(possible_harvests * growth_days, 1)

	result["possible_harvests"] = possible_harvests
	result["season_total_products"] = total_products
	result["season_seed_cost"] = season_seed_cost
	result["season_revenue"] = season_revenue
	result["season_profit"] = season_profit
	result["season_profit_per_day"] = season_profit / float(season_length)
	result["unused_season_days"] = unused_days
	result["occupied_tile_days"] = occupied_tile_days
	result["profit_per_tile_day"] = season_profit / float(occupied_tile_days)


func _calculate_market_scenarios(result: Dictionary) -> void:
	_apply_market_scenario(result, "bear", BEAR_PRICE_MULTIPLIER)
	_apply_market_scenario(result, "base", BASE_PRICE_MULTIPLIER)
	_apply_market_scenario(result, "bull", BULL_PRICE_MULTIPLIER)

	if float(result["bear_profit_per_day"]) < 0.0:
		_add_warning(result, "BEAR_MARKET_UNPROFITABLE")
	if float(result["bull_profit_per_day"]) > _target_max_for_role(str(result["role"])) * 1.75:
		_add_warning(result, "BULL_MARKET_EXTREME")


func _apply_market_scenario(result: Dictionary, prefix: String, multiplier: float) -> void:
	var scenario_sell_price := float(result["base_sell_price"]) * multiplier
	var revenue := scenario_sell_price * float(result["yield_per_crop"])
	var profit_per_harvest := revenue - float(result["seed_price"])
	var profit_per_day := profit_per_harvest / float(result["growth_days"])
	var season_profit := (
		float(result["possible_harvests"])
		* (scenario_sell_price * float(result["yield_per_crop"]) - float(result["seed_price"]))
	)

	result["%s_market_price" % prefix] = scenario_sell_price
	result["%s_profit_per_harvest" % prefix] = profit_per_harvest
	result["%s_profit_per_day" % prefix] = profit_per_day
	result["%s_season_profit" % prefix] = season_profit


func _calculate_oversupply_metrics(result: Dictionary, oversupply: MarketEventData) -> void:
	if oversupply == null:
		result["oversupply_threshold"] = "N/A"
		result["oversupply_recent_sales_days"] = "N/A"
		result["oversupply_cooldown_days"] = "N/A"
		result["oversupply_crop_equivalent"] = "N/A"
		result["oversupply_risk_status"] = "UNKNOWN"
		return

	var threshold := oversupply.recent_sales_threshold
	var yield_per_crop := float(result["yield_per_crop"])
	var crop_equivalent := float(threshold) / yield_per_crop
	var growth_days := int(result["growth_days"])
	var available_tiles := _get_available_farming_tiles()
	var season_harvests := int(result.get("possible_harvests", 0))
	result["oversupply_threshold"] = threshold
	result["oversupply_recent_sales_days"] = oversupply.recent_sales_days
	result["oversupply_cooldown_days"] = oversupply.cooldown_days
	result["oversupply_crop_equivalent"] = crop_equivalent
	result["oversupply_test_field_harvests"] = "N/A"
	var risk_level := 0
	if crop_equivalent <= OVERSUPPLY_HIGH_CROP_EQUIVALENT:
		risk_level = 2
	elif crop_equivalent <= OVERSUPPLY_MODERATE_CROP_EQUIVALENT:
		risk_level = 1

	var has_upgrade_factor := false
	if growth_days <= 4:
		has_upgrade_factor = true
	if yield_per_crop > 1.0 and growth_days <= 6:
		has_upgrade_factor = true
	if yield_per_crop > 1.0 and season_harvests >= 4 and crop_equivalent <= OVERSUPPLY_MODERATE_CROP_EQUIVALENT:
		has_upgrade_factor = true
	if available_tiles > 0 and float(available_tiles) * yield_per_crop >= float(threshold) and season_harvests >= 3 and yield_per_crop > 1.0:
		has_upgrade_factor = true
	if has_upgrade_factor:
		risk_level = mini(risk_level + 1, 2)

	var risk_status := _oversupply_risk_status_from_level(risk_level)
	result["oversupply_risk_status"] = risk_status
	if risk_status == "HIGH":
		_add_warning(result, "HIGH_OVERSUPPLY_RISK")
	elif risk_status == "MODERATE":
		_add_warning(result, "MODERATE_OVERSUPPLY_RISK")


func _calculate_starting_capital_metrics(result: Dictionary) -> void:
	var starting_capital := MoneyManager.money
	var available_tiles := _get_available_farming_tiles()
	if available_tiles > 0:
		result["available_farming_tiles"] = available_tiles
		result["farm_capacity_known"] = true
	else:
		result["available_farming_tiles"] = "N/A"
		result["farm_capacity_known"] = false
		_add_warning(result, "FARM_CAPACITY_UNKNOWN")

	if starting_capital <= 0:
		result["starting_capital"] = "N/A"
		result["capital_limited_seed_count"] = "N/A"
		result["starting_capital_notes"] = "STARTING_CAPITAL_UNKNOWN"
		result["capital_analysis_type"] = "UNKNOWN"
		_add_warning(result, "STARTING_CAPITAL_UNKNOWN")
		return

	var seed_price := int(result["seed_price"])
	if seed_price <= 0:
		result["starting_capital"] = starting_capital
		result["capital_limited_seed_count"] = "N/A"
		result["starting_capital_notes"] = "INVALID_SEED_PRICE"
		result["capital_analysis_type"] = "INVALID_SEED_PRICE"
		return

	var capital_limited_seed_count := int(floor(float(starting_capital) / float(seed_price)))
	var usable_seed_count := capital_limited_seed_count
	if available_tiles > 0:
		usable_seed_count = mini(capital_limited_seed_count, available_tiles)
		result["capital_analysis_type"] = "CAPITAL_AND_FARM_LIMITED"
	else:
		result["capital_analysis_type"] = "CAPITAL_LIMITED_ONLY"
	var first_cycle_revenue := float(usable_seed_count) * float(result["yield_per_crop"]) * float(result["base_sell_price"])
	var first_cycle_profit := first_cycle_revenue - float(usable_seed_count * seed_price)
	result["starting_capital"] = starting_capital
	result["capital_limited_seed_count"] = capital_limited_seed_count
	result["usable_seed_count"] = usable_seed_count
	result["first_cycle_seed_cost"] = float(usable_seed_count * seed_price)
	result["capital_limited_first_cycle_revenue"] = first_cycle_revenue
	result["capital_limited_first_cycle_profit"] = first_cycle_profit
	result["first_cycle_revenue"] = first_cycle_revenue
	result["first_cycle_profit"] = first_cycle_profit
	result["payback_growth_days"] = result["growth_days"]
	result["test_field_capital_percent"] = "N/A"


func _classify_crop_role(result: Dictionary) -> String:
	var crop_id := str(result["crop_id"])
	var growth_days := int(result["growth_days"])
	var yield_per_crop := int(result["yield_per_crop"])
	var seed_price := int(result["seed_price"])

	if bool(result.get("multi_harvest", false)):
		return "MULTI_HARVEST"
	var halloween_event: MarketEventData = EventManager.get_event_by_id("halloween_pumpkin_demand")
	if crop_id == "pumpkin" and halloween_event != null:
		result["event_specialist_reason"] = halloween_event.display_name
		_add_warning(result, "EVENT_SPECIALIST_BASELINE")
		return "EVENT_SPECIALIST"
	result["event_specialist_reason"] = ""
	if yield_per_crop > 1:
		return "HIGH_YIELD"
	if growth_days <= 8 and seed_price <= 5:
		return "FAST_LOW_COST"
	if growth_days >= 12:
		return "SLOW_HIGH_RETURN"
	if growth_days >= 9 and growth_days <= 11:
		return "MEDIUM_BALANCED"

	_add_warning(result, "ROLE_UNCLASSIFIED")
	return "UNCLASSIFIED"


func _determine_target_range(result: Dictionary) -> Dictionary:
	var role := str(result["role"])
	var min_value := TARGET_PROFIT_PER_DAY_MEDIUM_MIN
	var max_value := TARGET_PROFIT_PER_DAY_MEDIUM_MAX

	match role:
		"FAST_LOW_COST":
			min_value = TARGET_PROFIT_PER_DAY_FAST_MIN
			max_value = TARGET_PROFIT_PER_DAY_FAST_MAX
		"SLOW_HIGH_RETURN":
			min_value = TARGET_PROFIT_PER_DAY_SLOW_MIN
			max_value = TARGET_PROFIT_PER_DAY_SLOW_MAX
		"HIGH_YIELD":
			min_value = TARGET_PROFIT_PER_DAY_HIGH_YIELD_MIN
			max_value = TARGET_PROFIT_PER_DAY_HIGH_YIELD_MAX
		"EVENT_SPECIALIST":
			min_value = TARGET_PROFIT_PER_DAY_EVENT_SPECIALIST_MIN
			max_value = TARGET_PROFIT_PER_DAY_EVENT_SPECIALIST_MAX
		"MULTI_HARVEST", "UNCLASSIFIED":
			_add_warning(result, "ROLE_UNCLASSIFIED")

	return {
		"min": min_value,
		"mid": (min_value + max_value) / 2.0,
		"max": max_value
	}


func _target_max_for_role(role: String) -> float:
	match role:
		"FAST_LOW_COST":
			return TARGET_PROFIT_PER_DAY_FAST_MAX
		"SLOW_HIGH_RETURN":
			return TARGET_PROFIT_PER_DAY_SLOW_MAX
		"HIGH_YIELD":
			return TARGET_PROFIT_PER_DAY_HIGH_YIELD_MAX
		"EVENT_SPECIALIST":
			return TARGET_PROFIT_PER_DAY_EVENT_SPECIALIST_MAX
		_:
			return TARGET_PROFIT_PER_DAY_MEDIUM_MAX


func _determine_balance_status(result: Dictionary) -> void:
	if str(result.get("validation_status", "PASS")) != "PASS":
		result["balance_status"] = "INVALID_DATA"
		return

	var target: Dictionary = _determine_target_range(result)
	var profit_per_day := float(result["profit_per_growth_day"])
	var roi_value := _numeric_or_zero(result["roi"])

	if profit_per_day < float(target["min"]):
		result["balance_status"] = "UNDERPOWERED"
		_add_warning(result, "BELOW_TARGET_PROFIT")
	elif profit_per_day > float(target["max"]):
		result["balance_status"] = "OVERPOWERED"
		_add_warning(result, "ABOVE_TARGET_PROFIT")
	else:
		result["balance_status"] = "BALANCED"

	if roi_value <= 0.0:
		_add_warning(result, "LOW_ROI")
	elif roi_value > 5.0:
		_add_warning(result, "HIGH_ROI")

	if str(result["role"]) == "UNCLASSIFIED" or bool(result.get("multi_harvest", false)):
		result["balance_status"] = "REVIEW_REQUIRED"


func _apply_relative_analysis(results: Array[Dictionary]) -> void:
	var valid_results: Array[Dictionary] = _valid_results(results)
	var median_profit_day := _median(_float_values(valid_results, "profit_per_growth_day"))
	var median_season_profit := _median(_float_values(valid_results, "season_profit"))

	for result in valid_results:
		if float(result["profit_per_growth_day"]) < median_profit_day and float(result["season_profit"]) < median_season_profit and _numeric_or_zero(result["roi"]) < _median(_float_values(valid_results, "roi")):
			_add_warning(result, "WEAK_IN_ALL_METRICS")

	_calculate_dominance_scores(valid_results)
	_mark_group_warnings(valid_results)


func _calculate_dominance_scores(results: Array[Dictionary]) -> void:
	var top_profit_day := _top_crop_ids(results, "profit_per_growth_day", 3)
	var top_season_profit := _top_crop_ids(results, "season_profit", 3)
	var top_roi := _top_crop_ids(results, "roi", 3)
	var top_profit_harvest := _top_crop_ids(results, "profit_per_harvest", 3)

	for result in results:
		var score := 0
		var crop_id := str(result["crop_id"])
		var top_metric_count := 0
		if top_profit_day.has(crop_id):
			score += 1
			top_metric_count += 1
		if top_season_profit.has(crop_id):
			score += 1
			top_metric_count += 1
		if top_roi.has(crop_id):
			score += 1
			top_metric_count += 1
		if top_profit_harvest.has(crop_id):
			score += 1
			top_metric_count += 1
		if int(result["seed_price"]) > 10:
			score -= 1
		if _has_warning(result, "HIGH_OVERSUPPLY_RISK"):
			score -= 1
		if _season_count(str(result["seasons"])) <= 1:
			score -= 1
		if str(result.get("role", "")) == "EVENT_SPECIALIST":
			score -= 1
		if int(result["growth_days"]) >= 12 and not top_profit_day.has(crop_id):
			score -= 1

		result["overall_dominance_score"] = score
		result["top_metric_count"] = top_metric_count
		if top_metric_count >= 3:
			_add_warning(result, "DOMINATES_MULTIPLE_METRICS")


func _mark_group_warnings(results: Array[Dictionary]) -> void:
	if results.is_empty():
		return

	var sorted_by_day: Array[Dictionary] = results.duplicate()
	sorted_by_day.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["profit_per_growth_day"]) > float(b["profit_per_growth_day"])
	)

	var best: Dictionary = sorted_by_day[0]
	var worst: Dictionary = sorted_by_day[sorted_by_day.size() - 1]
	var worst_value := maxf(float(worst["profit_per_growth_day"]), 0.0001)
	if float(best["profit_per_growth_day"]) / worst_value > WARNING_BEST_TO_WORST_RATIO_MAX:
		_add_warning(best, "PROFITABILITY_SPREAD_UNHEALTHY")


func _generate_suggestions(results: Array[Dictionary]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []

	for result in results:
		rows.append(_generate_price_suggestions(result))

	return rows


func _generate_price_suggestions(result: Dictionary) -> Dictionary:
	var target: Dictionary = _determine_target_range(result)
	var growth_days := float(result.get("growth_days", 0.0))
	var yield_per_crop := float(result.get("yield_per_crop", 0.0))
	var seed_price := float(result.get("seed_price", 0.0))
	var current_sell_price := float(result.get("base_sell_price", 0.0))
	var current_profit_per_day := float(result.get("profit_per_growth_day", 0.0))
	var target_min := float(target["min"])
	var target_max := float(target["max"])
	var target_mid := float(target["mid"])
	var nearest_target := _nearest_value_in_range(current_profit_per_day, target_min, target_max)

	var min_sell_price := _raw_sell_price_for_target(seed_price, growth_days, yield_per_crop, target_min)
	var max_sell_price := _raw_sell_price_for_target(seed_price, growth_days, yield_per_crop, target_max)
	var nearest_sell_price := _nearest_value_in_range(current_sell_price, min_sell_price, max_sell_price)
	var rounded_sell_data: Dictionary = _select_integer_sell_price(
		current_sell_price,
		seed_price,
		yield_per_crop,
		growth_days,
		target_min,
		target_max,
		min_sell_price,
		max_sell_price
	)
	var rounded_sell_price := float(rounded_sell_data["price"])
	var rounded_result_profit_per_day := float(rounded_sell_data["profit_per_day"])
	var rounded_result_in_target_range := bool(rounded_sell_data["in_target_range"])
	var sell_change := _percent_change(current_sell_price, rounded_sell_price)
	var sell_change_scale := _change_scale(sell_change)

	var min_seed_price := yield_per_crop * current_sell_price - target_max * growth_days
	var max_seed_price := yield_per_crop * current_sell_price - target_min * growth_days
	var seed_solution_feasible := max_seed_price >= 0.0
	min_seed_price = maxf(min_seed_price, 0.0)
	var nearest_seed_price: Variant = "N/A"
	var rounded_seed_price: Variant = "N/A"
	var seed_change: Variant = "N/A"
	var seed_change_scale := "N/A"
	var notes: Array[String] = []

	if seed_solution_feasible:
		var raw_seed_price := _nearest_value_in_range(seed_price, min_seed_price, max_seed_price)
		var rounded_seed_float := _round_price_inside_range(seed_price, raw_seed_price, min_seed_price, max_seed_price)
		nearest_seed_price = raw_seed_price
		rounded_seed_price = rounded_seed_float
		seed_change = _percent_change(seed_price, rounded_seed_float)
		seed_change_scale = _change_scale(float(seed_change))
	else:
		notes.append("SEED_PRICE_SOLUTION_NOT_FEASIBLE")
		_add_warning(result, "SEED_PRICE_SOLUTION_NOT_FEASIBLE")
	var maximum_balanced_seed_price: Variant = "N/A"
	if seed_solution_feasible:
		maximum_balanced_seed_price = max_seed_price

	var sell_candidate: Dictionary = _build_recommendation_candidate("SELL_PRICE", sell_change)
	var seed_candidate: Dictionary = _build_recommendation_candidate("SEED_PRICE", seed_change)
	var mixed_candidate: Dictionary = _build_mixed_candidate(sell_change, seed_change)
	var selected: Dictionary = _select_recommendation_candidate(
		result,
		current_profit_per_day,
		target_min,
		target_max,
		[sell_candidate, seed_candidate, mixed_candidate]
	)

	var recommendation_status := "OK"
	var largest_change := float(selected.get("change", 0.0))
	if largest_change > LARGE_CHANGE_LIMIT_PERCENT or str(selected.get("type", "")) == "REVIEW_MANUALLY":
		recommendation_status = "REVIEW_REQUIRED"
	var selected_type := str(selected.get("type", ""))
	if (selected_type == "SELL_PRICE" or selected_type == "MIXED") and absf(sell_change) > LARGE_CHANGE_LIMIT_PERCENT:
		notes.append("EXTREME_PRICE_CHANGE")
		_add_warning(result, "EXTREME_PRICE_CHANGE")
		recommendation_status = "REVIEW_REQUIRED"
	if (selected_type == "SELL_PRICE" or selected_type == "MIXED") and absf(sell_change) > EXTREME_CHANGE_PERCENT:
		notes.append("EXTREME_PRICE_CHANGE_OVER_100_PERCENT")
		_add_warning(result, "EXTREME_PRICE_CHANGE_OVER_100_PERCENT")
	if (selected_type == "SEED_PRICE" or selected_type == "MIXED") and not (seed_change is String) and absf(float(seed_change)) > LARGE_CHANGE_LIMIT_PERCENT:
		notes.append("EXTREME_SEED_PRICE_CHANGE")
		_add_warning(result, "EXTREME_SEED_PRICE_CHANGE")
		recommendation_status = "REVIEW_REQUIRED"
	if (selected_type == "SEED_PRICE" or selected_type == "MIXED") and not (seed_change is String) and absf(float(seed_change)) > EXTREME_CHANGE_PERCENT:
		notes.append("EXTREME_SEED_PRICE_CHANGE_OVER_100_PERCENT")
		_add_warning(result, "EXTREME_SEED_PRICE_CHANGE_OVER_100_PERCENT")
	if not rounded_result_in_target_range and selected_type == "SELL_PRICE":
		notes.append("NO_INTEGER_PRICE_IN_TARGET_RANGE")
		_add_warning(result, "NO_INTEGER_PRICE_IN_TARGET_RANGE")
		recommendation_status = "REVIEW_REQUIRED"
	elif largest_change > LARGE_CHANGE_LIMIT_PERCENT:
		pass
	elif largest_change > LARGE_CHANGE_REVIEW_PERCENT:
		recommendation_status = "REVIEW_REQUIRED"
		notes.append(str(selected.get("scale", "LARGE_CHANGE")))
	if not seed_solution_feasible and str(selected.get("type", "")) == "SEED_PRICE":
		selected["type"] = "REVIEW_MANUALLY"
		recommendation_status = "REVIEW_REQUIRED"

	return {
		"crop_id": result["crop_id"],
		"role": result.get("role", "UNCLASSIFIED"),
		"current_seed_price": seed_price,
		"current_sell_price": current_sell_price,
		"current_growth_days": growth_days,
		"current_profit_per_day": current_profit_per_day,
		"target_profit_min": target_min,
		"target_profit_mid": target_mid,
		"target_profit_max": target_max,
		"minimum_balanced_sell_price": min_sell_price,
		"maximum_balanced_sell_price": max_sell_price,
		"nearest_balanced_sell_price": nearest_sell_price,
		"raw_suggested_sell_price": nearest_sell_price,
		"rounded_suggested_sell_price": rounded_sell_price,
		"rounded_result_profit_per_day": rounded_result_profit_per_day,
		"rounded_result_in_target_range": rounded_result_in_target_range,
		"sell_price_change_percent": sell_change,
		"sell_price_change_scale": sell_change_scale,
		"minimum_balanced_seed_price": min_seed_price,
		"maximum_balanced_seed_price": maximum_balanced_seed_price,
		"nearest_balanced_seed_price": nearest_seed_price,
		"raw_suggested_seed_price": nearest_seed_price,
		"rounded_suggested_seed_price": rounded_seed_price,
		"seed_price_change_percent": seed_change,
		"seed_price_change_scale": seed_change_scale,
		"nearest_target_profit": nearest_target,
		"recommended_adjustment_type": selected.get("type", "REVIEW_MANUALLY"),
		"recommendation_status": recommendation_status,
		"warning_codes": result.get("warning_codes", ""),
		"recommendation_notes": "|".join(notes)
	}


func _raw_sell_price_for_target(seed_price: float, growth_days: float, yield_per_crop: float, target_profit_per_day: float) -> float:
	if yield_per_crop <= 0.0:
		return 0.0
	return (seed_price + target_profit_per_day * growth_days) / yield_per_crop


func _round_price_inside_range(current_value: float, target_value: float, min_value: float, max_value: float) -> float:
	if current_value < min_value:
		return ceil(target_value)
	if current_value > max_value:
		return floor(target_value)
	return round(current_value)


func _select_integer_sell_price(
	current_sell_price: float,
	seed_price: float,
	yield_per_crop: float,
	growth_days: float,
	target_min: float,
	target_max: float,
	min_sell_price: float,
	max_sell_price: float
) -> Dictionary:
	if current_sell_price >= min_sell_price and current_sell_price <= max_sell_price:
		return {
			"price": round(current_sell_price),
			"profit_per_day": _profit_per_day_for_prices(round(current_sell_price), seed_price, yield_per_crop, growth_days),
			"in_target_range": true
		}

	var start_price: int = int(floor(min_sell_price)) - 2
	var end_price: int = int(ceil(max_sell_price)) + 2
	var best_price: float = round(current_sell_price)
	var best_profit: float = _profit_per_day_for_prices(best_price, seed_price, yield_per_crop, growth_days)
	var best_in_range: bool = false
	var best_distance: float = INF
	var best_target_distance: float = INF

	for price in range(maxi(start_price, 1), maxi(end_price, start_price) + 1):
		var candidate_price: float = float(price)
		var candidate_profit: float = _profit_per_day_for_prices(candidate_price, seed_price, yield_per_crop, growth_days)
		var in_range: bool = candidate_profit >= target_min - 0.0001 and candidate_profit <= target_max + 0.0001
		var price_distance: float = absf(candidate_price - current_sell_price)
		var target_distance: float = _distance_to_range(candidate_profit, target_min, target_max)

		if in_range:
			if not best_in_range or price_distance < best_distance:
				best_price = candidate_price
				best_profit = candidate_profit
				best_in_range = true
				best_distance = price_distance
				best_target_distance = target_distance
		elif not best_in_range and target_distance < best_target_distance:
			best_price = candidate_price
			best_profit = candidate_profit
			best_distance = price_distance
			best_target_distance = target_distance

	return {
		"price": best_price,
		"profit_per_day": best_profit,
		"in_target_range": best_in_range
	}


func _distance_to_range(value: float, min_value: float, max_value: float) -> float:
	if value < min_value:
		return min_value - value
	if value > max_value:
		return value - max_value
	return 0.0


func _nearest_value_in_range(value: float, min_value: float, max_value: float) -> float:
	if min_value > max_value:
		var tmp := min_value
		min_value = max_value
		max_value = tmp
	return clampf(value, min_value, max_value)


func _change_scale(change_percent: float) -> String:
	var change := absf(change_percent)
	if is_equal_approx(change, 0.0):
		return "NO_CHANGE"
	if change <= 10.0:
		return "SMALL_CHANGE"
	if change <= LARGE_CHANGE_REVIEW_PERCENT:
		return "MODERATE_CHANGE"
	if change <= LARGE_CHANGE_LIMIT_PERCENT:
		return "LARGE_CHANGE"
	return "EXTREME_CHANGE"


func _synthetic_extreme_price_warning_codes(change_percent: float) -> Array[String]:
	var codes: Array[String] = []
	var change := absf(change_percent)
	if change > LARGE_CHANGE_LIMIT_PERCENT:
		codes.append("EXTREME_PRICE_CHANGE")
	if change > EXTREME_CHANGE_PERCENT:
		codes.append("EXTREME_PRICE_CHANGE_OVER_100_PERCENT")
	return codes


func _build_recommendation_candidate(candidate_type: String, change_value: Variant) -> Dictionary:
	if change_value is String:
		return {
			"type": candidate_type,
			"change": INF,
			"scale": "N/A",
			"feasible": false
		}

	var absolute_change := absf(float(change_value))
	return {
		"type": candidate_type,
		"change": absolute_change,
		"scale": _change_scale(absolute_change),
		"feasible": true
	}


func _build_mixed_candidate(sell_change: Variant, seed_change: Variant) -> Dictionary:
	if sell_change is String or seed_change is String:
		return {
			"type": "MIXED",
			"change": INF,
			"scale": "N/A",
			"feasible": false
		}

	var mixed_change := (absf(float(sell_change)) + absf(float(seed_change))) / 2.0
	return {
		"type": "MIXED",
		"change": mixed_change,
		"scale": _change_scale(mixed_change),
		"feasible": true
	}


func _select_recommendation_candidate(
	result: Dictionary,
	current_profit_per_day: float,
	target_min: float,
	target_max: float,
	candidates: Array
) -> Dictionary:
	var has_major_warning := _has_warning(result, "INVALID_SEED_PRICE") or _has_warning(result, "INVALID_SELL_PRICE")
	if current_profit_per_day >= target_min and current_profit_per_day <= target_max and not has_major_warning:
		return {
			"type": "NONE",
			"change": 0.0,
			"scale": "SMALL_CHANGE",
			"feasible": true
		}

	var best: Dictionary = {
		"type": "REVIEW_MANUALLY",
		"change": INF,
		"scale": "EXTREME_CHANGE",
		"feasible": false
	}
	for candidate in candidates:
		var candidate_dict: Dictionary = candidate as Dictionary
		if not bool(candidate_dict.get("feasible", false)):
			continue
		if float(candidate_dict.get("change", INF)) < float(best.get("change", INF)):
			best = candidate_dict

	return best


func _build_summary(results: Array[Dictionary], suggestions: Array[Dictionary]) -> Dictionary:
	var valid_results: Array[Dictionary] = _valid_results(results)
	var profit_values: Array[float] = _float_values(valid_results, "profit_per_growth_day")
	var roi_values: Array[float] = _float_values(valid_results, "roi")
	var season_profit_values: Array[float] = _float_values(valid_results, "season_profit")
	var sorted_by_profit: Array[Dictionary] = valid_results.duplicate()
	sorted_by_profit.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["profit_per_growth_day"]) > float(b["profit_per_growth_day"])
	)

	var best: Dictionary = {}
	var worst: Dictionary = {}
	if not sorted_by_profit.is_empty():
		best = sorted_by_profit[0]
		worst = sorted_by_profit[sorted_by_profit.size() - 1]
	var min_profit := _min_float(profit_values)
	var max_profit := _max_float(profit_values)
	var ratio := 0.0
	if not profit_values.is_empty():
		ratio = max_profit / maxf(min_profit, 0.0001)
	var spread_status := "HEALTHY_RANGE"
	if ratio > WARNING_BEST_TO_WORST_RATIO_MAX:
		spread_status = "UNHEALTHY_RANGE"
		if not _balance_warnings.has("GLOBAL: PROFITABILITY_SPREAD_UNHEALTHY"):
			_balance_warnings.append("GLOBAL: PROFITABILITY_SPREAD_UNHEALTHY")
	elif ratio > TARGET_BEST_TO_WORST_RATIO_MAX:
		spread_status = "REVIEW_RANGE"
	var projected: Dictionary = _build_projected_profitability_summary(results, suggestions)
	var recommendation_review_required_count := _count_recommendation_status(suggestions, "REVIEW_REQUIRED")

	return {
		"crop_count": results.size(),
		"average_profit_per_day": _average(profit_values),
		"median_profit_per_day": _median(profit_values),
		"standard_deviation_profit_per_day": _standard_deviation(profit_values),
		"minimum_profit_per_day": min_profit,
		"maximum_profit_per_day": max_profit,
		"best_crop_id": best.get("crop_id", ""),
		"worst_crop_id": worst.get("crop_id", ""),
		"best_to_worst_ratio": ratio,
		"current_best_to_worst_ratio": ratio,
		"average_roi": _average(roi_values),
		"median_season_profit": _median(season_profit_values),
		"underpowered_count": _count_status(results, "UNDERPOWERED"),
		"balanced_count": _count_status(results, "BALANCED"),
		"overpowered_count": _count_status(results, "OVERPOWERED"),
		"balance_review_required_count": _count_status(results, "REVIEW_REQUIRED"),
		"recommendation_review_required_count": recommendation_review_required_count,
		"review_required_count": recommendation_review_required_count,
		"profitability_spread_status": spread_status,
		"healthy_range_threshold": TARGET_BEST_TO_WORST_RATIO_MAX,
		"warning_range_threshold": WARNING_BEST_TO_WORST_RATIO_MAX,
		"extreme_change_count": _count_extreme_changes(suggestions),
		"extreme_price_change_count": _count_recommended_extreme_price_changes(suggestions),
		"extreme_seed_price_change_count": _count_recommended_extreme_seed_changes(suggestions),
		"farm_capacity_known": _farm_capacity_known(results),
		"available_farming_tiles": _available_farming_tiles_for_summary(results),
		"event_specialist_count": _count_role(results, "EVENT_SPECIALIST"),
		"high_oversupply_risk_count": _count_oversupply_risk(results, "HIGH"),
		"moderate_oversupply_risk_count": _count_oversupply_risk(results, "MODERATE"),
		"low_oversupply_risk_count": _count_oversupply_risk(results, "LOW"),
		"projected_minimum_profit_per_day": projected["minimum_profit_per_day"],
		"projected_maximum_profit_per_day": projected["maximum_profit_per_day"],
		"projected_best_crop_id": projected["best_crop_id"],
		"projected_worst_crop_id": projected["worst_crop_id"],
		"projected_best_to_worst_ratio": projected["best_to_worst_ratio"],
		"projected_profitability_spread_status": projected["profitability_spread_status"],
		"rank_rows": _build_rank_rows(valid_results)
	}


func _build_rank_rows(results: Array[Dictionary]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var by_profit_day := _rank_map(results, "profit_per_growth_day")
	var by_season_profit := _rank_map(results, "season_profit")
	var by_roi := _rank_map(results, "roi")

	for result in results:
		var crop_id := str(result["crop_id"])
		rows.append({
			"crop_id": crop_id,
			"profit_rank": by_profit_day.get(crop_id, 0),
			"season_profit_rank": by_season_profit.get(crop_id, 0),
			"roi_rank": by_roi.get(crop_id, 0),
			"overall_dominance_score": result.get("overall_dominance_score", 0)
		})

	return rows


func _build_projected_profitability_summary(results: Array[Dictionary], suggestions: Array[Dictionary]) -> Dictionary:
	var results_by_crop: Dictionary = {}
	for result in results:
		results_by_crop[str(result["crop_id"])] = result

	var projected_rows: Array[Dictionary] = []
	for suggestion in suggestions:
		var crop_id := str(suggestion.get("crop_id", ""))
		var result: Dictionary = results_by_crop.get(crop_id, {}) as Dictionary
		if result.is_empty():
			continue

		var sell_price := float(suggestion.get("current_sell_price", result.get("base_sell_price", 0.0)))
		var seed_price := float(suggestion.get("current_seed_price", result.get("seed_price", 0.0)))
		var adjustment := str(suggestion.get("recommended_adjustment_type", "NONE"))
		if adjustment == "SELL_PRICE" or adjustment == "MIXED" or str(suggestion.get("recommendation_status", "")) == "REVIEW_REQUIRED":
			var rounded_sell: Variant = suggestion.get("rounded_suggested_sell_price", "N/A")
			if not (rounded_sell is String):
				sell_price = float(rounded_sell)
		if adjustment == "SEED_PRICE" or adjustment == "MIXED":
			var rounded_seed: Variant = suggestion.get("rounded_suggested_seed_price", "N/A")
			if not (rounded_seed is String):
				seed_price = float(rounded_seed)

		projected_rows.append({
			"crop_id": crop_id,
			"profit_per_day": _profit_per_day_for_prices(
				sell_price,
				seed_price,
				float(result.get("yield_per_crop", 0.0)),
				float(result.get("growth_days", 1.0))
			)
		})

	projected_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["profit_per_day"]) > float(b["profit_per_day"])
	)

	if projected_rows.is_empty():
		return {
			"minimum_profit_per_day": 0.0,
			"maximum_profit_per_day": 0.0,
			"best_crop_id": "",
			"worst_crop_id": "",
			"best_to_worst_ratio": 0.0,
			"profitability_spread_status": "UNKNOWN"
		}

	var best: Dictionary = projected_rows[0]
	var worst: Dictionary = projected_rows[projected_rows.size() - 1]
	var minimum_profit := float(worst["profit_per_day"])
	var maximum_profit := float(best["profit_per_day"])
	var ratio := maximum_profit / maxf(minimum_profit, 0.0001)
	return {
		"minimum_profit_per_day": minimum_profit,
		"maximum_profit_per_day": maximum_profit,
		"best_crop_id": best["crop_id"],
		"worst_crop_id": worst["crop_id"],
		"best_to_worst_ratio": ratio,
		"profitability_spread_status": _spread_status_for_ratio(ratio)
	}


func _validate_results(results: Array[Dictionary]) -> void:
	if results.size() != EXPECTED_CROP_IDS.size():
		_add_validation_error("MISSING_CROP_DATA", "Expected 10 crops, got %d" % results.size())

	for result in results:
		for key in ["profit_per_harvest", "profit_per_growth_day", "season_profit", "season_profit_per_day"]:
			if result.has(key) and _is_invalid_number(result[key]):
				_fail_result(result, "INVALID_NUMBER", "%s has invalid %s" % [result["crop_id"], key])


func _assert_analyzer_invariants(results: Array[Dictionary], suggestions: Array[Dictionary], summary: Dictionary) -> void:
	var by_crop: Dictionary = {}
	for result in results:
		by_crop[str(result["crop_id"])] = result

	for suggestion in suggestions:
		var crop_id: String = str(suggestion["crop_id"])
		var result: Dictionary = by_crop.get(crop_id, {}) as Dictionary
		var current_profit: float = float(suggestion.get("current_profit_per_day", 0.0))
		var target_min: float = float(suggestion.get("target_profit_min", 0.0))
		var target_max: float = float(suggestion.get("target_profit_max", 0.0))
		var adjustment: String = str(suggestion.get("recommended_adjustment_type", ""))

		if current_profit >= target_min and current_profit <= target_max:
			if adjustment != "NONE" and str(result.get("balance_status", "")) == "BALANCED":
				_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s balanced crop should use NONE" % crop_id)
			if adjustment == "NONE" and float(suggestion.get("rounded_suggested_sell_price", -1.0)) != float(suggestion.get("current_sell_price", -2.0)):
				_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s NONE recommendation changed sell price" % crop_id)
		elif adjustment == "NONE":
			_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s non-balanced crop used NONE" % crop_id)

		var raw_sell_value: Variant = suggestion.get("raw_suggested_sell_price", "N/A")
		if not (raw_sell_value is String):
			var raw_sell: float = float(raw_sell_value)
			var profit_from_sell: float = _profit_per_day_for_prices(
				raw_sell,
				float(suggestion.get("current_seed_price", 0.0)),
				float(result.get("yield_per_crop", 0.0)),
				float(result.get("growth_days", 0.0))
			)
			if profit_from_sell < target_min - 0.001 or profit_from_sell > target_max + 0.001:
				_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s nearest sell price outside target range" % crop_id)

		var seed_change: Variant = suggestion.get("seed_price_change_percent", "N/A")
		if str(suggestion.get("nearest_balanced_seed_price", "")) == "N/A" and not (seed_change is String):
			_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s infeasible seed price has percent change" % crop_id)

		var recommended_scale: String = _recommended_change_scale(suggestion)
		if recommended_scale == "EXTREME_CHANGE" and str(suggestion.get("recommendation_status", "")) != "REVIEW_REQUIRED":
			_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s extreme change must be REVIEW_REQUIRED" % crop_id)
		if _has_warning(suggestion, "EXTREME_CHANGE"):
			_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s used EXTREME_CHANGE as warning code" % crop_id)
		if (adjustment == "SELL_PRICE" or adjustment == "MIXED") and absf(_numeric_or_zero(suggestion.get("sell_price_change_percent", 0.0))) > LARGE_CHANGE_LIMIT_PERCENT and not _has_warning(suggestion, "EXTREME_PRICE_CHANGE"):
			_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s sell change >50 missing EXTREME_PRICE_CHANGE" % crop_id)

		if adjustment != "SEED_PRICE" and str(suggestion.get("recommendation_status", "")) != "REVIEW_REQUIRED" and not bool(suggestion.get("rounded_result_in_target_range", false)):
			_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s safe recommendation outside target after rounding" % crop_id)

		var crop_equivalent: Variant = result.get("oversupply_crop_equivalent", "N/A")
		if not (crop_equivalent is String) and is_equal_approx(float(crop_equivalent), 200.0):
			var risk_status: String = str(result.get("oversupply_risk_status", ""))
			if risk_status == "HIGH" and not _has_real_oversupply_upgrade_factor(result):
				_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s crop equivalent 200 alone caused HIGH risk" % crop_id)

		var available_capacity: Variant = result.get("available_farming_tiles", "N/A")
		if available_capacity is String and str(result.get("capital_analysis_type", "")) != "CAPITAL_LIMITED_ONLY":
			_add_validation_error("ANALYZER_INVARIANT_FAILED", "%s unknown farm capacity not marked capital-limited" % crop_id)

	if not summary.has("profitability_spread_status"):
		_add_validation_error("ANALYZER_INVARIANT_FAILED", "Summary missing profitability_spread_status")
	if _count_recommendation_status(suggestions, "REVIEW_REQUIRED") != int(summary.get("recommendation_review_required_count", -1)):
		_add_validation_error("ANALYZER_INVARIANT_FAILED", "Summary recommendation REVIEW_REQUIRED count mismatch")
	if _oversupply_risk_status_from_level(2) != "HIGH":
		_add_validation_error("ANALYZER_INVARIANT_FAILED", "Oversupply level 2 should be HIGH")
	if _change_scale(53.33) != "EXTREME_CHANGE":
		_add_validation_error("ANALYZER_INVARIANT_FAILED", "Price change >50 should be EXTREME_CHANGE")
	var synthetic_codes := _synthetic_extreme_price_warning_codes(53.33)
	if not synthetic_codes.has("EXTREME_PRICE_CHANGE"):
		_add_validation_error("ANALYZER_INVARIANT_FAILED", "Synthetic >50 sell change should add EXTREME_PRICE_CHANGE")


func _build_seed_price_balance_rows(results: Array[Dictionary]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for result in _valid_results(results):
		rows.append(_build_seed_price_balance_row(result))
	return rows


func _build_seed_price_balance_row(result: Dictionary) -> Dictionary:
	var crop_id: String = str(result.get("crop_id", ""))
	var current_seed_price: int = int(result.get("seed_price", 0))
	var recommended_seed_price: int = int(SEED_PRICE_RECOMMENDATIONS.get(crop_id, current_seed_price))
	var sell_price: float = float(result.get("base_sell_price", 0.0))
	var growth_days: int = int(result.get("growth_days", 0))
	var yield_per_crop: int = int(result.get("yield_per_crop", 0))
	var revenue_per_harvest: float = sell_price * float(yield_per_crop)
	var current_profit_per_harvest: float = revenue_per_harvest - float(current_seed_price)
	var recommended_profit_per_harvest: float = revenue_per_harvest - float(recommended_seed_price)
	var current_profit_per_day: float = 0.0
	var recommended_profit_per_day: float = 0.0
	if growth_days > 0:
		current_profit_per_day = current_profit_per_harvest / float(growth_days)
		recommended_profit_per_day = recommended_profit_per_harvest / float(growth_days)
	var current_roi: float = 0.0
	if current_seed_price > 0:
		current_roi = current_profit_per_harvest / float(current_seed_price)
	var recommended_roi: float = 0.0
	if recommended_seed_price > 0:
		recommended_roi = recommended_profit_per_harvest / float(recommended_seed_price)
	var current_seed_cost_share: float = 0.0
	var recommended_seed_cost_share: float = 0.0
	if revenue_per_harvest > 0.0:
		current_seed_cost_share = float(current_seed_price) / revenue_per_harvest
		recommended_seed_cost_share = float(recommended_seed_price) / revenue_per_harvest
	var seed_price_change_percent: float = _percent_change(float(current_seed_price), recommended_seed_price)
	var warning_codes: String = _seed_balance_warning_codes(
		result,
		current_seed_price,
		recommended_seed_price,
		revenue_per_harvest,
		recommended_profit_per_harvest,
		recommended_profit_per_day,
		recommended_roi,
		seed_price_change_percent
	)
	var recommendation_status: String = _seed_recommendation_status(
		warning_codes,
		recommended_seed_price,
		revenue_per_harvest,
		recommended_profit_per_harvest,
		recommended_profit_per_day,
		seed_price_change_percent
	)
	var starting_metrics: Dictionary = _seed_starting_cycle_metrics(recommended_seed_price, sell_price, yield_per_crop)

	return {
		"crop_id": crop_id,
		"role": str(result.get("role", "UNCLASSIFIED")),
		"current_seed_price": current_seed_price,
		"recommended_seed_price": recommended_seed_price,
		"product_sell_price": sell_price,
		"growth_days": growth_days,
		"yield": yield_per_crop,
		"revenue_per_harvest": revenue_per_harvest,
		"current_profit_per_harvest": current_profit_per_harvest,
		"recommended_profit_per_harvest": recommended_profit_per_harvest,
		"current_profit_per_day": current_profit_per_day,
		"recommended_profit_per_day": recommended_profit_per_day,
		"current_roi": current_roi,
		"recommended_roi": recommended_roi,
		"current_seed_cost_share": current_seed_cost_share,
		"recommended_seed_cost_share": recommended_seed_cost_share,
		"seed_price_change_percent": seed_price_change_percent,
		"change_scale": _change_scale(seed_price_change_percent),
		"balance_status": str(result.get("balance_status", "UNKNOWN")),
		"recommendation_status": recommendation_status,
		"warning_codes": warning_codes,
		"starting_capital": starting_metrics["starting_capital"],
		"available_farming_tiles": starting_metrics["available_farming_tiles"],
		"starting_affordable_seed_count": starting_metrics["starting_affordable_seed_count"],
		"usable_starting_seed_count": starting_metrics["usable_starting_seed_count"],
		"starting_cycle_seed_cost": starting_metrics["starting_cycle_seed_cost"],
		"starting_cycle_revenue": starting_metrics["starting_cycle_revenue"],
		"starting_cycle_profit": starting_metrics["starting_cycle_profit"]
	}


func _seed_balance_warning_codes(
	result: Dictionary,
	current_seed_price: int,
	recommended_seed_price: int,
	revenue_per_harvest: float,
	recommended_profit_per_harvest: float,
	recommended_profit_per_day: float,
	recommended_roi: float,
	seed_price_change_percent: float
) -> String:
	var codes: String = ""
	var role: String = str(result.get("role", "UNCLASSIFIED"))
	var target_roi: Dictionary = _seed_roi_target_for_role(role)
	var target_profit_min: float = float(result.get("target_profit_min", 0.0))

	if current_seed_price <= 5 and recommended_roi > float(target_roi["max"]):
		codes = _append_unique_token(codes, "SEED_PRICE_TOO_LOW")
	if recommended_seed_price >= revenue_per_harvest:
		codes = _append_unique_token(codes, "BREAK_EVEN_RISK")
		codes = _append_unique_token(codes, "SEED_PRICE_TOO_HIGH")
	if recommended_roi > float(target_roi["max"]):
		codes = _append_unique_token(codes, "HIGH_ROI")
	if recommended_roi < float(target_roi["min"]):
		codes = _append_unique_token(codes, "LOW_ROI")
	if absf(seed_price_change_percent) > EXTREME_CHANGE_PERCENT:
		codes = _append_unique_token(codes, "EXTREME_SEED_PRICE_CHANGE")
	if recommended_profit_per_day < target_profit_min:
		codes = _append_unique_token(codes, "PROFIT_PER_DAY_BELOW_ROLE_TARGET")
	if role == "HIGH_YIELD" and recommended_seed_price <= 5:
		codes = _append_unique_token(codes, "HIGH_YIELD_LOW_ENTRY_COST")
	if role == "EVENT_SPECIALIST":
		codes = _append_unique_token(codes, "EVENT_SPECIALIST_REVIEW")
	var affordable_count: int = _starting_affordable_seed_count(recommended_seed_price)
	if affordable_count > 0 and affordable_count < 5:
		codes = _append_unique_token(codes, "LOW_STARTING_AFFORDABILITY")
	if recommended_profit_per_harvest <= 0.0:
		codes = _append_unique_token(codes, "SEED_PRICE_TOO_HIGH")
	return codes


func _seed_recommendation_status(
	warning_codes: String,
	recommended_seed_price: int,
	revenue_per_harvest: float,
	recommended_profit_per_harvest: float,
	recommended_profit_per_day: float,
	seed_price_change_percent: float
) -> String:
	if recommended_profit_per_harvest <= 0.0 or recommended_profit_per_day <= 0.0 or float(recommended_seed_price) >= revenue_per_harvest:
		return "NOT_RECOMMENDED"
	if absf(seed_price_change_percent) > EXTREME_CHANGE_PERCENT:
		return "REVIEW_REQUIRED"
	if warning_codes.split("|", false).has("PROFIT_PER_DAY_BELOW_ROLE_TARGET"):
		return "REVIEW_REQUIRED"
	if warning_codes.split("|", false).has("LOW_STARTING_AFFORDABILITY"):
		return "REVIEW_REQUIRED"
	return "SAFE"


func _seed_roi_target_for_role(role: String) -> Dictionary:
	match role:
		"FAST_LOW_COST":
			return {"min": 1.5, "max": 3.5}
		"HIGH_YIELD":
			return {"min": 2.0, "max": 5.0}
		"EVENT_SPECIALIST":
			return {"min": 1.5, "max": 4.0}
		"MEDIUM_BALANCED", "SLOW_HIGH_RETURN":
			return {"min": 1.5, "max": 4.0}
		_:
			return {"min": 1.5, "max": 4.0}


func _seed_starting_cycle_metrics(seed_price: int, sell_price: float, yield_per_crop: int) -> Dictionary:
	var starting_capital: int = MoneyManager.money
	var available_tiles: int = _get_available_farming_tiles()
	var affordable_seed_count: int = _starting_affordable_seed_count(seed_price)
	var usable_seed_count: int = affordable_seed_count
	var available_tiles_value: Variant = "N/A"
	if available_tiles > 0:
		usable_seed_count = mini(affordable_seed_count, available_tiles)
		available_tiles_value = available_tiles
	var seed_cost: float = float(usable_seed_count * seed_price)
	var revenue: float = float(usable_seed_count) * float(yield_per_crop) * sell_price
	return {
		"starting_capital": starting_capital,
		"available_farming_tiles": available_tiles_value,
		"starting_affordable_seed_count": affordable_seed_count,
		"usable_starting_seed_count": usable_seed_count,
		"starting_cycle_seed_cost": seed_cost,
		"starting_cycle_revenue": revenue,
		"starting_cycle_profit": revenue - seed_cost
	}


func _starting_affordable_seed_count(seed_price: int) -> int:
	if seed_price <= 0:
		return 0
	return int(floor(float(MoneyManager.money) / float(seed_price)))


func _build_seed_price_balance_summary(rows: Array[Dictionary]) -> Dictionary:
	var current_roi_values: Array[float] = _float_values(rows, "current_roi")
	var recommended_roi_values: Array[float] = _float_values(rows, "recommended_roi")
	var current_profit_values: Array[float] = _float_values(rows, "current_profit_per_day")
	var recommended_profit_values: Array[float] = _float_values(rows, "recommended_profit_per_day")
	return {
		"crop_count": rows.size(),
		"current_average_roi": _average(current_roi_values),
		"recommended_average_roi": _average(recommended_roi_values),
		"current_min_roi": _min_float(current_roi_values),
		"recommended_min_roi": _min_float(recommended_roi_values),
		"current_max_roi": _max_float(current_roi_values),
		"recommended_max_roi": _max_float(recommended_roi_values),
		"current_best_to_worst_profit_ratio": _ratio_from_values(current_profit_values),
		"recommended_best_to_worst_profit_ratio": _ratio_from_values(recommended_profit_values),
		"starting_capital": MoneyManager.money,
		"minimum_seed_price": _min_int_value(rows, "recommended_seed_price"),
		"maximum_seed_price": _max_int_value(rows, "recommended_seed_price"),
		"review_required_count": _count_seed_recommendation_status(rows, "REVIEW_REQUIRED")
	}


func _validate_seed_price_balance_rows(rows: Array[Dictionary]) -> void:
	for row in rows:
		var crop_id: String = str(row.get("crop_id", ""))
		var recommended_seed_price: int = int(row.get("recommended_seed_price", 0))
		var revenue_per_harvest: float = float(row.get("revenue_per_harvest", 0.0))
		var recommended_profit_per_day: float = float(row.get("recommended_profit_per_day", 0.0))
		if recommended_seed_price <= 0:
			_add_validation_error("INVALID_SEED_PRICE", "%s recommended seed price is not positive" % crop_id)
		if float(recommended_seed_price) >= revenue_per_harvest:
			_add_validation_error("INVALID_SEED_PRICE", "%s recommended seed price reaches break-even revenue" % crop_id)
		if recommended_profit_per_day <= 0.0:
			_add_validation_error("INVALID_SEED_PRICE", "%s recommended seed price makes crop unprofitable" % crop_id)
		if _is_invalid_number(row.get("recommended_roi", 0.0)):
			_add_validation_error("INVALID_NUMBER", "%s recommended ROI is invalid" % crop_id)


func _ratio_from_values(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	return _max_float(values) / maxf(_min_float(values), 0.0001)


func _min_int_value(rows: Array[Dictionary], key: String) -> int:
	if rows.is_empty():
		return 0
	var result: int = int(rows[0].get(key, 0))
	for row in rows:
		result = mini(result, int(row.get(key, 0)))
	return result


func _max_int_value(rows: Array[Dictionary], key: String) -> int:
	if rows.is_empty():
		return 0
	var result: int = int(rows[0].get(key, 0))
	for row in rows:
		result = maxi(result, int(row.get(key, 0)))
	return result


func _count_seed_recommendation_status(rows: Array[Dictionary], status: String) -> int:
	var count: int = 0
	for row in rows:
		if str(row.get("recommendation_status", "")) == status:
			count += 1
	return count


func _write_profitability_report(results: Array[Dictionary]) -> void:
	_write_csv(PROFITABILITY_REPORT_PATH, [
		"crop_id",
		"role",
		"event_specialist_reason",
		"seasons",
		"growth_days",
		"yield_per_crop",
		"seed_price",
		"base_sell_price",
		"revenue_per_harvest",
		"profit_per_harvest",
		"profit_per_growth_day",
		"target_profit_min",
		"target_profit_max",
		"nearest_target_profit",
		"roi",
		"profit_margin",
		"break_even_sell_price",
		"season_length",
		"possible_harvests",
		"season_total_products",
		"season_seed_cost",
		"season_revenue",
		"season_profit",
		"season_profit_per_day",
		"unused_season_days",
		"profit_per_tile_day",
		"tile_size",
		"oversupply_threshold",
		"oversupply_recent_sales_days",
		"oversupply_cooldown_days",
		"oversupply_crop_equivalent",
		"oversupply_risk_status",
		"bear_profit_per_day",
		"base_profit_per_day",
		"bull_profit_per_day",
		"available_farming_tiles",
		"capital_analysis_type",
		"starting_capital",
		"capital_limited_seed_count",
		"usable_seed_count",
		"first_cycle_seed_cost",
		"first_cycle_revenue",
		"first_cycle_profit",
		"capital_limited_first_cycle_revenue",
		"capital_limited_first_cycle_profit",
		"balance_status",
		"warning_codes"
	], results)


func _write_suggestions_report(suggestions: Array[Dictionary]) -> void:
	_write_csv(SUGGESTIONS_REPORT_PATH, [
		"crop_id",
		"role",
		"current_seed_price",
		"current_sell_price",
		"current_growth_days",
		"current_profit_per_day",
		"target_profit_min",
		"target_profit_mid",
		"target_profit_max",
		"minimum_balanced_sell_price",
		"maximum_balanced_sell_price",
		"nearest_balanced_sell_price",
		"raw_suggested_sell_price",
		"rounded_suggested_sell_price",
		"rounded_result_profit_per_day",
		"rounded_result_in_target_range",
		"sell_price_change_percent",
		"sell_price_change_scale",
		"minimum_balanced_seed_price",
		"maximum_balanced_seed_price",
		"nearest_balanced_seed_price",
		"raw_suggested_seed_price",
		"rounded_suggested_seed_price",
		"seed_price_change_percent",
		"seed_price_change_scale",
		"recommended_adjustment_type",
		"recommendation_status",
		"warning_codes",
		"recommendation_notes"
	], suggestions)


func _write_summary_report(summary: Dictionary) -> void:
	var rows: Array[Dictionary] = []
	for metric in [
		"crop_count",
		"average_profit_per_day",
		"median_profit_per_day",
		"standard_deviation_profit_per_day",
		"minimum_profit_per_day",
		"maximum_profit_per_day",
		"best_crop_id",
		"worst_crop_id",
		"best_to_worst_ratio",
		"current_best_to_worst_ratio",
		"average_roi",
		"median_season_profit",
		"underpowered_count",
		"balanced_count",
		"overpowered_count",
		"balance_review_required_count",
		"recommendation_review_required_count",
		"review_required_count",
		"profitability_spread_status",
		"healthy_range_threshold",
		"warning_range_threshold",
		"extreme_change_count",
		"extreme_price_change_count",
		"extreme_seed_price_change_count",
		"farm_capacity_known",
		"available_farming_tiles",
		"event_specialist_count",
		"high_oversupply_risk_count",
		"moderate_oversupply_risk_count",
		"low_oversupply_risk_count",
		"projected_minimum_profit_per_day",
		"projected_maximum_profit_per_day",
		"projected_best_crop_id",
		"projected_worst_crop_id",
		"projected_best_to_worst_ratio",
		"projected_profitability_spread_status"
	]:
		rows.append({"metric": metric, "value": summary.get(metric, "")})

	rows.append({"metric": "per_crop_rankings", "value": ""})
	for rank_row in summary.get("rank_rows", []):
		rows.append({
			"metric": "crop_rank",
			"value": "",
			"crop_id": rank_row["crop_id"],
			"profit_rank": rank_row["profit_rank"],
			"season_profit_rank": rank_row["season_profit_rank"],
			"roi_rank": rank_row["roi_rank"],
			"overall_dominance_score": rank_row["overall_dominance_score"]
		})

	_write_csv(SUMMARY_REPORT_PATH, [
		"metric",
		"value",
		"crop_id",
		"profit_rank",
		"season_profit_rank",
		"roi_rank",
		"overall_dominance_score"
	], rows)


func _write_seed_price_balance_report(rows: Array[Dictionary]) -> void:
	_write_csv(SEED_PRICE_BALANCE_REPORT_PATH, [
		"crop_id",
		"role",
		"current_seed_price",
		"recommended_seed_price",
		"product_sell_price",
		"growth_days",
		"yield",
		"revenue_per_harvest",
		"current_profit_per_harvest",
		"recommended_profit_per_harvest",
		"current_profit_per_day",
		"recommended_profit_per_day",
		"current_roi",
		"recommended_roi",
		"current_seed_cost_share",
		"recommended_seed_cost_share",
		"seed_price_change_percent",
		"change_scale",
		"balance_status",
		"recommendation_status",
		"warning_codes",
		"starting_capital",
		"available_farming_tiles",
		"starting_affordable_seed_count",
		"usable_starting_seed_count",
		"starting_cycle_seed_cost",
		"starting_cycle_revenue",
		"starting_cycle_profit"
	], rows)


func _write_seed_price_balance_summary_report(summary: Dictionary) -> void:
	var rows: Array[Dictionary] = []
	for metric in [
		"crop_count",
		"current_average_roi",
		"recommended_average_roi",
		"current_min_roi",
		"recommended_min_roi",
		"current_max_roi",
		"recommended_max_roi",
		"current_best_to_worst_profit_ratio",
		"recommended_best_to_worst_profit_ratio",
		"starting_capital",
		"minimum_seed_price",
		"maximum_seed_price",
		"review_required_count"
	]:
		rows.append({"metric": metric, "value": summary.get(metric, "")})

	_write_csv(SEED_PRICE_BALANCE_SUMMARY_PATH, ["metric", "value"], rows)


func _write_csv(path: String, headers: Array[String], rows: Array[Dictionary]) -> void:
	var absolute_directory := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if dir_error != OK:
		_add_validation_error("CSV_WRITE_FAILED", "Could not create report directory: %s" % absolute_directory)
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_add_validation_error("CSV_WRITE_FAILED", "Could not open CSV: %s error=%d" % [path, FileAccess.get_open_error()])
		return

	file.store_line(_csv_line(headers))
	for row in rows:
		var values: Array[String] = []
		for header in headers:
			values.append(_format_csv_value(header, row.get(header, "")))
		file.store_line(_csv_line(values))
	file.close()


func _format_csv_value(header: String, value) -> String:
	if value == null:
		return ""
	if value is String:
		return str(value)
	if value is int:
		return str(value)
	if value is float:
		var number := float(value)
		if is_nan(number) or is_inf(number):
			return "N/A"
		if header.contains("roi") or header == "profit_margin":
			return "%.4f" % number
		if header.contains("percent"):
			return "%.2f" % number
		return "%.2f" % number
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


func _print_analysis_summary(results: Array[Dictionary], summary: Dictionary) -> void:
	print("CROP PROFITABILITY ANALYSIS")
	print("Crops analyzed: ", results.size())
	print("Underpowered: ", summary.get("underpowered_count", 0))
	print("Balanced: ", summary.get("balanced_count", 0))
	print("Overpowered: ", summary.get("overpowered_count", 0))
	print("Review required: ", summary.get("review_required_count", 0))
	print("Best profit per day: %s %.2f" % [summary.get("best_crop_id", ""), float(summary.get("maximum_profit_per_day", 0.0))])
	print("Worst profit per day: %s %.2f" % [summary.get("worst_crop_id", ""), float(summary.get("minimum_profit_per_day", 0.0))])
	print("Best-to-worst ratio: %.2f" % float(summary.get("best_to_worst_ratio", 0.0)))
	print("Reports:")
	print("- ", ProjectSettings.globalize_path(PROFITABILITY_REPORT_PATH))
	print("- ", ProjectSettings.globalize_path(SUGGESTIONS_REPORT_PATH))
	print("- ", ProjectSettings.globalize_path(SUMMARY_REPORT_PATH))
	print("- ", ProjectSettings.globalize_path(SEED_PRICE_BALANCE_REPORT_PATH))
	print("- ", ProjectSettings.globalize_path(SEED_PRICE_BALANCE_SUMMARY_PATH))
	print("Profitability ranking:")

	var sorted: Array[Dictionary] = _valid_results(results)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["profit_per_growth_day"]) > float(b["profit_per_growth_day"])
	)
	for i in range(sorted.size()):
		var row: Dictionary = sorted[i]
		print("%d. %s %.2f/day" % [i + 1, row["crop_id"], float(row["profit_per_growth_day"])])

	for warning in _balance_warnings:
		print("WARNING: ", warning)
	for error in _validation_errors:
		push_error(error)


func _fail_result(result: Dictionary, code: String, message: String) -> void:
	result["validation_status"] = "FAIL"
	_add_warning(result, code)
	_add_validation_error(code, message)


func _add_validation_error(code: String, message: String) -> void:
	_validation_errors.append("%s: %s" % [code, message])


func _add_warning(result: Dictionary, code: String) -> void:
	result["warning_codes"] = _append_unique_token(str(result.get("warning_codes", "")), code)
	var warning := "%s: %s" % [result.get("crop_id", ""), code]
	if not _balance_warnings.has(warning):
		_balance_warnings.append(warning)


func _append_unique_token(existing: String, token: String) -> String:
	if existing.is_empty():
		return token
	var tokens := existing.split("|", false)
	if not tokens.has(token):
		tokens.append(token)
	return "|".join(tokens)


func _has_warning(result: Dictionary, code: String) -> bool:
	return str(result.get("warning_codes", "")).split("|", false).has(code)


func _valid_results(results: Array[Dictionary]) -> Array[Dictionary]:
	var valid: Array[Dictionary] = []
	for result in results:
		if str(result.get("validation_status", "PASS")) == "PASS":
			valid.append(result)
	return valid


func _float_values(results: Array[Dictionary], key: String) -> Array[float]:
	var values: Array[float] = []
	for result in results:
		var value = result.get(key, null)
		if value is String:
			continue
		values.append(float(value))
	return values


func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var middle := int(floor(float(sorted.size()) / 2.0))
	if sorted.size() % 2 == 0:
		return (sorted[middle - 1] + sorted[middle]) / 2.0
	return sorted[middle]


func _standard_deviation(values: Array[float]) -> float:
	if values.size() <= 1:
		return 0.0
	var avg := _average(values)
	var total := 0.0
	for value in values:
		total += pow(value - avg, 2.0)
	return sqrt(total / float(values.size()))


func _min_float(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var result := values[0]
	for value in values:
		result = minf(result, value)
	return result


func _max_float(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var result := values[0]
	for value in values:
		result = maxf(result, value)
	return result


func _numeric_or_zero(value) -> float:
	if value is String:
		return 0.0
	return float(value)


func _count_status(results: Array[Dictionary], status: String) -> int:
	var count := 0
	for result in results:
		if str(result.get("balance_status", "")) == status:
			count += 1
	return count


func _count_recommendation_status(suggestions: Array[Dictionary], status: String) -> int:
	var count := 0
	for suggestion in suggestions:
		if str(suggestion.get("recommendation_status", "")) == status:
			count += 1
	return count


func _count_role(results: Array[Dictionary], role: String) -> int:
	var count := 0
	for result in results:
		if str(result.get("role", "")) == role:
			count += 1
	return count


func _count_oversupply_risk(results: Array[Dictionary], risk_status: String) -> int:
	var count := 0
	for result in results:
		if str(result.get("oversupply_risk_status", "")) == risk_status:
			count += 1
	return count


func _count_extreme_changes(suggestions: Array[Dictionary]) -> int:
	var count := 0
	for suggestion in suggestions:
		if _recommended_change_scale(suggestion) == "EXTREME_CHANGE":
			count += 1
	return count


func _count_recommended_extreme_price_changes(suggestions: Array[Dictionary]) -> int:
	var count := 0
	for suggestion in suggestions:
		var adjustment := str(suggestion.get("recommended_adjustment_type", ""))
		if (adjustment == "SELL_PRICE" or adjustment == "MIXED") and str(suggestion.get("sell_price_change_scale", "")) == "EXTREME_CHANGE":
			count += 1
	return count


func _count_recommended_extreme_seed_changes(suggestions: Array[Dictionary]) -> int:
	var count := 0
	for suggestion in suggestions:
		var adjustment := str(suggestion.get("recommended_adjustment_type", ""))
		if (adjustment == "SEED_PRICE" or adjustment == "MIXED") and str(suggestion.get("seed_price_change_scale", "")) == "EXTREME_CHANGE":
			count += 1
	return count


func _recommended_change_scale(suggestion: Dictionary) -> String:
	var adjustment_type := str(suggestion.get("recommended_adjustment_type", ""))
	match adjustment_type:
		"SELL_PRICE":
			return str(suggestion.get("sell_price_change_scale", ""))
		"SEED_PRICE":
			return str(suggestion.get("seed_price_change_scale", ""))
		"MIXED":
			var sell_change := absf(_numeric_or_zero(suggestion.get("sell_price_change_percent", 0.0)))
			var seed_change := absf(_numeric_or_zero(suggestion.get("seed_price_change_percent", 0.0)))
			return _change_scale(maxf(sell_change, seed_change))
		_:
			return "SMALL_CHANGE"


func _farm_capacity_known(results: Array[Dictionary]) -> bool:
	for result in results:
		if bool(result.get("farm_capacity_known", false)):
			return true
	return false


func _available_farming_tiles_for_summary(results: Array[Dictionary]) -> Variant:
	for result in results:
		var available_tiles: Variant = result.get("available_farming_tiles", "N/A")
		if not (available_tiles is String):
			return available_tiles
	return "N/A"


func _oversupply_risk_status_from_level(level: int) -> String:
	if level >= 2:
		return "HIGH"
	if level == 1:
		return "MODERATE"
	return "LOW"


func _has_real_oversupply_upgrade_factor(result: Dictionary) -> bool:
	var growth_days := int(result.get("growth_days", 0))
	var yield_per_crop := float(result.get("yield_per_crop", 0.0))
	var season_harvests := int(result.get("possible_harvests", 0))
	var available_tiles: Variant = result.get("available_farming_tiles", "N/A")
	var threshold: Variant = result.get("oversupply_threshold", "N/A")
	if growth_days <= 4:
		return true
	if yield_per_crop > 1.0 and growth_days <= 6:
		return true
	if yield_per_crop > 1.0 and season_harvests >= 4:
		return true
	if not (available_tiles is String) and not (threshold is String):
		return float(available_tiles) * yield_per_crop >= float(threshold) and season_harvests >= 3 and yield_per_crop > 1.0
	return false


func _spread_status_for_ratio(ratio: float) -> String:
	if ratio > WARNING_BEST_TO_WORST_RATIO_MAX:
		return "UNHEALTHY_RANGE"
	if ratio > TARGET_BEST_TO_WORST_RATIO_MAX:
		return "REVIEW_RANGE"
	return "HEALTHY_RANGE"


func _get_available_farming_tiles() -> int:
	var file := FileAccess.open(WORLD_SCENE_PATH, FileAccess.READ)
	if file == null:
		return -1

	var count := 0
	while not file.eof_reached():
		var line := file.get_line()
		if line.begins_with("[node name=\"Tile_") and line.contains("parent=\"Farm/FarmGridGenerator\""):
			count += 1
	file.close()
	return count


func _top_crop_ids(results: Array[Dictionary], key: String, count: int) -> Array[String]:
	var sorted := results.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _numeric_or_zero(a.get(key, 0.0)) > _numeric_or_zero(b.get(key, 0.0))
	)
	var ids: Array[String] = []
	for i in range(mini(count, sorted.size())):
		ids.append(str(sorted[i]["crop_id"]))
	return ids


func _rank_map(results: Array[Dictionary], key: String) -> Dictionary:
	var sorted := results.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _numeric_or_zero(a.get(key, 0.0)) > _numeric_or_zero(b.get(key, 0.0))
	)
	var ranks: Dictionary = {}
	for i in range(sorted.size()):
		ranks[str(sorted[i]["crop_id"])] = i + 1
	return ranks


func _season_count(seasons: String) -> int:
	if seasons.is_empty() or seasons == "N/A":
		return 0
	return seasons.split("|", false).size()


func _season_list_to_string(seasons: Array[SeasonData.Season]) -> String:
	if seasons.is_empty():
		return "N/A"
	var names: Array[String] = []
	for season in seasons:
		names.append(_season_to_string(season))
	names.sort()
	return "|".join(names)


func _season_to_string(season: SeasonData.Season) -> String:
	match season:
		SeasonData.Season.SPRING:
			return "Spring"
		SeasonData.Season.SUMMER:
			return "Summer"
		SeasonData.Season.AUTUMN:
			return "Autumn"
		SeasonData.Season.WINTER:
			return "Winter"
		_:
			return "Unknown"


func _percent_change(current_value: float, suggested_value) -> float:
	if current_value == 0.0 or suggested_value is String:
		return 0.0
	return ((float(suggested_value) - current_value) / current_value) * 100.0


func _profit_per_day_for_prices(sell_price: float, seed_price: float, yield_per_crop: float, growth_days: float) -> float:
	if growth_days <= 0.0:
		return 0.0
	return ((sell_price * yield_per_crop) - seed_price) / growth_days


func _is_invalid_number(value) -> bool:
	if value is String:
		return false
	var number := float(value)
	return is_nan(number) or is_inf(number)
