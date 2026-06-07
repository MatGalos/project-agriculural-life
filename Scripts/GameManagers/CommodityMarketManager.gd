extends Node

signal commodity_prices_updated

var commodities: Array[CommodityData] = [
	preload("res://Data/Economy/Commodities/wheat_commodity.tres")
]

const MARKET_OPEN_HOUR := 9
const MARKET_CLOSE_HOUR := 17

var last_processed_day := -1
var last_processed_hour := -1

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

	if commodity.price_history.size() > 30:
		commodity.price_history.pop_front()

func _ready() -> void:
	TimeManager.time_changed.connect(_on_time_changed)

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
