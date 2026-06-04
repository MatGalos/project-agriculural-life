extends Resource
class_name InventoryData

signal inventory_changed

@export var slot_count: int = 24
@export var slots: Array[InventorySlot] = []


func setup() -> void:
	slot_count = maxi(slot_count, 0)

	while slots.size() < slot_count:
		slots.append(InventorySlot.new())

	while slots.size() > slot_count:
		slots.pop_back()

	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = InventorySlot.new()


func get_slot(index: int) -> InventorySlot:
	setup()

	if index < 0 or index >= slots.size():
		return null

	return slots[index]


func clear_inventory() -> void:
	setup()

	for slot in slots:
		slot.clear()

	inventory_changed.emit()


func add_item(item_data: ItemData, amount: int) -> int:
	if item_data == null or amount <= 0:
		return amount

	setup()
	var remaining := amount

	for slot in slots:
		if slot.can_stack_with(item_data):
			remaining = slot.add_to_stack(remaining)

			if remaining <= 0:
				inventory_changed.emit()
				return 0

	for slot in slots:
		if slot.is_empty():
			slot.item_data = item_data
			slot.amount = mini(remaining, item_data.max_stack)
			remaining -= slot.amount

			if remaining <= 0:
				inventory_changed.emit()
				return 0

	if remaining != amount:
		inventory_changed.emit()

	return remaining


func get_item_count(item_data: ItemData) -> int:
	if item_data == null:
		return 0

	setup()
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

	setup()

	if not has_item(item_data, amount):
		return false

	var remaining := amount

	for slot in slots:
		if slot.is_empty() or slot.item_data != item_data:
			continue

		var amount_to_remove := mini(slot.amount, remaining)
		slot.amount -= amount_to_remove
		remaining -= amount_to_remove

		if slot.amount <= 0:
			slot.clear()

		if remaining <= 0:
			inventory_changed.emit()
			return true

	inventory_changed.emit()
	return true


func move_or_merge_slot(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return

	var from_slot := get_slot(from_index)
	var to_slot := get_slot(to_index)

	if from_slot == null or to_slot == null or from_slot.is_empty():
		return

	if to_slot.is_empty():
		_move_slot_contents(from_slot, to_slot)
		inventory_changed.emit()
		return

	if to_slot.item_data == from_slot.item_data:
		var amount_to_move := mini(from_slot.amount, to_slot.get_space_left())

		if amount_to_move <= 0:
			return

		to_slot.amount += amount_to_move
		from_slot.amount -= amount_to_move

		if from_slot.amount <= 0:
			from_slot.clear()

		inventory_changed.emit()
		return

	_swap_slot_contents(from_slot, to_slot)
	inventory_changed.emit()


func _move_slot_contents(from_slot: InventorySlot, to_slot: InventorySlot) -> void:
	to_slot.item_data = from_slot.item_data
	to_slot.amount = from_slot.amount
	from_slot.clear()


func _swap_slot_contents(first_slot: InventorySlot, second_slot: InventorySlot) -> void:
	var temp_item := second_slot.item_data
	var temp_amount := second_slot.amount

	second_slot.item_data = first_slot.item_data
	second_slot.amount = first_slot.amount

	first_slot.item_data = temp_item
	first_slot.amount = temp_amount
