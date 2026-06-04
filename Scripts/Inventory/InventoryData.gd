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
