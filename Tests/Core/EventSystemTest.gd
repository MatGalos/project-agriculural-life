extends RefCounted

var runner: TestRunner

const WHEAT: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")
const PUMPKIN: ItemData = preload("res://Data/Items/Crops/pumpkin_item.tres")
const CORN: ItemData = preload("res://Data/Items/Crops/corn_item.tres")
const TOMATOE: ItemData = preload("res://Data/Items/Crops/tomatoe_item.tres")
const WHEAT_SEED: ItemData = preload("res://Data/Items/Seeds/wheat_seed_item.tres")


func run() -> void:
	print("\n--- EventSystemTest ---")

	_reset_event_state()
	_test_single_product_event_still_works()
	_test_demand_spike_generation_is_limited()
	_test_market_event_generation_chances()
	_test_multi_product_event_modifies_all_items_without_duplicates()
	_test_volatility_does_not_accumulate_and_resets()
	_test_season_and_day_requirements()
	_test_bad_harvest_season_requirements()
	_test_halloween_once_per_year()
	_test_calendar_events_can_trigger_again_next_year()
	_test_event_cooldown_blocks_restart()
	_test_event_cooldown_survives_save_load()
	_test_once_per_season_blocks_same_season_restart()
	_test_weather_requirements()
	_test_temperature_requirement()
	_test_seed_buy_price_modifier()
	_test_oversupply_uses_sales_stats()
	_test_daily_event_start_limit()
	_test_active_events_expire()
	_test_commodity_prices_stay_within_min_max()
	_test_active_event_volatility_does_not_grow_over_reapply()
	_test_save_load_event_state_and_weather_history()
	_test_year_end_save_data_loads()
	_test_news_not_duplicated_on_event_restore()
	_test_deterministic_overlap()
	_reset_event_state()


func _reset_event_state() -> void:
	EventManager.active_market_events.clear()
	EventManager.apply_calendar_event_state_save_data({})
	EventManager.apply_event_activation_history_save_data({})
	EventManager.apply_once_per_season_state_save_data({})
	EventManager.apply_once_per_year_state_save_data({})
	EventManager.apply_daily_event_limit_save_data({})
	EventManager._events_started_today = 0
	EventManager._market_events_started_today = 0
	EventManager._events_started_today_key = ""
	EventManager._apply_market_event_effects()
	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()
	WeatherManager.apply_weather_history_save_data([])


func _test_single_product_event_still_works() -> void:
	var event_data := EventManager.get_event_by_id("wheat_oversupply")
	runner.assert_true(event_data != null, "Existing one-product event exists")
	runner.assert_eq(event_data.get_affected_items().size(), 1, "Existing target_item maps to one affected item")
	runner.assert_eq(event_data.get_affected_items()[0].id, "wheat", "Existing event still targets wheat")


func _test_demand_spike_generation_is_limited() -> void:
	var product_ids := [
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

	for product_id in product_ids:
		var event_data := EventManager.get_event_by_id("%s_demand_spike" % product_id)
		runner.assert_true(event_data != null, "%s demand spike event exists" % product_id)

		if event_data == null:
			continue

		runner.assert_true(
			event_data.trigger_chance <= 0.05,
			"%s demand spike trigger chance is limited" % product_id
		)


func _test_market_event_generation_chances() -> void:
	var product_ids := [
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

	for product_id in product_ids:
		var export_contract := EventManager.get_event_by_id("%s_export_contract" % product_id)
		var market_panic := EventManager.get_event_by_id("%s_market_panic" % product_id)

		runner.assert_true(export_contract != null, "%s export contract event exists" % product_id)
		runner.assert_true(market_panic != null, "%s market panic event exists" % product_id)

		if export_contract != null:
			runner.assert_eq(export_contract.trigger_chance, 0.01, "%s export contract trigger chance" % product_id)

		if market_panic != null:
			runner.assert_eq(market_panic.trigger_chance, 0.02, "%s market panic trigger chance" % product_id)


func _test_multi_product_event_modifies_all_items_without_duplicates() -> void:
	var event_data := MarketEventData.new()
	event_data.event_id = "test_multi"
	event_data.affected_items = [WHEAT, CORN, WHEAT, null]
	event_data.trend_effect = CommodityData.MarketTrend.BULLISH
	event_data.trend_strength_modifier = 0.02
	event_data.volatility_modifier = 0.01

	CommodityMarketManager.reset_event_modifiers()
	CommodityMarketManager.apply_event_modifier(event_data)

	runner.assert_eq(event_data.get_affected_items().size(), 2, "Multi-product event removes duplicate products")
	runner.assert_eq(CommodityMarketManager.get_commodity_for_item(WHEAT).trend, CommodityData.MarketTrend.BULLISH, "Multi-product event modifies first commodity")
	runner.assert_eq(CommodityMarketManager.get_commodity_for_item(CORN).trend, CommodityData.MarketTrend.BULLISH, "Multi-product event modifies second commodity")


func _test_volatility_does_not_accumulate_and_resets() -> void:
	CommodityMarketManager.reset_event_modifiers()
	var commodity := CommodityMarketManager.get_commodity_for_item(WHEAT)
	var base_volatility := commodity.volatility
	var event_data := MarketEventData.new()
	event_data.target_item = WHEAT
	event_data.trend_effect = CommodityData.MarketTrend.BULLISH
	event_data.trend_strength_modifier = 0.01
	event_data.volatility_modifier = 0.05

	CommodityMarketManager.reset_event_modifiers()
	CommodityMarketManager.apply_event_modifier(event_data)
	var modified_volatility := commodity.volatility

	CommodityMarketManager.reset_event_modifiers()
	CommodityMarketManager.apply_event_modifier(event_data)

	runner.assert_eq(commodity.volatility, modified_volatility, "Volatility modifier does not accumulate after reapply")

	CommodityMarketManager.reset_event_modifiers()
	runner.assert_eq(commodity.volatility, base_volatility, "Volatility returns to base after event reset")


func _test_season_and_day_requirements() -> void:
	var event_data := EventManager.get_event_by_id("halloween_pumpkin_demand")
	TimeManager.current_month = 2
	TimeManager.current_day = 25
	runner.assert_true(not EventManager._does_event_meet_requirements(event_data), "Seasonal event rejects invalid season")

	TimeManager.current_month = 3
	TimeManager.current_day = 22
	runner.assert_true(not EventManager._does_event_meet_requirements(event_data), "Day range rejects day before 23")

	TimeManager.current_day = 23
	runner.assert_true(EventManager._does_event_meet_requirements(event_data), "Day range accepts day 23")

	TimeManager.current_day = 30
	runner.assert_true(EventManager._does_event_meet_requirements(event_data), "Day range accepts day 30")


func _test_bad_harvest_season_requirements() -> void:
	var cases := {
		"wheat_bad_harvest": 1,
		"carrot_bad_harvest": 1,
		"lettuce_bad_harvest": 1,
		"corn_bad_harvest": 2,
		"strawberry_bad_harvest": 2,
		"tomatoe_bad_harvest": 2,
		"beetroot_bad_harvest": 3,
		"potatoe_bad_harvest": 3,
		"pumpkin_bad_harvest": 3,
		"cabbage_bad_harvest": 4
	}

	TimeManager.current_day = 10

	for event_id in cases.keys():
		var event_data := EventManager.get_event_by_id(String(event_id))
		var valid_month := int(cases[event_id])

		runner.assert_true(event_data != null, "%s event exists" % event_id)
		if event_data == null:
			continue

		for month in range(1, TimeManager.MONTHS_PER_YEAR + 1):
			TimeManager.current_month = month

			if month == valid_month:
				runner.assert_true(
					EventManager._does_event_meet_requirements(event_data),
					"%s accepts valid crop season" % event_id
				)
			else:
				runner.assert_true(
					not EventManager._does_event_meet_requirements(event_data),
					"%s rejects invalid crop season %d" % [event_id, month]
				)


func _test_halloween_once_per_year() -> void:
	_reset_event_state()
	TimeManager.current_year = 1
	TimeManager.current_month = 3
	TimeManager.current_day = 23

	EventManager._try_trigger_fixed_date_events_for_current_day()
	var first_count := _count_active_event("halloween_pumpkin_demand")
	EventManager.active_market_events.clear()

	for day in range(23, 31):
		TimeManager.current_day = day
		EventManager._try_trigger_fixed_date_events_for_current_day()

	runner.assert_eq(first_count, 1, "Halloween starts once when date is valid")
	runner.assert_eq(_count_active_event("halloween_pumpkin_demand"), 0, "Halloween does not restart during the same yearly date range")


func _test_calendar_events_can_trigger_again_next_year() -> void:
	_reset_event_state()
	TimeManager.current_year = 1
	TimeManager.current_month = 3
	TimeManager.current_day = 23

	EventManager._try_trigger_fixed_date_events_for_current_day()
	runner.assert_eq(_count_active_event("halloween_pumpkin_demand"), 1, "Halloween starts in first year")

	EventManager.active_market_events.clear()
	TimeManager.current_year = 2
	TimeManager.current_month = 3
	TimeManager.current_day = 23

	EventManager._try_trigger_fixed_date_events_for_current_day()
	runner.assert_eq(_count_active_event("halloween_pumpkin_demand"), 1, "Halloween can start again in next year")


func _test_event_cooldown_blocks_restart() -> void:
	_reset_event_state()
	TimeManager.current_year = 1
	TimeManager.current_month = 1
	TimeManager.current_day = 10

	var event_data := MarketEventData.new()
	event_data.event_id = "test_cooldown"
	event_data.duration_days = 2
	event_data.cooldown_days = 3
	event_data.event_category = MarketEventData.EventCategory.WEATHER

	runner.assert_true(EventManager._start_market_event(event_data, false), "Cooldown test event starts")

	EventManager.active_market_events.clear()
	TimeManager.current_day = 14
	runner.assert_true(not EventManager._start_market_event(event_data, false), "Cooldown blocks restart before enough days pass")

	TimeManager.current_day = 15
	runner.assert_true(EventManager._start_market_event(event_data, false), "Cooldown allows restart after enough days pass")


func _test_event_cooldown_survives_save_load() -> void:
	_reset_event_state()
	TimeManager.current_year = 1
	TimeManager.current_month = 1
	TimeManager.current_day = 10

	var event_data := MarketEventData.new()
	event_data.event_id = "test_cooldown_save"
	event_data.duration_days = 2
	event_data.cooldown_days = 3
	event_data.event_category = MarketEventData.EventCategory.WEATHER

	runner.assert_true(EventManager._start_market_event(event_data, false), "Cooldown save test event starts")
	var state_save := SaveManager._create_event_state_save_data()

	_reset_event_state()
	SaveManager._apply_event_state_save_data(state_save)
	TimeManager.current_year = 1
	TimeManager.current_month = 1
	TimeManager.current_day = 14

	runner.assert_true(not EventManager._start_market_event(event_data, false), "Save/load preserves cooldown activation day")


func _test_once_per_season_blocks_same_season_restart() -> void:
	_reset_event_state()
	TimeManager.current_year = 1
	TimeManager.current_month = 4
	TimeManager.current_day = 5

	var event_data := MarketEventData.new()
	event_data.event_id = "test_once_per_season"
	event_data.once_per_season = true
	event_data.event_category = MarketEventData.EventCategory.SEASONAL

	runner.assert_true(EventManager._start_market_event(event_data, false), "Once-per-season event starts")

	EventManager.active_market_events.clear()
	TimeManager.current_day = 12
	runner.assert_true(not EventManager._start_market_event(event_data, false), "Once-per-season blocks second start in same season")

	TimeManager.current_year = 2
	TimeManager.current_day = 5
	runner.assert_true(EventManager._start_market_event(event_data, false), "Once-per-season allows start in next year's season")


func _test_weather_requirements() -> void:
	var drought := EventManager.get_event_by_id("drought")
	TimeManager.current_month = 2
	WeatherManager.apply_weather_history_save_data([
		{"is_rainy": false},
		{"is_rainy": false},
		{"is_rainy": true},
		{"is_rainy": false}
	])
	runner.assert_true(not EventManager._does_event_meet_requirements(drought), "Drought rejects insufficient consecutive dry days")

	WeatherManager.apply_weather_history_save_data([
		{"is_rainy": false},
		{"is_rainy": false},
		{"is_rainy": false},
		{"is_rainy": false}
	])
	runner.assert_true(EventManager._does_event_meet_requirements(drought), "Drought accepts required dry-day history")

	var heavy_rain := EventManager.get_event_by_id("heavy_rain")
	TimeManager.current_month = 1
	WeatherManager.apply_weather_history_save_data([
		{"is_rainy": true},
		{"is_rainy": true},
		{"is_rainy": true},
		{"is_rainy": false},
		{"is_rainy": true},
		{"is_rainy": true}
	])
	runner.assert_true(EventManager._does_event_meet_requirements(heavy_rain), "Heavy Rain accepts rainy days in recent history")


func _test_temperature_requirement() -> void:
	var heatwave := EventManager.get_event_by_id("summer_heatwave")
	TimeManager.current_month = 2
	WeatherManager.current_day_base_temperature = 24
	runner.assert_true(not EventManager._does_event_meet_requirements(heatwave), "Heatwave rejects low daily base temperature")

	WeatherManager.current_day_base_temperature = 31
	runner.assert_true(EventManager._does_event_meet_requirements(heatwave), "Heatwave accepts high daily base temperature")


func _test_seed_buy_price_modifier() -> void:
	_reset_event_state()
	var event_data := EventManager.get_event_by_id("spring_planting_boom")
	var base_price := EconomyManager.get_buy_price(WHEAT_SEED)

	EventManager.trigger_event_by_id(event_data.event_id)
	EventManager._apply_market_event_effects()
	runner.assert_true(EconomyManager.get_buy_price(WHEAT_SEED) > base_price, "Spring Planting Boom increases seed buy price")

	EventManager.active_market_events.clear()
	EventManager._apply_market_event_effects()
	runner.assert_eq(EconomyManager.get_buy_price(WHEAT_SEED), base_price, "Seed buy price returns to base after event")


func _test_oversupply_uses_sales_stats() -> void:
	var event_data := EventManager.get_event_by_id("wheat_oversupply")
	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.current_day_sales["wheat"] = event_data.recent_sales_threshold

	runner.assert_true(EventManager._does_event_meet_requirements(event_data), "Oversupply uses SalesStatsManager recent sales")


func _test_daily_event_start_limit() -> void:
	_reset_event_state()
	TimeManager.current_year = 1
	TimeManager.current_month = 1
	TimeManager.current_day = 10

	var first := EventManager.trigger_event_by_id("wheat_export_contract")
	var second := EventManager.trigger_event_by_id("corn_export_contract")

	runner.assert_true(first, "Daily event limit allows first event")
	runner.assert_true(not second, "Daily market event limit rejects second product event")
	runner.assert_eq(EventManager.active_market_events.size(), 1, "Daily market event limit keeps max one new product event")


func _test_active_events_expire() -> void:
	_reset_event_state()
	var longest_duration := 0

	for event_data in EventManager.possible_market_events:
		if event_data == null:
			continue

		var active_event := ActiveMarketEvent.new()
		active_event.setup(event_data)
		EventManager.active_market_events.append(active_event)
		longest_duration = maxi(longest_duration, active_event.remaining_days)

	for _day in range(longest_duration + 1):
		EventManager._process_active_events()

	runner.assert_eq(EventManager.active_market_events.size(), 0, "No active event remains forever after enough days")


func _test_commodity_prices_stay_within_min_max() -> void:
	var commodity := CommodityMarketManager.get_commodity_for_item(WHEAT)
	var saved_current_price := commodity.current_price
	var saved_volatility := commodity.volatility
	var saved_trend := commodity.trend
	var saved_trend_strength := commodity.trend_strength

	commodity.current_price = commodity.base_price
	commodity.volatility = 5.0
	commodity.trend = CommodityData.MarketTrend.BULLISH
	commodity.trend_strength = 2.0

	for i in range(20):
		CommodityMarketManager._update_commodity_price(commodity, "Test %02d" % i)
		var min_price := commodity.base_price * commodity.min_price_multiplier
		var max_price := commodity.base_price * commodity.max_price_multiplier

		runner.assert_true(commodity.current_price >= min_price, "Commodity price stays above min bound")
		runner.assert_true(commodity.current_price <= max_price, "Commodity price stays below max bound")

	commodity.current_price = saved_current_price
	commodity.volatility = saved_volatility
	commodity.trend = saved_trend
	commodity.trend_strength = saved_trend_strength


func _test_active_event_volatility_does_not_grow_over_reapply() -> void:
	_reset_event_state()
	var commodity := CommodityMarketManager.get_commodity_for_item(WHEAT)
	var base_volatility := commodity.volatility
	var event_data := EventManager.get_event_by_id("wheat_market_panic")
	var active_event := ActiveMarketEvent.new()
	active_event.setup(event_data)
	EventManager.active_market_events.append(active_event)

	EventManager._apply_market_event_effects()
	var modified_volatility := commodity.volatility

	for _i in range(5):
		EventManager._apply_market_event_effects()
		runner.assert_eq(commodity.volatility, modified_volatility, "Active event volatility does not grow after repeated reapply")

	EventManager.active_market_events.clear()
	EventManager._apply_market_event_effects()
	runner.assert_eq(commodity.volatility, base_volatility, "Volatility returns to base after active event is removed")


func _test_save_load_event_state_and_weather_history() -> void:
	_reset_event_state()
	var event_data := EventManager.get_event_by_id("wheat_export_contract")
	EventManager.trigger_event_by_id(event_data.event_id)
	EventManager.active_market_events[0].remaining_days = 2
	EventManager.apply_calendar_event_state_save_data({"halloween_pumpkin_demand:1": true})
	WeatherManager.apply_weather_history_save_data([
		{"year": 1, "season": SeasonData.Season.SUMMER, "day": 3, "is_rainy": false, "base_temperature": 30.0, "pattern_id": "sunny_day", "pattern_name": "Sunny Day"}
	])

	var events_save := SaveManager._create_events_save_data()
	var state_save := SaveManager._create_event_state_save_data()
	var weather_save := SaveManager._create_weather_save_data()

	_reset_event_state()
	SaveManager._apply_event_state_save_data(state_save)
	SaveManager._apply_weather_save_data(weather_save)
	SaveManager._apply_events_save_data(events_save, false)

	runner.assert_eq(EventManager.active_market_events.size(), 1, "Save/load restores active event")
	runner.assert_eq(EventManager.active_market_events[0].remaining_days, 2, "Save/load preserves remaining days")
	runner.assert_eq(WeatherManager.daily_weather_history.size(), 1, "Save/load preserves weather history")
	runner.assert_true(EventManager.create_calendar_event_state_save_data().has("halloween_pumpkin_demand:1"), "Save/load preserves calendar event lock")


func _test_year_end_save_data_loads() -> void:
	_reset_event_state()
	TimeManager.current_year = 1
	TimeManager.current_month = 4
	TimeManager.current_day = 30
	TimeManager.current_minute_of_day = 23 * 60
	WeatherManager.apply_weather_history_save_data([
		{"year": 1, "season": SeasonData.Season.WINTER, "day": 29, "is_rainy": true, "base_temperature": 2.0, "pattern_id": "stormy_day", "pattern_name": "Stormy Day"}
	])

	var event_data := EventManager.get_event_by_id("wheat_export_contract")
	EventManager.trigger_event_by_id(event_data.event_id)
	EventManager.apply_calendar_event_state_save_data({"halloween_pumpkin_demand:1": true})
	var save_data := SaveManager._create_save_data()

	_reset_event_state()
	TimeManager.current_year = 99
	TimeManager.current_month = 1
	TimeManager.current_day = 1
	SaveManager._apply_save_data(save_data)

	runner.assert_eq(TimeManager.current_year, 1, "Year-end save restores year")
	runner.assert_eq(TimeManager.current_month, 4, "Year-end save restores winter month")
	runner.assert_eq(TimeManager.current_day, 30, "Year-end save restores final day")
	runner.assert_eq(WeatherManager.daily_weather_history.size(), 1, "Year-end save restores weather history")
	runner.assert_eq(EventManager.active_market_events.size(), 1, "Year-end save restores active event")
	runner.assert_true(EventManager.create_calendar_event_state_save_data().has("halloween_pumpkin_demand:1"), "Year-end save restores fixed-date event lock")


func _test_news_not_duplicated_on_event_restore() -> void:
	_reset_event_state()
	NewsManager.clear_news()
	var event_data := EventManager.get_event_by_id("wheat_export_contract")
	EventManager.trigger_event_by_id(event_data.event_id)
	var save_data := SaveManager._create_events_save_data()
	var news_count := NewsManager.news_items.size()

	SaveManager._apply_events_save_data(save_data, false)
	NewsManager.rebuild_announced_event_ids_from_active_events()

	runner.assert_eq(NewsManager.news_items.size(), news_count, "Save/load event restore does not duplicate news")


func _test_deterministic_overlap() -> void:
	_reset_event_state()
	var bullish := MarketEventData.new()
	bullish.event_id = "test_bullish"
	bullish.target_item = TOMATOE
	bullish.trend_effect = CommodityData.MarketTrend.BULLISH
	bullish.trend_strength_modifier = 0.03
	bullish.volatility_modifier = 0.02

	var bearish := MarketEventData.new()
	bearish.event_id = "test_bearish"
	bearish.target_item = TOMATOE
	bearish.trend_effect = CommodityData.MarketTrend.BEARISH
	bearish.trend_strength_modifier = 0.01
	bearish.volatility_modifier = 0.02

	CommodityMarketManager.reset_event_modifiers()
	CommodityMarketManager.apply_event_modifier(bullish)
	CommodityMarketManager.apply_event_modifier(bearish)
	var first_trend := CommodityMarketManager.get_commodity_for_item(TOMATOE).trend

	CommodityMarketManager.reset_event_modifiers()
	CommodityMarketManager.apply_event_modifier(bearish)
	CommodityMarketManager.apply_event_modifier(bullish)
	var second_trend := CommodityMarketManager.get_commodity_for_item(TOMATOE).trend

	runner.assert_eq(first_trend, CommodityData.MarketTrend.BULLISH, "Overlapping trend resolves by summed direction")
	runner.assert_eq(second_trend, first_trend, "Overlapping trend resolution is deterministic independent of order")


func _count_active_event(event_id: String) -> int:
	var count := 0

	for active_event in EventManager.active_market_events:
		if active_event != null and active_event.event_data != null and active_event.event_data.event_id == event_id:
			count += 1

	return count
