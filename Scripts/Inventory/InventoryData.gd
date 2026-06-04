extends Resource
class_name InventoryData

@export var slot_count: int = 24
@export var slots: Array[InventorySlot] = []


func setup() -> void:
	if slots.size() == slot_count:
		return

	slots.clear()

	for i in range(slot_count):
		var slot := InventorySlot.new()
		slots.append(slot)


func get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= slots.size():
		return null

	return slots[index]


func clear_inventory() -> void:
	for slot in slots:
		slot.clear()

func add_item(item_data: ItemData, amount: int) -> int:
	if item_data == null or amount <= 0:
		return amount

	var remaining := amount

	for slot in slots:
		if slot.can_stack_with(item_data):
			remaining = slot.add_to_stack(remaining)

			if remaining <= 0:
				return 0

	for slot in slots:
		if slot.is_empty():
			slot.item_data = item_data
			slot.amount = mini(remaining, item_data.max_stack)
			remaining -= slot.amount

			if remaining <= 0:
				return 0

	return remaining
