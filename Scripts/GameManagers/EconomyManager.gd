extends Node

signal buy_prices_changed

var price_data_list: Array[ItemPriceData] = [
	preload("res://Data/Economy/Prices/beetroot_price.tres"),
	preload("res://Data/Economy/Prices/beetroot_seed_price.tres"),
	preload("res://Data/Economy/Prices/cabbage_price.tres"),
	preload("res://Data/Economy/Prices/cabbage_seed_price.tres"),
	preload("res://Data/Economy/Prices/carrot_price.tres"),
	preload("res://Data/Economy/Prices/carrot_seed_price.tres"),
	preload("res://Data/Economy/Prices/corn_price.tres"),
	preload("res://Data/Economy/Prices/corn_seed_price.tres"),
	preload("res://Data/Economy/Prices/lettuce_price.tres"),
	preload("res://Data/Economy/Prices/lettuce_seed_price.tres"),
	preload("res://Data/Economy/Prices/potatoe_price.tres"),
	preload("res://Data/Economy/Prices/potatoe_seed_price.tres"),
	preload("res://Data/Economy/Prices/pumpkin_price.tres"),
	preload("res://Data/Economy/Prices/pumpkin_seed_price.tres"),
	preload("res://Data/Economy/Prices/strawberry_price.tres"),
	preload("res://Data/Economy/Prices/strawberry_seed_price.tres"),
	preload("res://Data/Economy/Prices/tomatoe_price.tres"),
	preload("res://Data/Economy/Prices/tomatoe_seed_price.tres"),
	preload("res://Data/Economy/Prices/wheat_price.tres"),
	preload("res://Data/Economy/Prices/wheat_seed_price.tres")
]

var prices_by_item_id: Dictionary = {}
var buy_price_multipliers_by_item_id: Dictionary = {}


func _ready() -> void:
	_register_prices()


func _register_prices() -> void:
	prices_by_item_id.clear()

	for price_data in price_data_list:
		if price_data == null:
			continue

		if price_data.item_data == null:
			continue

		prices_by_item_id[price_data.item_data.id] = price_data


func get_buy_price(item_data: ItemData) -> int:
	if item_data == null:
		return 0

	var price_data: ItemPriceData = prices_by_item_id.get(item_data.id, null)
	var base_price := item_data.base_price

	if price_data == null:
		base_price = item_data.base_price
	else:
		base_price = price_data.buy_price

	var multiplier := float(buy_price_multipliers_by_item_id.get(item_data.id, 1.0))
	var final_price := float(base_price) * multiplier

	return maxi(0, int(round(final_price)))


func get_sell_price(item_data: ItemData) -> int:
	if item_data == null:
		return 0

	if CommodityMarketManager.has_commodity(item_data):
		return CommodityMarketManager.get_current_price(item_data)

	var price_data: ItemPriceData = prices_by_item_id.get(item_data.id, null)

	if price_data == null:
		return item_data.base_price

	return price_data.sell_price


func reset_buy_price_modifiers() -> void:
	buy_price_multipliers_by_item_id.clear()
	buy_prices_changed.emit()


func apply_buy_price_event_modifier(event_data: MarketEventData) -> void:
	if event_data == null or not event_data.affects_buy_prices:
		return

	var multiplier := maxf(event_data.buy_price_multiplier, 0.0)

	for item in event_data.get_affected_buy_price_items():
		var current_multiplier := float(buy_price_multipliers_by_item_id.get(item.id, 1.0))
		buy_price_multipliers_by_item_id[item.id] = current_multiplier * multiplier

	buy_prices_changed.emit()
