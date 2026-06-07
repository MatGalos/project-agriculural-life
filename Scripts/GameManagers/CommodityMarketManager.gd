extends Node

signal commodity_prices_updated

var commodities: Array[CommodityData] = [
	preload("res://Data/Economy/Commodities/wheat_commodity.tres")
]

const MARKET_OPEN_HOUR := 9
const MARKET_CLOSE_HOUR := 17

var last_processed_day := -1
var last_processed_hour := -1

func update_market() -> void:
	for commodity in commodities:
		_update_commodity_price(commodity)

	commodity_prices_updated.emit()

func _update_commodity_price(commodity: CommodityData) -> void:
	if commodity == null:
		return

	var change_percent := randf_range(
		-commodity.volatility,
		commodity.volatility
	)

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

	update_market()

	print("Market updated at: ", TimeManager.get_time_string())
