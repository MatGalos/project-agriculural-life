extends Resource
class_name StorageData

signal storage_changed

@export var stored_items: Dictionary = {}
@export var item_database: Array[ItemData] = []


func add_item(item_data: ItemData, amount: int) -> void:
	if item_data == null or amount <= 0:
		return

	if get_item_by_id(item_data.id) == null:
		item_database.append(item_data)

	var item_id := item_data.id

	if not stored_items.has(item_id):
		stored_items[item_id] = 0

	stored_items[item_id] += amount
	storage_changed.emit()


func remove_item(item_data: ItemData, amount: int) -> bool:
	if item_data == null or amount <= 0:
		return false

	var item_id := item_data.id

	if not stored_items.has(item_id):
		return false

	if stored_items[item_id] < amount:
		return false

	stored_items[item_id] -= amount

	if stored_items[item_id] <= 0:
		stored_items.erase(item_id)

	storage_changed.emit()
	return true


func has_item(item_data: ItemData, amount: int) -> bool:
	return get_item_amount(item_data) >= amount


func get_item_amount(item_data: ItemData) -> int:
	if item_data == null:
		return 0

	return int(stored_items.get(item_data.id, 0))


func get_item_by_id(item_id: String) -> ItemData:
	for item in item_database:
		if item != null and item.id == item_id:
			return item

	return null


func get_all_items() -> Array:
	var result := []

	for item_id in stored_items.keys():
		var item_data := get_item_by_id(item_id)

		if item_data == null:
			continue

		result.append({
			"item_data": item_data,
			"amount": stored_items[item_id]
		})

	return result
