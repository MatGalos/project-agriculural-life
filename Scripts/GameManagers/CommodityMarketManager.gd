extends Node

signal commodity_prices_updated

var commodities: Array[CommodityData] = [
	preload("res://Data/Economy/Commodities/wheat_commodity.tres")
]

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
	for i in range(5):
		update_market()

	var wheat = commodities[0]

	print("Current wheat price: ", wheat.current_price)
	print("History: ", wheat.price_history)
