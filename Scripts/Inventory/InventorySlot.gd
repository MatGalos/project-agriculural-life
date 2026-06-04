extends Resource
class_name InventorySlot

@export var item_data: ItemData
@export var amount: int = 0


func is_empty() -> bool:
	return item_data == null or amount <= 0


func clear() -> void:
	item_data = null
	amount = 0


func can_stack_with(item: ItemData) -> bool:
	if is_empty():
		return false

	return item_data == item and amount < item_data.max_stack


func get_space_left() -> int:
	if is_empty():
		return 0

	return item_data.max_stack - amount


func add_to_stack(add_amount: int) -> int:
	if is_empty():
		return add_amount

	var space_left := get_space_left()
	var amount_to_add := mini(add_amount, space_left)

	amount += amount_to_add

	return add_amount - amount_to_add
