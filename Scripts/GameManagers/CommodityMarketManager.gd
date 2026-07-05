extends Node

signal commodity_prices_updated

var commodities: Array[CommodityData] = [
	preload("res://Data/Economy/Commodities/beetroot_commodity.tres"),
	preload("res://Data/Economy/Commodities/cabbage_commodity.tres"),
	preload("res://Data/Economy/Commodities/carrot_commodity.tres"),
	preload("res://Data/Economy/Commodities/corn_commodity.tres"),
	preload("res://Data/Economy/Commodities/lettuce_commodity.tres"),
	preload("res://Data/Economy/Commodities/potatoe_commodity.tres"),
	preload("res://Data/Economy/Commodities/pumpkin_commodity.tres"),
	preload("res://Data/Economy/Commodities/strawberry_commodity.tres"),
	preload("res://Data/Economy/Commodities/tomatoe_commodity.tres"),
	preload("res://Data/Economy/Commodities/wheat_commodity.tres")
]

const MARKET_OPEN_HOUR := 9
const MARKET_CLOSE_HOUR := 17

var last_processed_day := -1
var last_processed_hour := -1
var _base_volatility_by_item_id: Dictionary = {}
var _base_trend_strength_by_item_id: Dictionary = {}
var _event_direction_by_item_id: Dictionary = {}
var _event_trend_strength_by_item_id: Dictionary = {}
var _event_volatility_by_item_id: Dictionary = {}

func update_market(log_time: String = "") -> void:
	if log_time.is_empty():
		log_time = TimeManager.get_time_string()

	for commodity in commodities:
		_update_commodity_price(commodity, log_time)

	commodity_prices_updated.emit()
	print("[CommodityMarket] Prices updated signal emitted at %s" % log_time)

func simulate_skipped_market_hours(from_day: int, from_hour: int, to_day: int, to_hour: int) -> void:
	if from_day != to_day:
		_simulate_day_hours(from_day, from_hour + 1, MARKET_CLOSE_HOUR)
		return

	_simulate_day_hours(from_day, from_hour + 1, mini(to_hour, MARKET_CLOSE_HOUR))


func _simulate_day_hours(day: int, start_hour: int, end_hour: int) -> void:
	for hour in range(maxi(start_hour, MARKET_OPEN_HOUR), end_hour + 1):
		if last_processed_day == day and last_processed_hour == hour:
			continue

		last_processed_day = day
		last_processed_hour = hour

		var log_time := "%02d:00" % hour
		print("[CommodityMarket] Simulating skipped market update for day %d at %s" % [day, log_time])
		update_market(log_time)


func _update_commodity_price(commodity: CommodityData, log_time: String) -> void:
	if commodity == null:
		return

	var old_price := commodity.current_price

	var change_percent := randf_range(
		-commodity.volatility,
		commodity.volatility
	)

	match commodity.trend:
		CommodityData.MarketTrend.BEARISH:
			change_percent -= commodity.trend_strength

		CommodityData.MarketTrend.BULLISH:
			change_percent += commodity.trend_strength

		CommodityData.MarketTrend.NEUTRAL:
			pass

	var new_price := commodity.current_price
	new_price *= (1.0 + change_percent)

	var min_price := commodity.base_price * commodity.min_price_multiplier
	var max_price := commodity.base_price * commodity.max_price_multiplier

	new_price = clampf(
		new_price,
		min_price,
		max_price
	)

	commodity.current_price = snappedf(new_price, 0.01)
	var item_name := "unknown"
	var item_id := "unknown"

	if commodity.item_data:
		item_name = commodity.item_data.display_name
		item_id = commodity.item_data.id

	print(
		"[CommodityMarket] %s %s (%s): %.2f -> %.2f, displayed sell price: %d, change: %.2f%%" % [
			log_time,
			item_name,
			item_id,
			old_price,
			commodity.current_price,
			int(round(commodity.current_price)),
			change_percent * 100.0
		]
	)

	commodity.price_history.append(
		commodity.current_price
	)
	commodity.price_history_labels.append(_get_history_label(log_time))

	if commodity.price_history.size() > 30:
		commodity.price_history.pop_front()
		if not commodity.price_history_labels.is_empty():
			commodity.price_history_labels.pop_front()

func _ready() -> void:
	_capture_base_market_values()
	_initialize_price_history()
	TimeManager.time_changed.connect(_on_time_changed)


func _capture_base_market_values() -> void:
	_base_volatility_by_item_id.clear()
	_base_trend_strength_by_item_id.clear()

	for commodity in commodities:
		if commodity == null or commodity.item_data == null:
			continue

		_base_volatility_by_item_id[commodity.item_data.id] = commodity.volatility
		_base_trend_strength_by_item_id[commodity.item_data.id] = commodity.trend_strength


func _ensure_base_market_values() -> void:
	if _base_volatility_by_item_id.is_empty() or _base_trend_strength_by_item_id.is_empty():
		_capture_base_market_values()


func _initialize_price_history() -> void:
	for commodity in commodities:
		if commodity == null:
			continue

		if commodity.price_history.is_empty():
			commodity.price_history.append(commodity.current_price)

		if commodity.price_history_labels.is_empty():
			commodity.price_history_labels.append(_get_history_label(TimeManager.get_time_string()))

		while commodity.price_history_labels.size() < commodity.price_history.size():
			commodity.price_history_labels.append(_get_history_label(TimeManager.get_time_string()))

func _on_time_changed() -> void:
	var current_day := TimeManager.current_day
	var current_hour := TimeManager.get_hour()

	if current_hour < MARKET_OPEN_HOUR:
		return

	if current_hour > MARKET_CLOSE_HOUR:
		return

	if last_processed_day == current_day and last_processed_hour == current_hour:
		return

	last_processed_day = current_day
	last_processed_hour = current_hour

	var log_time := TimeManager.get_time_string()
	print("[CommodityMarket] Updating market for day %d at %s" % [current_day, log_time])
	update_market(log_time)

func get_commodity_for_item(item_data: ItemData) -> CommodityData:
	if item_data == null:
		return null

	for commodity in commodities:
		if commodity == null:
			continue

		if commodity.item_data == item_data or commodity.item_data.id == item_data.id:
			return commodity

	return null

func has_commodity(item_data: ItemData) -> bool:
	return get_commodity_for_item(item_data) != null

func get_current_price(item_data: ItemData) -> int:
	var commodity := get_commodity_for_item(item_data)

	if commodity == null:
		return 0

	return int(round(commodity.current_price))

func _get_history_label(time_string: String) -> String:
	return "%s %s" % [TimeManager.get_date_string(), time_string]

func reset_event_modifiers() -> void:
	_ensure_base_market_values()
	_event_direction_by_item_id.clear()
	_event_trend_strength_by_item_id.clear()
	_event_volatility_by_item_id.clear()

	for commodity in commodities:
		if commodity == null:
			continue

		commodity.trend = CommodityData.MarketTrend.NEUTRAL
		if commodity.item_data != null:
			commodity.trend_strength = float(_base_trend_strength_by_item_id.get(
				commodity.item_data.id,
				commodity.trend_strength
			))
			commodity.volatility = float(_base_volatility_by_item_id.get(
				commodity.item_data.id,
				commodity.volatility
			))

func apply_event_modifier(event_data: MarketEventData) -> void:
	if event_data == null:
		return

	_ensure_base_market_values()

	for item in event_data.get_affected_items():
		var commodity := get_commodity_for_item(item)

		if commodity == null or commodity.item_data == null:
			continue

		var item_id := commodity.item_data.id
		var direction := float(_event_direction_by_item_id.get(item_id, 0.0))

		match event_data.trend_effect:
			CommodityData.MarketTrend.BULLISH:
				direction += event_data.trend_strength_modifier
			CommodityData.MarketTrend.BEARISH:
				direction -= event_data.trend_strength_modifier
			CommodityData.MarketTrend.NEUTRAL:
				pass

		_event_direction_by_item_id[item_id] = direction
		_event_trend_strength_by_item_id[item_id] = (
			float(_event_trend_strength_by_item_id.get(item_id, 0.0))
			+ event_data.trend_strength_modifier
		)
		_event_volatility_by_item_id[item_id] = (
			float(_event_volatility_by_item_id.get(item_id, 0.0))
			+ event_data.volatility_modifier
		)

		_apply_runtime_values_to_commodity(commodity)


func _apply_runtime_values_to_commodity(commodity: CommodityData) -> void:
	if commodity == null or commodity.item_data == null:
		return

	var item_id := commodity.item_data.id
	var direction := float(_event_direction_by_item_id.get(item_id, 0.0))
	var base_strength := float(_base_trend_strength_by_item_id.get(item_id, commodity.trend_strength))
	var base_volatility := float(_base_volatility_by_item_id.get(item_id, commodity.volatility))

	if direction > 0.0001:
		commodity.trend = CommodityData.MarketTrend.BULLISH
	elif direction < -0.0001:
		commodity.trend = CommodityData.MarketTrend.BEARISH
	else:
		commodity.trend = CommodityData.MarketTrend.NEUTRAL

	commodity.trend_strength = base_strength + float(_event_trend_strength_by_item_id.get(item_id, 0.0))
	commodity.volatility = maxf(0.0, base_volatility + float(_event_volatility_by_item_id.get(item_id, 0.0)))
