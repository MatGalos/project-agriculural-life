extends Control
class_name InventoryPanel

@export var slot_ui_scene: PackedScene
@export var inventory_data: InventoryData

@onready var hotbar_slots_container: HBoxContainer = $PanelContainer/MarginContainer/Content/HotbarBeltPanel/HotbarSlots
@onready var inventory_grid: GridContainer = $PanelContainer/MarginContainer/Content/InventoryGrid
@onready var description_title: Label = $PanelContainer/MarginContainer/Content/DescriptionPanel/DescriptionContent/DescriptionTitle
@onready var description_amount: Label = $PanelContainer/MarginContainer/Content/DescriptionPanel/DescriptionContent/DescriptionAmount
@onready var description_text: Label = $PanelContainer/MarginContainer/Content/DescriptionPanel/DescriptionContent/DescriptionText

const HOTBAR_DISPLAY_COUNT := 5
const INVENTORY_GRID_SLOT_COUNT := 20
const INVENTORY_GRID_START_INDEX := 5

var hotbar_slot_ui_nodes: Array[InventorySlotUI] = []
var inventory_slot_ui_nodes: Array[InventorySlotUI] = []
var _selected_slot_index: int = -1

func _ready() -> void:
	visible = false
	add_to_group("inventory_panel")

	if inventory_data and not inventory_data.inventory_changed.is_connected(refresh):
		inventory_data.inventory_changed.connect(refresh)

	if not ToolManager.watering_can_changed.is_connected(refresh):
		ToolManager.watering_can_changed.connect(refresh)

	if not HotbarManager.selected_slot_changed.is_connected(_on_hotbar_selected_slot_changed):
		HotbarManager.selected_slot_changed.connect(_on_hotbar_selected_slot_changed)

	build_slots()
	refresh()
	_update_description(null)


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


func is_open() -> bool:
	return visible

func build_slots() -> void:
	for child in hotbar_slots_container.get_children():
		child.queue_free()

	for child in inventory_grid.get_children():
		child.queue_free()

	hotbar_slot_ui_nodes.clear()
	inventory_slot_ui_nodes.clear()

	if inventory_data == null or slot_ui_scene == null:
		return

	inventory_data.setup()

	if HotbarManager.hotbar_data != null:
		HotbarManager.hotbar_data.setup()

		for hotbar_index in range(HOTBAR_DISPLAY_COUNT):
			var inventory_slot_index: int = HotbarManager.hotbar_data.get_inventory_slot_index(hotbar_index)
			var hotbar_slot_ui := _create_slot_ui(inventory_slot_index, true)

			if hotbar_slot_ui:
				hotbar_slots_container.add_child(hotbar_slot_ui)
				hotbar_slot_ui_nodes.append(hotbar_slot_ui)

	for grid_index in range(INVENTORY_GRID_SLOT_COUNT):
		var inventory_slot_index := INVENTORY_GRID_START_INDEX + grid_index
		var inventory_slot_ui := _create_slot_ui(inventory_slot_index, false)

		if inventory_slot_ui:
			inventory_grid.add_child(inventory_slot_ui)
			inventory_slot_ui_nodes.append(inventory_slot_ui)


func refresh() -> void:
	if inventory_data == null:
		return

	inventory_data.setup()

	if HotbarManager.hotbar_data != null:
		HotbarManager.hotbar_data.setup()

	if inventory_data.slots.size() < INVENTORY_GRID_START_INDEX + INVENTORY_GRID_SLOT_COUNT:
		build_slots()

	var expected_hotbar_slots: int = HOTBAR_DISPLAY_COUNT if HotbarManager.hotbar_data != null else 0
	if hotbar_slot_ui_nodes.size() != expected_hotbar_slots or inventory_slot_ui_nodes.size() != INVENTORY_GRID_SLOT_COUNT:
		build_slots()

	if HotbarManager.hotbar_data != null:
		for i in range(hotbar_slot_ui_nodes.size()):
			var inventory_slot_index: int = HotbarManager.hotbar_data.get_inventory_slot_index(i)
			var slot_data := inventory_data.get_slot(inventory_slot_index)
			hotbar_slot_ui_nodes[i].set_slot(inventory_slot_index, slot_data)

	for i in range(inventory_slot_ui_nodes.size()):
		var inventory_slot_index := INVENTORY_GRID_START_INDEX + i
		var slot_data := inventory_data.get_slot(inventory_slot_index)
		inventory_slot_ui_nodes[i].set_slot(inventory_slot_index, slot_data)

	_update_slot_selection()

func move_or_merge_slot(from_index: int, to_index: int) -> void:
	if inventory_data == null:
		return

	inventory_data.move_or_merge_slot(from_index, to_index)

	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui and hotbar_ui.has_method("refresh"):
		hotbar_ui.refresh()

	refresh()


func select_slot(slot_index: int) -> void:
	_selected_slot_index = slot_index
	var slot_data: InventorySlot = inventory_data.get_slot(slot_index) if inventory_data != null else null
	_update_description(slot_data)
	_update_slot_selection()


func _create_slot_ui(slot_index: int, is_hotbar_slot: bool) -> InventorySlotUI:
	var slot_ui: InventorySlotUI = slot_ui_scene.instantiate() as InventorySlotUI

	if slot_ui == null:
		return null

	slot_ui.set_display_mode(InventorySlotUI.DisplayMode.HOTBAR if is_hotbar_slot else InventorySlotUI.DisplayMode.INVENTORY)
	slot_ui.slot_selected.connect(select_slot)
	slot_ui.slot_hovered.connect(_on_slot_hovered)
	slot_ui.custom_minimum_size = Vector2(78.0, 78.0) if is_hotbar_slot else Vector2(76.0, 76.0)
	slot_ui.set_slot(slot_index, inventory_data.get_slot(slot_index))
	return slot_ui


func _on_hotbar_selected_slot_changed(_slot_index: int) -> void:
	_update_slot_selection()


func _on_slot_hovered(slot_index: int) -> void:
	if inventory_data == null:
		return

	_update_description(inventory_data.get_slot(slot_index))


func _update_slot_selection() -> void:
	if HotbarManager.hotbar_data == null:
		return

	var active_hotbar_inventory_index: int = HotbarManager.hotbar_data.get_selected_inventory_slot_index()

	for slot_ui in hotbar_slot_ui_nodes:
		slot_ui.set_active_hotbar(slot_ui.slot_index == active_hotbar_inventory_index)
		slot_ui.set_selected(slot_ui.slot_index == _selected_slot_index)

	for slot_ui in inventory_slot_ui_nodes:
		slot_ui.set_active_hotbar(false)
		slot_ui.set_selected(slot_ui.slot_index == _selected_slot_index)


func _update_description(slot: InventorySlot) -> void:
	if slot == null or slot.is_empty() or slot.item_data == null:
		description_title.text = "Select an item"
		description_amount.text = ""
		description_text.text = "Hover or select a slot to view item details."
		return

	description_title.text = UIFormatHelper.display_product_name(slot.item_data)
	description_amount.text = "Quantity: %dx" % slot.amount

	var description := String(slot.item_data.description).strip_edges()
	description_text.text = description if not description.is_empty() else "No description available."
