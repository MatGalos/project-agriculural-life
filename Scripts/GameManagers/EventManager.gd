extends Node

signal market_event_started(event_data: MarketEventData)
signal market_event_ended(event_data: MarketEventData)
signal market_events_changed

const WEATHER_RAIN_LOOKBACK_DAYS := 7
const MAX_EVENTS_STARTED_PER_DAY := 2

var market_events: Array[MarketEventData] = [
	preload("res://Data/Events/beetroot_demand_spike_event.tres"),
	preload("res://Data/Events/beetroot_oversupply_event.tres"),
	preload("res://Data/Events/beetroot_bad_harvest_event.tres"),
	preload("res://Data/Events/cabbage_demand_spike_event.tres"),
	preload("res://Data/Events/cabbage_oversupply_event.tres"),
	preload("res://Data/Events/cabbage_bad_harvest_event.tres"),
	preload("res://Data/Events/carrot_demand_spike_event.tres"),
	preload("res://Data/Events/carrot_oversupply_event.tres"),
	preload("res://Data/Events/carrot_bad_harvest_event.tres"),
	preload("res://Data/Events/corn_demand_spike_event.tres"),
	preload("res://Data/Events/corn_oversupply_event.tres"),
	preload("res://Data/Events/corn_bad_harvest_event.tres"),
	preload("res://Data/Events/lettuce_demand_spike_event.tres"),
	preload("res://Data/Events/lettuce_oversupply_event.tres"),
	preload("res://Data/Events/lettuce_bad_harvest_event.tres"),
	preload("res://Data/Events/potatoe_demand_spike_event.tres"),
	preload("res://Data/Events/potatoe_oversupply_event.tres"),
	preload("res://Data/Events/potatoe_bad_harvest_event.tres"),
	preload("res://Data/Events/pumpkin_demand_spike_event.tres"),
	preload("res://Data/Events/pumpkin_oversupply_event.tres"),
	preload("res://Data/Events/pumpkin_bad_harvest_event.tres"),
	preload("res://Data/Events/strawberry_demand_spike_event.tres"),
	preload("res://Data/Events/strawberry_oversupply_event.tres"),
	preload("res://Data/Events/strawberry_bad_harvest_event.tres"),
	preload("res://Data/Events/tomatoe_demand_spike_event.tres"),
	preload("res://Data/Events/tomatoe_oversupply_event.tres"),
	preload("res://Data/Events/tomatoe_bad_harvest_event.tres"),
	preload("res://Data/Events/wheat_demand_spike_event.tres"),
	preload("res://Data/Events/wheat_oversupply_event.tres"),
	preload("res://Data/Events/bad_harvest_event.tres"),
	preload("res://Data/Events/Market/beetroot_export_contract_event.tres"),
	preload("res://Data/Events/Market/beetroot_market_panic_event.tres"),
	preload("res://Data/Events/Market/cabbage_export_contract_event.tres"),
	preload("res://Data/Events/Market/cabbage_market_panic_event.tres"),
	preload("res://Data/Events/Market/carrot_export_contract_event.tres"),
	preload("res://Data/Events/Market/carrot_market_panic_event.tres"),
	preload("res://Data/Events/Market/corn_export_contract_event.tres"),
	preload("res://Data/Events/Market/corn_market_panic_event.tres"),
	preload("res://Data/Events/Market/lettuce_export_contract_event.tres"),
	preload("res://Data/Events/Market/lettuce_market_panic_event.tres"),
	preload("res://Data/Events/Market/potatoe_export_contract_event.tres"),
	preload("res://Data/Events/Market/potatoe_market_panic_event.tres"),
	preload("res://Data/Events/Market/pumpkin_export_contract_event.tres"),
	preload("res://Data/Events/Market/pumpkin_market_panic_event.tres"),
	preload("res://Data/Events/Market/strawberry_export_contract_event.tres"),
	preload("res://Data/Events/Market/strawberry_market_panic_event.tres"),
	preload("res://Data/Events/Market/tomatoe_export_contract_event.tres"),
	preload("res://Data/Events/Market/tomatoe_market_panic_event.tres"),
	preload("res://Data/Events/Market/wheat_export_contract_event.tres"),
	preload("res://Data/Events/Market/wheat_market_panic_event.tres")
]

var weather_events: Array[MarketEventData] = [
	preload("res://Data/Events/Weather/drought_event.tres"),
	preload("res://Data/Events/Weather/heavy_rain_event.tres"),
	preload("res://Data/Events/Weather/summer_heatwave_event.tres")
]

var seasonal_events: Array[MarketEventData] = [
	preload("res://Data/Events/Seasonal/spring_planting_boom_event.tres"),
	preload("res://Data/Events/Seasonal/autumn_harvest_festival_event.tres"),
	preload("res://Data/Events/Seasonal/halloween_pumpkin_demand_event.tres"),
	preload("res://Data/Events/Seasonal/winter_shortage_event.tres")
]

var possible_market_events: Array[MarketEventData] = []
var active_market_events: Array[ActiveMarketEvent] = []
var triggered_fixed_event_keys: Dictionary = {}
var _events_started_today := 0
var _events_started_today_key := ""
var process_day_synchronously_for_test := false
var suppress_logs := false

func _ready() -> void:
	_rebuild_possible_market_events()
	TimeManager.day_changed.connect(_on_day_changed)
	_validate_possible_market_events()
	_try_trigger_fixed_date_events_for_current_day.call_deferred()


func _rebuild_possible_market_events() -> void:
	possible_market_events.clear()
	possible_market_events.append_array(market_events)
	possible_market_events.append_array(weather_events)
	possible_market_events.append_array(seasonal_events)

func _on_day_changed() -> void:
	_update_daily_event_limit_key()
	_process_active_events()

	if process_day_synchronously_for_test:
		_finish_day_event_processing()
	else:
		_finish_day_event_processing.call_deferred()


func _finish_day_event_processing() -> void:
	_try_trigger_market_events()
	_apply_market_event_effects()

	market_events_changed.emit()


func finish_day_event_processing_for_test() -> void:
	_finish_day_event_processing()

func _process_active_events() -> void:
	var ended_events: Array[ActiveMarketEvent] = []

	for active_event in active_market_events:
		active_event.remaining_days -= 1

		if active_event.remaining_days <= 0:
			ended_events.append(active_event)

	for ended_event in ended_events:
		active_market_events.erase(ended_event)
		market_event_ended.emit(ended_event.event_data)

func _try_trigger_market_events() -> void:
	_update_daily_event_limit_key()

	for event_data in possible_market_events:
		if not _can_start_event_today():
			break

		if event_data == null:
			continue

		if _is_event_already_active(event_data):
			continue
		
		if not _does_event_meet_requirements(event_data):
			continue

		match event_data.trigger_mode:
			MarketEventData.TriggerMode.RANDOM:
				if randf() <= event_data.trigger_chance:
					_start_market_event(event_data)
			MarketEventData.TriggerMode.CONDITION_BASED:
				if randf() <= event_data.trigger_chance:
					_start_market_event(event_data)
			MarketEventData.TriggerMode.FIXED_DATE:
				if _can_trigger_fixed_date_event(event_data):
					_start_market_event(event_data)
					_mark_fixed_date_event_triggered(event_data)


func _try_trigger_fixed_date_events_for_current_day() -> void:
	_update_daily_event_limit_key()

	for event_data in possible_market_events:
		if not _can_start_event_today():
			break

		if event_data == null:
			continue

		if event_data.trigger_mode != MarketEventData.TriggerMode.FIXED_DATE:
			continue

		if _is_event_already_active(event_data):
			continue

		if not _does_event_meet_requirements(event_data):
			continue

		if not _can_trigger_fixed_date_event(event_data):
			continue

		_start_market_event(event_data)
		_mark_fixed_date_event_triggered(event_data)

	_apply_market_event_effects()
	market_events_changed.emit()

func _is_event_already_active(event_data: MarketEventData) -> bool:
	for active_event in active_market_events:
		if active_event.event_data == event_data:
			return true

		if active_event.event_data != null and active_event.event_data.event_id == event_data.event_id:
			return true

	return false


func trigger_event_by_id(event_id: String) -> bool:
	var event_data := get_event_by_id(event_id)

	if event_data == null:
		push_warning("EventManager: event id not found: %s" % event_id)
		return false

	return _start_market_event(event_data)


func _start_market_event(event_data: MarketEventData, emit_started_signal: bool = true) -> bool:
	if event_data == null:
		return false

	_update_daily_event_limit_key()

	if not _can_start_event_today():
		return false

	if _is_event_already_active(event_data):
		return false

	var active_event := ActiveMarketEvent.new()
	active_event.setup(event_data)

	active_market_events.append(active_event)
	_events_started_today += 1

	if emit_started_signal:
		market_event_started.emit(event_data)
		if not suppress_logs:
			print("Market event started: ", event_data.display_name)

	return true


func _update_daily_event_limit_key() -> void:
	var current_key := "%d:%d:%d" % [
		TimeManager.current_year,
		TimeManager.current_month,
		TimeManager.current_day
	]

	if _events_started_today_key == current_key:
		return

	_events_started_today_key = current_key
	_events_started_today = 0


func _can_start_event_today() -> bool:
	return _events_started_today < MAX_EVENTS_STARTED_PER_DAY

func _apply_market_event_effects() -> void:
	CommodityMarketManager.reset_event_modifiers()
	EconomyManager.reset_buy_price_modifiers()

	for active_event in active_market_events:
		var event_data := active_event.event_data

		if event_data == null:
			continue

		CommodityMarketManager.apply_event_modifier(event_data)
		EconomyManager.apply_buy_price_event_modifier(event_data)

	CommodityMarketManager.commodity_prices_updated.emit()

func get_active_market_events() -> Array[ActiveMarketEvent]:
	return active_market_events

func get_event_by_id(event_id: String) -> MarketEventData:
	for event_data in possible_market_events:
		if event_data != null and event_data.event_id == event_id:
			return event_data

	return null

func _does_event_meet_requirements(event_data: MarketEventData) -> bool:
	if event_data == null:
		return false

	return (
		_meets_sales_requirements(event_data)
		and _meets_season_requirements(event_data)
		and _meets_day_range_requirements(event_data)
		and _meets_weather_requirements(event_data)
		and _meets_temperature_requirements(event_data)
	)


func _meets_sales_requirements(event_data: MarketEventData) -> bool:
	if not event_data.requires_recent_sales:
		return true

	var items := event_data.get_affected_items()

	if event_data.target_item != null:
		items = [event_data.target_item]

	if items.is_empty():
		push_warning("EventManager: sales requirement has no item for event %s" % event_data.event_id)
		return false

	for item in items:
		var recent_sales := SalesStatsManager.get_recent_sales_amount(
			item.id,
			event_data.recent_sales_days
		)

		if recent_sales >= event_data.recent_sales_threshold:
			return true

	return false


func _meets_season_requirements(event_data: MarketEventData) -> bool:
	if not event_data.requires_season:
		return true

	if event_data.required_seasons.is_empty():
		push_warning("EventManager: event %s requires season but has no required seasons" % event_data.event_id)
		return false

	return event_data.required_seasons.has(TimeManager.get_current_season())


func _meets_day_range_requirements(event_data: MarketEventData) -> bool:
	if not event_data.requires_day_range:
		return true

	if event_data.start_day < 1 or event_data.end_day > TimeManager.DAYS_PER_MONTH:
		push_warning("EventManager: event %s has day range outside 1-30" % event_data.event_id)
		return false

	if event_data.start_day > event_data.end_day:
		push_warning("EventManager: event %s has start_day greater than end_day" % event_data.event_id)
		return false

	return TimeManager.current_day >= event_data.start_day and TimeManager.current_day <= event_data.end_day


func _meets_weather_requirements(event_data: MarketEventData) -> bool:
	if not event_data.requires_weather_history:
		return true

	if event_data.required_dry_days > 0:
		if WeatherManager.get_consecutive_recent_dry_days() < event_data.required_dry_days:
			return false

	if event_data.required_rain_days > 0:
		if WeatherManager.get_rainy_days_in_recent_days(WEATHER_RAIN_LOOKBACK_DAYS) < event_data.required_rain_days:
			return false

	return true


func _meets_temperature_requirements(event_data: MarketEventData) -> bool:
	if not event_data.requires_temperature:
		return true

	var temperature := WeatherManager.get_current_day_base_temperature()

	return temperature >= event_data.minimum_temperature and temperature <= event_data.maximum_temperature


func _can_trigger_fixed_date_event(event_data: MarketEventData) -> bool:
	if event_data.trigger_mode != MarketEventData.TriggerMode.FIXED_DATE:
		return true

	return not triggered_fixed_event_keys.has(_get_fixed_date_event_key(event_data))


func _mark_fixed_date_event_triggered(event_data: MarketEventData) -> void:
	if event_data == null:
		return

	triggered_fixed_event_keys[_get_fixed_date_event_key(event_data)] = true


func _get_fixed_date_event_key(event_data: MarketEventData) -> String:
	return "%s:%d" % [event_data.event_id, TimeManager.current_year]


func create_calendar_event_state_save_data() -> Dictionary:
	return triggered_fixed_event_keys.duplicate(true)


func apply_calendar_event_state_save_data(save_data: Dictionary) -> void:
	triggered_fixed_event_keys.clear()

	for key in save_data.keys():
		triggered_fixed_event_keys[String(key)] = bool(save_data[key])


func create_daily_event_limit_save_data() -> Dictionary:
	_update_daily_event_limit_key()

	return {
		"date_key": _events_started_today_key,
		"started_count": _events_started_today
	}


func apply_daily_event_limit_save_data(save_data: Dictionary) -> void:
	_events_started_today_key = String(save_data.get("date_key", ""))
	_events_started_today = clampi(
		int(save_data.get("started_count", 0)),
		0,
		MAX_EVENTS_STARTED_PER_DAY
	)
	_update_daily_event_limit_key()


func _validate_possible_market_events() -> void:
	var seen_ids := {}

	for event_data in possible_market_events:
		if event_data == null:
			push_warning("EventManager: null event in possible_market_events")
			continue

		if event_data.event_id == "":
			push_warning("EventManager: event without event_id: %s" % event_data.display_name)
		elif seen_ids.has(event_data.event_id):
			push_warning("EventManager: duplicate event_id: %s" % event_data.event_id)
		else:
			seen_ids[event_data.event_id] = true

		if event_data.requires_season and event_data.required_seasons.is_empty():
			push_warning("EventManager: event %s requires season but has no seasons" % event_data.event_id)

		if event_data.requires_day_range:
			if event_data.start_day < 1 or event_data.end_day > TimeManager.DAYS_PER_MONTH or event_data.start_day > event_data.end_day:
				push_warning("EventManager: invalid day range for event %s" % event_data.event_id)

		if event_data.buy_price_multiplier < 0.0:
			push_warning("EventManager: negative buy price multiplier for event %s" % event_data.event_id)

		if event_data.trend_strength_modifier != 0.0 or event_data.volatility_modifier != 0.0:
			if event_data.get_affected_items().is_empty():
				push_warning("EventManager: event %s modifies market but has no affected products" % event_data.event_id)
