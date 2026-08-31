extends Control
class_name StoragePanel

signal close_requested

const BASE_PANEL_SIZE := Vector2(680.0, 460.0)
const VIEWPORT_SAFE_MARGIN := Vector2(48.0, 48.0)
const MIN_RESPONSIVE_SCALE := 0.5

@export var storage_data: StorageData
@export var row_scene: PackedScene
@export var player_inventory: InventoryData

@onready var inventory_items_container: VBoxContainer = $PanelContainer/MarginContainer/ContentContainer/ColumnsContainer/InventoryColumnPanel/InventoryColumn/InventoryScroll/ListMargin/InventoryItemsContainer
@onready var storage_items_container: VBoxContainer = $PanelContainer/MarginContainer/ContentContainer/ColumnsContainer/StorageColumnPanel/StorageColumn/StorageScroll/ListMargin/StorageItemsContainer
@onready var inventory_scroll: ScrollContainer = $PanelContainer/MarginContainer/ContentContainer/ColumnsContainer/InventoryColumnPanel/InventoryColumn/InventoryScroll
@onready var storage_scroll: ScrollContainer = $PanelContainer/MarginContainer/ContentContainer/ColumnsContainer/StorageColumnPanel/StorageColumn/StorageScroll
@onready var hint_label: Label = $PanelContainer/MarginContainer/ContentContainer/FooterContainer/HintLabel
@onready var close_button: Button = $PanelContainer/MarginContainer/ContentContainer/FooterContainer/CloseButton

var _inventory_scroll_line: OptionsScrollLine
var _storage_scroll_line: OptionsScrollLine


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("storage_panel")
	get_viewport().size_changed.connect(_apply_responsive_layout)
	resized.connect(_position_scroll_lines_deferred)

	if not GraphicsSettingsManager.interface_scale_changed.is_connected(_on_interface_scale_changed):
		GraphicsSettingsManager.interface_scale_changed.connect(_on_interface_scale_changed)

	if storage_data and not storage_data.storage_changed.is_connected(refresh):
		storage_data.storage_changed.connect(refresh)

	if player_inventory and not player_inventory.inventory_changed.is_connected(refresh):
		player_inventory.inventory_changed.connect(refresh)

	if close_button and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)

	_inventory_scroll_line = _create_scroll_line(inventory_scroll, "InventoryScrollLine")
	_storage_scroll_line = _create_scroll_line(storage_scroll, "StorageScrollLine")
	_apply_responsive_layout()
	refresh()


func open() -> void:
	_apply_responsive_layout()
	refresh()
	_update_hint("Click or drag an item to transfer it.")
	visible = true
	_position_scroll_lines_deferred()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close() -> void:
	visible = false

	if gamemanager.isInGame and not gamemanager.isPaused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_close_button_pressed() -> void:
	close_requested.emit()


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
	_position_scroll_lines_deferred()


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
		UISoundManager.play_action_error()
		_update_hint("Cannot transfer item.")
		return

	var payload := data as Dictionary
	var source := String(payload.get("source", ""))

	if source == "storage" and target_type == "inventory":
		_transfer_storage_to_inventory(payload.get("item_data") as ItemData)
	elif source == "inventory" and target_type == "storage":
		_transfer_inventory_to_storage(int(payload.get("inventory_slot_index", -1)))
	else:
		UISoundManager.play_action_error()
		_update_hint("Cannot transfer item.")


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return _is_transfer_payload(data)


func _drop_data(drop_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(drop_position, data):
		UISoundManager.play_action_error()
		_update_hint("Cannot transfer item.")
		return

	var payload := data as Dictionary
	var source := String(payload.get("source", ""))
	var target := "storage" if drop_position.x < size.x * 0.5 else "inventory"

	if source == target:
		UISoundManager.play_action_error()
		_update_hint("Cannot transfer item.")
		return

	if source == "storage" and target == "inventory":
		_transfer_storage_to_inventory(payload.get("item_data") as ItemData)
	elif source == "inventory" and target == "storage":
		_transfer_inventory_to_storage(int(payload.get("inventory_slot_index", -1)))
	else:
		UISoundManager.play_action_error()
		_update_hint("Cannot transfer item.")


func _refresh_storage_items() -> void:
	var has_items := false

	for item_entry in storage_data.get_all_items():
		var row := _create_row(
			item_entry["item_data"],
			int(item_entry["amount"]),
			"storage",
			-1
		)

		if row:
			storage_items_container.add_child(row)
			has_items = true

	if not has_items:
		_add_empty_state(storage_items_container, "Empty Storage")


func _refresh_inventory_items() -> void:
	if player_inventory == null:
		return

	player_inventory.setup()
	var has_items := false

	for i in range(player_inventory.slots.size()):
		var slot := player_inventory.slots[i]

		if slot == null or slot.is_empty():
			continue

		var row := _create_row(slot.item_data, slot.amount, "inventory", i)

		if row:
			inventory_items_container.add_child(row)
			has_items = true

	if not has_items:
		_add_empty_state(inventory_items_container, "Empty Inventory")


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
		UISoundManager.play_action_error()
		_update_hint("Cannot transfer item.")
		return

	var slot := player_inventory.get_slot(slot_index)

	if slot == null or slot.is_empty():
		UISoundManager.play_action_error()
		_update_hint("Empty Inventory.")
		return

	var item_data := slot.item_data
	var amount := slot.amount

	slot.clear()
	player_inventory.inventory_changed.emit()
	storage_data.add_item(item_data, amount)
	refresh()
	UISoundManager.play_transfer_item()
	_update_hint("Transferred %dx %s to Silo." % [amount, UIFormatHelper.display_product_name(item_data)])


func _transfer_storage_to_inventory(item_data: ItemData) -> void:
	if player_inventory == null or storage_data == null or item_data == null:
		UISoundManager.play_action_error()
		_update_hint("Cannot transfer item.")
		return

	var stored_amount := storage_data.get_item_amount(item_data)
	var amount_to_transfer := mini(item_data.max_stack, stored_amount)

	if amount_to_transfer <= 0:
		UISoundManager.play_action_error()
		_update_hint("Not enough items.")
		return

	var remaining := player_inventory.add_item(item_data, amount_to_transfer)
	var moved_amount := amount_to_transfer - remaining

	if moved_amount <= 0:
		UISoundManager.play_action_error()
		_update_hint("Inventory is full.")
		return

	storage_data.remove_item(item_data, moved_amount)
	refresh()
	UISoundManager.play_transfer_item()
	_update_hint("Transferred %dx %s to Inventory." % [moved_amount, UIFormatHelper.display_product_name(item_data)])


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


func _add_empty_state(container: Container, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0.0, 44.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.18, 0.10, 0.045, 0.78))
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)


func _update_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text


func _create_scroll_line(scroll_container: ScrollContainer, line_name: String) -> OptionsScrollLine:
	if scroll_container == null:
		return null

	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll_container.resized.connect(_position_scroll_lines_deferred)

	var scroll_line := OptionsScrollLine.new()
	scroll_line.name = line_name
	scroll_line.scroll_container_path = scroll_container.get_path()
	scroll_line.line_color = Color(0.0, 0.0, 0.0, 1.0)
	scroll_line.line_width = 3.0
	scroll_line.min_line_height = 28.0
	scroll_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_line.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	add_child(scroll_line)
	scroll_line.move_to_front()
	return scroll_line


func _position_scroll_lines_deferred() -> void:
	call_deferred("_position_scroll_lines")


func _position_scroll_lines() -> void:
	_position_scroll_line(_inventory_scroll_line, inventory_scroll)
	_position_scroll_line(_storage_scroll_line, storage_scroll)


func _position_scroll_line(scroll_line: Control, scroll_container: ScrollContainer) -> void:
	if scroll_line == null or scroll_container == null:
		return

	var scroll_rect: Rect2 = scroll_container.get_global_rect()
	var local_position: Vector2 = get_global_transform().affine_inverse() * scroll_rect.position
	scroll_line.position = local_position + Vector2(maxf(scroll_rect.size.x - 5.0, 0.0), 0.0)
	scroll_line.size = Vector2(6.0, scroll_rect.size.y)
	scroll_line.queue_redraw()


func _refresh_hotbar() -> void:
	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")

	if hotbar_ui and hotbar_ui.has_method("refresh"):
		hotbar_ui.refresh()


func _is_transfer_payload(data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and (data as Dictionary).get("type", "") == "storage_transfer_item"


func _on_interface_scale_changed(_scale_multiplier: float) -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var interface_scale := maxf(GraphicsSettingsManager.get_interface_scale_multiplier(), 0.1)
	var available_size := (viewport_size / interface_scale) - (VIEWPORT_SAFE_MARGIN * 2.0)
	var fit_scale := minf(available_size.x / BASE_PANEL_SIZE.x, available_size.y / BASE_PANEL_SIZE.y)
	fit_scale = clampf(fit_scale, MIN_RESPONSIVE_SCALE, 1.0)

	var panel_size := BASE_PANEL_SIZE * fit_scale
	offset_left = -panel_size.x * 0.5
	offset_top = -panel_size.y * 0.5
	offset_right = panel_size.x * 0.5
	offset_bottom = panel_size.y * 0.5
	_position_scroll_lines_deferred()
