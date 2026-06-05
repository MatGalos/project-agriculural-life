extends Control

const ICON_SIZE := Vector2(48, 48)
const WATER_BAR_OFFSET := Vector2(2, 42)
const WATER_BAR_SIZE := Vector2(44, 4)

@onready var slots := [
	$PanelContainer/HBoxContainer/Slot1,
	$PanelContainer/HBoxContainer/Slot2,
	$PanelContainer/HBoxContainer/Slot3,
	$PanelContainer/HBoxContainer/Slot4,
	$PanelContainer/HBoxContainer/Slot5
]

func _ready() -> void:
	if HotbarManager.inventory_data and not HotbarManager.inventory_data.inventory_changed.is_connected(refresh):
		HotbarManager.inventory_data.inventory_changed.connect(refresh)

	if not HotbarManager.selected_slot_changed.is_connected(_on_selected_slot_changed):
		HotbarManager.selected_slot_changed.connect(_on_selected_slot_changed)

	if not ToolManager.watering_can_changed.is_connected(refresh):
		ToolManager.watering_can_changed.connect(refresh)

	refresh()

func refresh() -> void:
	if HotbarManager.inventory_data == null or HotbarManager.hotbar_data == null:
		return

	HotbarManager.inventory_data.setup()

	for i in range(slots.size()):
		var slot_node = slots[i]
		_ensure_watering_can_bar(slot_node)

		var icon_rect: TextureRect = slot_node.get_node_or_null("IconRect") as TextureRect
		var amount_label: Label = slot_node.get_node_or_null("AmountLabel") as Label

		if icon_rect == null or amount_label == null:
			continue

		_setup_slot_ui(icon_rect, amount_label)

		var inventory_index := HotbarManager.hotbar_data.get_inventory_slot_index(i)
		var inventory_slot := HotbarManager.inventory_data.get_slot(inventory_index)

		if inventory_slot == null or inventory_slot.is_empty():
			icon_rect.texture = null
			icon_rect.visible = false
			amount_label.text = ""
			amount_label.visible = false
			_update_watering_can_bar(slot_node, null)
			continue
		else:
			icon_rect.texture = inventory_slot.item_data.icon
			icon_rect.visible = inventory_slot.item_data.icon != null

			if inventory_slot.amount > 1:
				amount_label.text = str(inventory_slot.amount)
				amount_label.visible = true
			else:
				amount_label.visible = false

			_update_watering_can_bar(slot_node, inventory_slot.item_data)

	_update_highlight(HotbarManager.get_selected_slot())

func _on_selected_slot_changed(slot_index: int) -> void:
	_update_highlight(slot_index)


func _update_highlight(active_slot: int) -> void:
	for i in range(slots.size()):
		var slot = slots[i]

		if i + 1 == active_slot:
			slot.modulate = Color(1, 1, 1, 1)
		else:
			slot.modulate = Color(0.45, 0.45, 0.45, 0.85)


func _setup_slot_ui(icon_rect: TextureRect, amount_label: Label) -> void:
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _update_watering_can_bar(slot_node: Control, item_data: ItemData) -> void:
	var icon_rect := slot_node.get_node_or_null("IconRect") as TextureRect
	if icon_rect == null:
		return

	var water_bar_background := icon_rect.get_node_or_null("WaterBarBackground") as ColorRect
	if water_bar_background == null:
		return

	var water_bar_fill := water_bar_background.get_node_or_null("WaterBarFill") as ColorRect
	if water_bar_fill == null:
		return

	var is_watering_can := false

	if item_data is ToolItemData:
		var tool := item_data as ToolItemData
		is_watering_can = tool.tool_type == ToolItemData.ToolType.WATERING_CAN

	water_bar_background.visible = is_watering_can
	water_bar_fill.visible = is_watering_can

	if not is_watering_can:
		return

	var ratio := 0.0

	if ToolManager.watering_can_capacity > 0:
		ratio = float(ToolManager.watering_can_water) / float(ToolManager.watering_can_capacity)

	ratio = clampf(ratio, 0.0, 1.0)

	water_bar_background.position = WATER_BAR_OFFSET
	water_bar_background.size = WATER_BAR_SIZE
	water_bar_fill.position = Vector2.ZERO
	water_bar_fill.size = Vector2(WATER_BAR_SIZE.x * ratio, WATER_BAR_SIZE.y)

func _ensure_watering_can_bar(slot_node: Control) -> void:
	var icon_rect := slot_node.get_node_or_null("IconRect") as TextureRect
	if icon_rect == null:
		return

	if icon_rect.get_node_or_null("WaterBarBackground") != null:
		return

	var water_bar_background := ColorRect.new()
	water_bar_background.name = "WaterBarBackground"
	water_bar_background.color = Color(0.55, 0.55, 0.55, 1.0)
	water_bar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_bar_background.position = WATER_BAR_OFFSET
	water_bar_background.size = WATER_BAR_SIZE
	water_bar_background.visible = false
	icon_rect.add_child(water_bar_background)

	var water_bar_fill := ColorRect.new()
	water_bar_fill.name = "WaterBarFill"
	water_bar_fill.color = Color(0.06, 0.33, 0.70, 1.0)
	water_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_bar_fill.position = Vector2.ZERO
	water_bar_fill.size = WATER_BAR_SIZE
	water_bar_fill.visible = false
	water_bar_background.add_child(water_bar_fill)
