extends Resource
class_name HotbarData

@export var hotbar_size: int = 5
@export var inventory_slot_indexes: Array[int] = [0, 1, 2, 3, 4]
@export var selected_slot_index: int = 0


func setup() -> void:
	hotbar_size = maxi(hotbar_size, 0)

	while inventory_slot_indexes.size() < hotbar_size:
		inventory_slot_indexes.append(inventory_slot_indexes.size())

	while inventory_slot_indexes.size() > hotbar_size:
		inventory_slot_indexes.pop_back()

	if hotbar_size <= 0:
		selected_slot_index = 0
	else:
		selected_slot_index = clampi(selected_slot_index, 0, hotbar_size - 1)


func select_slot(index: int) -> void:
	setup()

	if index < 0 or index >= hotbar_size:
		return

	selected_slot_index = index


func get_selected_inventory_slot_index() -> int:
	setup()

	if inventory_slot_indexes.is_empty():
		return -1

	return inventory_slot_indexes[selected_slot_index]


func get_inventory_slot_index(hotbar_index: int) -> int:
	setup()

	if hotbar_index < 0 or hotbar_index >= inventory_slot_indexes.size():
		return -1

	return inventory_slot_indexes[hotbar_index]
