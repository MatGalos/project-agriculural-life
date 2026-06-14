extends Control
class_name StoragePanel

@export var storage_data: StorageData
@export var row_scene: PackedScene
@export var player_inventory: InventoryData

@onready var storage_items_container: VBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/StorageColumn/StorageItemsContainer
@onready var inventory_items_container: VBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/InventoryColumn/InventoryItemsContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("storage_panel")

	if storage_data and not storage_data.storage_changed.is_connected(refresh):
		storage_data.storage_changed.connect(refresh)

	if player_inventory and not player_inventory.inventory_changed.is_connected(refresh):
		player_inventory.inventory_changed.connect(refresh)

	refresh()


func open() -> void:
	refresh()
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close() -> void:
	visible = false

	if gamemanager.isInGame and not gamemanager.isPaused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func refresh() -> void:
	if storage_data == null or row_scene == null:
		return

	_clear_container(storage_items_container)
	_clear_container(inventory_items_container)
	_refresh_storage_items()
	_refresh_inventory_items()
	_refresh_hotbar()


func transfer_from_inventory_slot(slot_index: int) -> void:
	_transfer_inventory_to_storage(slot_index)


func is_open() -> bool:
	return visible


func can_accept_transfer_drop(target_type: String, data: Variant) -> bool:
	if not _is_transfer_payload(data):
		return false

	var source := String((data as Dictionary).get("source", ""))
	return source != "" and source != target_type


func drop_transfer_to(target_type: String, data: Variant) -> void:
	if not can_accept_transfer_drop(target_type, data):
		return

	var payload := data as Dictionary
	var source := String(payload.get("source", ""))

	if source == "storage" and target_type == "inventory":
		_transfer_storage_to_inventory(payload.get("item_data") as ItemData)
	elif source == "inventory" and target_type == "storage":
		_transfer_inventory_to_storage(int(payload.get("inventory_slot_index", -1)))


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return _is_transfer_payload(data)


func _drop_data(position: Vector2, data: Variant) -> void:
	if not _can_drop_data(position, data):
		return

	var payload := data as Dictionary
	var source := String(payload.get("source", ""))
	var target := "storage" if position.x < size.x * 0.5 else "inventory"

	if source == target:
		return

	if source == "storage" and target == "inventory":
		_transfer_storage_to_inventory(payload.get("item_data") as ItemData)
	elif source == "inventory" and target == "storage":
		_transfer_inventory_to_storage(int(payload.get("inventory_slot_index", -1)))


func _refresh_storage_items() -> void:
	for item_entry in storage_data.get_all_items():
		var row := _create_row(
			item_entry["item_data"],
			int(item_entry["amount"]),
			"storage",
			-1
		)

		if row:
			storage_items_container.add_child(row)


func _refresh_inventory_items() -> void:
	if player_inventory == null:
		return

	player_inventory.setup()

	for i in range(player_inventory.slots.size()):
		var slot := player_inventory.slots[i]

		if slot == null or slot.is_empty():
			continue

		var row := _create_row(slot.item_data, slot.amount, "inventory", i)

		if row:
			inventory_items_container.add_child(row)


func _create_row(item_data: ItemData, amount: int, source_type: String, inventory_slot_index: int) -> StorageItemRow:
	var row := row_scene.instantiate() as StorageItemRow

	if row == null:
		return null

	row.setup(item_data, amount, source_type, inventory_slot_index)
	row.transfer_requested.connect(_on_row_transfer_requested)
	row.item_dropped.connect(_on_row_item_dropped)
	return row


func _on_row_transfer_requested(row: StorageItemRow) -> void:
	if row == null:
		return

	if row.source_type == "storage":
		_transfer_storage_to_inventory(row.item_data)
	elif row.source_type == "inventory":
		_transfer_inventory_to_storage(row.inventory_slot_index)


func _on_row_item_dropped(target_row: StorageItemRow, payload: Dictionary) -> void:
	if target_row == null:
		return

	drop_transfer_to(target_row.source_type, payload)


func _transfer_inventory_to_storage(slot_index: int) -> void:
	if player_inventory == null or storage_data == null:
		return

	var slot := player_inventory.get_slot(slot_index)

	if slot == null or slot.is_empty():
		return

	var item_data := slot.item_data
	var amount := slot.amount

	slot.clear()
	player_inventory.inventory_changed.emit()
	storage_data.add_item(item_data, amount)
	refresh()


func _transfer_storage_to_inventory(item_data: ItemData) -> void:
	if player_inventory == null or storage_data == null or item_data == null:
		return

	var stored_amount := storage_data.get_item_amount(item_data)
	var amount_to_transfer := mini(item_data.max_stack, stored_amount)

	if amount_to_transfer <= 0:
		return

	var remaining := player_inventory.add_item(item_data, amount_to_transfer)
	var moved_amount := amount_to_transfer - remaining

	if moved_amount <= 0:
		return

	storage_data.remove_item(item_data, moved_amount)
	refresh()


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


func _refresh_hotbar() -> void:
	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")

	if hotbar_ui and hotbar_ui.has_method("refresh"):
		hotbar_ui.refresh()


func _is_transfer_payload(data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and (data as Dictionary).get("type", "") == "storage_transfer_item"
