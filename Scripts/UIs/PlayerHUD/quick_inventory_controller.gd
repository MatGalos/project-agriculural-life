extends Control

const ICON_SIZE := Vector2(52, 52)
const WATER_BAR_MARGIN := 9.0
const WATER_BAR_HEIGHT := 6.0

@onready var slots := [
	$PanelContainer/HBoxContainer/Slot1,
	$PanelContainer/HBoxContainer/Slot2,
	$PanelContainer/HBoxContainer/Slot3,
	$PanelContainer/HBoxContainer/Slot4,
	$PanelContainer/HBoxContainer/Slot5
]

func _ready() -> void:
	if not resized.is_connected(_on_hotbar_resized):
		resized.connect(_on_hotbar_resized)

	for slot_node: Control in slots:
		if not slot_node.resized.is_connected(_on_slot_resized):
			slot_node.resized.connect(_on_slot_resized)

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

		_setup_slot_ui(slot_node, icon_rect, amount_label)

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
				amount_label.text = "%dx" % inventory_slot.amount
				amount_label.visible = true
			else:
				amount_label.visible = false

			_update_watering_can_bar(slot_node, inventory_slot.item_data)

	_update_highlight(HotbarManager.get_selected_slot())
	_refresh_layout_deferred()

func _on_selected_slot_changed(slot_index: int) -> void:
	_update_highlight(slot_index)


func _on_hotbar_resized() -> void:
	_refresh_layout_deferred()


func _on_slot_resized() -> void:
	if HotbarManager.inventory_data == null or HotbarManager.hotbar_data == null:
		return

	for i in range(slots.size()):
		var slot_node: Control = slots[i]
		var inventory_index := HotbarManager.hotbar_data.get_inventory_slot_index(i)
		var inventory_slot := HotbarManager.inventory_data.get_slot(inventory_index)
		var item_data: ItemData = null

		if inventory_slot != null and not inventory_slot.is_empty():
			item_data = inventory_slot.item_data

		var icon_rect: TextureRect = slot_node.get_node_or_null("IconRect") as TextureRect
		var amount_label: Label = slot_node.get_node_or_null("AmountLabel") as Label
		if icon_rect != null and amount_label != null:
			_setup_slot_ui(slot_node, icon_rect, amount_label)

		_update_watering_can_bar(slot_node, item_data)


func _refresh_layout_deferred() -> void:
	call_deferred("_refresh_slot_layout")


func _refresh_slot_layout() -> void:
	if HotbarManager.inventory_data == null or HotbarManager.hotbar_data == null:
		return

	for i in range(slots.size()):
		var slot_node: Control = slots[i]
		var icon_rect: TextureRect = slot_node.get_node_or_null("IconRect") as TextureRect
		var amount_label: Label = slot_node.get_node_or_null("AmountLabel") as Label
		var inventory_index := HotbarManager.hotbar_data.get_inventory_slot_index(i)
		var inventory_slot := HotbarManager.inventory_data.get_slot(inventory_index)
		var item_data: ItemData = null

		if inventory_slot != null and not inventory_slot.is_empty():
			item_data = inventory_slot.item_data

		if icon_rect != null and amount_label != null:
			_setup_slot_ui(slot_node, icon_rect, amount_label)

		_update_watering_can_bar(slot_node, item_data)


func _update_highlight(active_slot: int) -> void:
	for i in range(slots.size()):
		var slot: Control = slots[i]
		var is_active: bool = i + 1 == active_slot

		slot.modulate = Color.WHITE

		if slot.has_method("set_active_state"):
			slot.call("set_active_state", is_active)


func _setup_slot_ui(slot_node: Control, icon_rect: TextureRect, amount_label: Label) -> void:
	icon_rect.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.size = ICON_SIZE
	icon_rect.position = (slot_node.size - ICON_SIZE) * 0.5 + Vector2(0.0, -1.0)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)

	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	amount_label.size_flags_vertical = Control.SIZE_SHRINK_END
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.add_theme_font_size_override("font_size", 13)
	amount_label.add_theme_color_override("font_color", Color(0.06, 0.035, 0.015, 1.0))
	amount_label.add_theme_color_override("font_shadow_color", Color(0.95, 0.78, 0.48, 0.25))
	amount_label.add_theme_constant_override("shadow_offset_x", 1)
	amount_label.add_theme_constant_override("shadow_offset_y", 1)

func _update_watering_can_bar(slot_node: Control, item_data: ItemData) -> void:
	if slot_node.size.x <= 1.0 or slot_node.size.y <= 1.0:
		_refresh_layout_deferred()
		return

	var water_bar_layer := slot_node.get_node_or_null("WaterBarLayer") as Control
	if water_bar_layer == null:
		return

	water_bar_layer.position = Vector2.ZERO
	water_bar_layer.size = slot_node.size
	water_bar_layer.move_to_front()

	var water_bar_background := water_bar_layer.get_node_or_null("WaterBarBackground") as ColorRect
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

	var layer_size := water_bar_layer.size
	var bar_width := maxf(layer_size.x - (WATER_BAR_MARGIN * 2.0), 0.0)
	var bar_size := Vector2(bar_width, WATER_BAR_HEIGHT)
	water_bar_background.position = Vector2(
		WATER_BAR_MARGIN,
		maxf(layer_size.y - WATER_BAR_MARGIN - WATER_BAR_HEIGHT, 0.0)
	)
	water_bar_background.size = bar_size
	water_bar_fill.position = Vector2.ZERO
	water_bar_fill.size = Vector2(bar_size.x * ratio, bar_size.y)

func _ensure_watering_can_bar(slot_node: Control) -> void:
	var legacy_water_bar := slot_node.get_node_or_null("WaterBarBackground")
	if legacy_water_bar != null:
		legacy_water_bar.queue_free()

	var water_bar_layer := slot_node.get_node_or_null("WaterBarLayer") as Control
	if water_bar_layer == null:
		water_bar_layer = Control.new()
		water_bar_layer.name = "WaterBarLayer"
		water_bar_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		water_bar_layer.custom_minimum_size = Vector2.ZERO
		water_bar_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		water_bar_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot_node.add_child(water_bar_layer)

	water_bar_layer.position = Vector2.ZERO
	water_bar_layer.size = slot_node.size
	water_bar_layer.move_to_front()

	if water_bar_layer.get_node_or_null("WaterBarBackground") != null:
		return

	var water_bar_background := ColorRect.new()
	water_bar_background.name = "WaterBarBackground"
	water_bar_background.color = Color(0.11, 0.055, 0.025, 0.96)
	water_bar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_bar_background.position = Vector2.ZERO
	water_bar_background.size = Vector2.ZERO
	water_bar_background.visible = false
	water_bar_layer.add_child(water_bar_background)

	var water_bar_fill := ColorRect.new()
	water_bar_fill.name = "WaterBarFill"
	water_bar_fill.color = Color(0.20, 0.55, 0.78, 0.95)
	water_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_bar_fill.position = Vector2.ZERO
	water_bar_fill.size = Vector2.ZERO
	water_bar_fill.visible = false
	water_bar_background.add_child(water_bar_fill)
