extends Node

signal selected_slot_changed(slot_index: int)
signal selected_item_changed(item_data: ItemData)

var inventory_data: InventoryData = preload("res://Data/Inventory/player_inventory.tres")
var hotbar_data: HotbarData = preload("res://Data/Inventory/player_hotbar.tres")
var selected_slot: int = 1


func _ready() -> void:
	if inventory_data:
		inventory_data.setup()

	if hotbar_data:
		hotbar_data.setup()


func _process(_delta: float) -> void:
	var pressed_slot: int = InputManager.get_pressed_hotbar_slot()

	if pressed_slot != -1:
		select_slot(pressed_slot)


func select_slot(slot_index: int) -> void:
	if hotbar_data == null:
		return

	hotbar_data.setup()

	if slot_index < 1 or slot_index > hotbar_data.hotbar_size:
		return

	var zero_based_index := slot_index - 1

	if selected_slot == slot_index:
		return

	selected_slot = slot_index
	hotbar_data.select_slot(zero_based_index)

	selected_slot_changed.emit(selected_slot)
	selected_item_changed.emit(get_selected_item())


func get_selected_slot() -> int:
	return selected_slot

func get_selected_item() -> ItemData:
	if inventory_data == null or hotbar_data == null:
		return null

	var inventory_index := hotbar_data.get_selected_inventory_slot_index()
	var slot := inventory_data.get_slot(inventory_index)

	if slot == null or slot.is_empty():
		return null

	return slot.item_data
