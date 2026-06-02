extends Node

signal selected_slot_changed(slot_index: int)

var selected_slot: int = 1

func _process(_delta: float) -> void:
	var pressed_slot: int = InputManager.get_pressed_hotbar_slot()

	if pressed_slot != -1:
		select_slot(pressed_slot)


func select_slot(slot_index: int) -> void:
	if slot_index < 1 or slot_index > 5:
		return

	if selected_slot == slot_index:
		return

	selected_slot = slot_index
	selected_slot_changed.emit(selected_slot)


func get_selected_slot() -> int:
	return selected_slot
