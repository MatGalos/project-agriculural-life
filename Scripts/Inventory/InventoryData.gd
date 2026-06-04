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

func get_item_count(item_data: ItemData) -> int:
	if item_data == null:
		return 0

	var total := 0

	for slot in slots:
		if not slot.is_empty() and slot.item_data == item_data:
			total += slot.amount

	return total


func has_item(item_data: ItemData, amount: int) -> bool:
	return get_item_count(item_data) >= amount


func remove_item(item_data: ItemData, amount: int) -> bool:
	if item_data == null or amount <= 0:
		return false

	if not has_item(item_data, amount):
		return false

	var remaining := amount

	for slot in slots:
		if slot.is_empty():
			continue

		if slot.item_data != item_data:
			continue

		var amount_to_remove := mini(slot.amount, remaining)
		slot.amount -= amount_to_remove
		remaining -= amount_to_remove

		if slot.amount <= 0:
			slot.clear()

		if remaining <= 0:
			return true

	return true

func move_or_merge_slot(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return

	var from_slot := get_slot(from_index)
	var to_slot := get_slot(to_index)

	if from_slot == null or to_slot == null:
		return

	if from_slot.is_empty():
		return

	# Target pusty → przenieś cały slot
	if to_slot.is_empty():
		to_slot.item_data = from_slot.item_data
		to_slot.amount = from_slot.amount
		from_slot.clear()
		return

	# Ten sam item → spróbuj połączyć stacki
	if to_slot.item_data == from_slot.item_data:
		var space_left := to_slot.item_data.max_stack - to_slot.amount
		var amount_to_move := mini(from_slot.amount, space_left)

		to_slot.amount += amount_to_move
		from_slot.amount -= amount_to_move

		if from_slot.amount <= 0:
			from_slot.clear()

		return

	# Inny item → zamień miejscami
	var temp_item := to_slot.item_data
	var temp_amount := to_slot.amount

	to_slot.item_data = from_slot.item_data
	to_slot.amount = from_slot.amount

	from_slot.item_data = temp_item
	from_slot.amount = temp_amount
