extends Node

var price_data_list: Array[ItemPriceData] = [
	preload("res://Data/Economy/Prices/wheat_price.tres"),
	preload("res://Data/Economy/Prices/wheat_seed_price.tres")
]

var prices_by_item_id: Dictionary = {}


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

	if price_data == null:
		return item_data.base_price

	return price_data.buy_price


func get_sell_price(item_data: ItemData) -> int:
	if item_data == null:
		return 0

	if CommodityMarketManager.has_commodity(item_data):
		return CommodityMarketManager.get_current_price(item_data)

	var price_data: ItemPriceData = prices_by_item_id.get(item_data.id, null)

	if price_data == null:
		return item_data.base_price

	return price_data.sell_price
