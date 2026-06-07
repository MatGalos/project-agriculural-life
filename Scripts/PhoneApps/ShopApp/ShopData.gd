extends Resource
class_name ShopData

@export var items: Array[ShopItemData] = []


func get_available_items() -> Array[ShopItemData]:
	var result: Array[ShopItemData] = []

	for item in items:
		if item != null and item.is_available:
			result.append(item)

	return result
