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
