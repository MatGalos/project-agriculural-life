extends PanelContainer
class_name InventorySlotUI

signal slot_selected(slot_index: int)
signal slot_hovered(slot_index: int)

enum DisplayMode {
	INVENTORY,
	HOTBAR
}

const ICON_SIZE := Vector2(52, 52)
const WATER_BAR_MARGIN := 8.0
const WATER_BAR_HEIGHT := 6.0

@onready var icon_rect: TextureRect = $Control/IconRect
@onready var amount_label: Label = $Control/AmountLabel
@onready var water_bar_background: ColorRect = $Control/WaterBarBackground
@onready var water_bar_fill: ColorRect = $Control/WaterBarBackground/WaterBarFill

var slot_index: int = -1
var slot_data: InventorySlot = null
var display_mode: int = DisplayMode.INVENTORY
var _is_hovered: bool = false
var _is_selected: bool = false
var _is_active_hotbar: bool = false


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(78.0, 78.0) if display_mode == DisplayMode.HOTBAR else Vector2(76.0, 76.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_on_resized)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if icon_rect:
		icon_rect.custom_minimum_size = ICON_SIZE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if amount_label:
		amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if water_bar_background:
		water_bar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		water_bar_background.visible = false

	if water_bar_fill:
		water_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_layout()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	if display_mode == DisplayMode.HOTBAR:
		_draw_hotbar_slot()
	else:
		_draw_inventory_slot()


func _draw_inventory_slot() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var fill_color: Color = Color(0.82, 0.64, 0.38, 0.76)
	var border_color: Color = Color(0.22, 0.105, 0.04, 0.94)

	if _is_selected:
		fill_color = Color(0.94, 0.74, 0.42, 0.90)
	elif _is_hovered:
		fill_color = Color(0.88, 0.69, 0.40, 0.84)

	draw_rect(Rect2(Vector2(2.0, 3.0), size), Color(0.06, 0.03, 0.012, 0.22), true)
	draw_rect(rect.grow(-3.0), fill_color, true)
	draw_line(Vector2(9.0, 13.0), Vector2(size.x - 9.0, 13.0), Color(0.35, 0.18, 0.07, 0.23), 1.0)
	draw_line(Vector2(9.0, size.y - 12.0), Vector2(size.x - 9.0, size.y - 12.0), Color(0.35, 0.18, 0.07, 0.20), 1.0)
	draw_rect(rect.grow(-3.0), border_color, false, 2.0)

	if _is_selected:
		draw_rect(rect.grow(-6.0), Color(1.0, 0.84, 0.45, 0.42), false, 2.0)


func _draw_hotbar_slot() -> void:
	var base_color: Color = Color(0.24, 0.11, 0.045, 0.96)
	var border_color: Color = Color(0.10, 0.045, 0.02, 1.0)
	var stitch_color: Color = Color(0.78, 0.55, 0.30, 0.58)
	var bottom_y: float = size.y - 7.0
	var lip_y: float = 16.0
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(5.0, 6.0),
		Vector2(size.x - 5.0, 6.0),
		Vector2(size.x - 8.0, bottom_y),
		Vector2(8.0, bottom_y)
	])

	if _is_active_hotbar:
		base_color = Color(0.54, 0.29, 0.12, 0.98)
	elif _is_hovered or _is_selected:
		base_color = Color(0.34, 0.16, 0.065, 0.98)

	if _is_active_hotbar:
		draw_rect(Rect2(Vector2(0.0, 1.0), size - Vector2(0.0, 1.0)), Color(0.95, 0.66, 0.32, 0.22), true)

	draw_rect(Rect2(Vector2(3.0, 7.0), size - Vector2(6.0, 5.0)), Color(0.035, 0.018, 0.01, 0.34), true)
	draw_colored_polygon(points, base_color)
	draw_line(Vector2(8.0, lip_y), Vector2(size.x - 8.0, lip_y), Color(0.12, 0.055, 0.025, 0.72), 2.0)
	draw_line(Vector2(9.0, lip_y + 5.0), Vector2(size.x - 9.0, lip_y + 5.0), stitch_color, 1.0)
	draw_circle(Vector2(12.0, 13.0), 2.6, Color(0.62, 0.54, 0.44, 0.95))
	draw_circle(Vector2(size.x - 12.0, 13.0), 2.6, Color(0.62, 0.54, 0.44, 0.95))
	draw_line(points[0], points[1], border_color, 2.0)
	draw_line(points[1], points[2], border_color, 2.0)
	draw_line(points[2], points[3], border_color, 2.0)
	draw_line(points[3], points[0], border_color, 2.0)

	if _is_selected:
		draw_rect(Rect2(Vector2(4.0, 4.0), size - Vector2(8.0, 8.0)), Color(1.0, 0.84, 0.45, 0.34), false, 2.0)


func set_display_mode(new_display_mode: int) -> void:
	display_mode = new_display_mode
	queue_redraw()


func set_slot(index: int, slot: InventorySlot) -> void:
	slot_index = index
	slot_data = slot

	if slot == null or slot.is_empty():
		clear()
		return

	if icon_rect:
		icon_rect.texture = slot.item_data.icon
		icon_rect.visible = slot.item_data.icon != null

	if amount_label and slot.amount > 1:
		amount_label.text = "%dx" % slot.amount
		amount_label.visible = true
	elif amount_label:
		amount_label.visible = false
	_apply_layout()
	_update_water_bar(slot.item_data)


func clear() -> void:
	if icon_rect:
		icon_rect.texture = null
		icon_rect.visible = false

	if amount_label:
		amount_label.text = ""
		amount_label.visible = false
	_apply_layout()
	_update_water_bar(null)


func set_selected(is_selected: bool) -> void:
	if _is_selected == is_selected:
		return

	_is_selected = is_selected
	queue_redraw()


func set_active_hotbar(is_active: bool) -> void:
	if _is_active_hotbar == is_active:
		return

	_is_active_hotbar = is_active
	queue_redraw()


func _get_drag_data(_position):
	if slot_data == null or slot_data.is_empty():
		return null

	var preview := TextureRect.new()
	preview.texture = slot_data.item_data.icon
	preview.custom_minimum_size = ICON_SIZE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	# Use an explicit payload type so other UI drags cannot be dropped into inventory slots.
	return {
		"type": "inventory_slot",
		"slot_index": slot_index
	}


func _can_drop_data(_position, data) -> bool:
	return (
		typeof(data) == TYPE_DICTIONARY
		and data.get("type", "") == "inventory_slot"
		and int(data.get("slot_index", -1)) != slot_index
	)


func _drop_data(_position, data) -> void:
	if not _can_drop_data(_position, data):
		return

	var from_index: int = int(data["slot_index"])
	var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")

	if inventory_panel == null:
		return

	inventory_panel.move_or_merge_slot(from_index, slot_index)

func _update_water_bar(item_data: ItemData) -> void:
	if water_bar_background == null or water_bar_fill == null:
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

	_position_water_bar()
	water_bar_fill.position = Vector2.ZERO
	water_bar_fill.size = Vector2(water_bar_background.size.x * ratio, water_bar_background.size.y)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			slot_selected.emit(slot_index)

		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			var storage_panel = get_tree().get_first_node_in_group("storage_panel")

			if storage_panel == null:
				return

			if not storage_panel.visible:
				return

			storage_panel.transfer_from_inventory_slot(slot_index)


func _on_mouse_entered() -> void:
	_is_hovered = true
	slot_hovered.emit(slot_index)
	queue_redraw()


func _on_mouse_exited() -> void:
	_is_hovered = false
	queue_redraw()


func _on_resized() -> void:
	_apply_layout()
	queue_redraw()


func _apply_layout() -> void:
	if icon_rect:
		icon_rect.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		icon_rect.size = ICON_SIZE
		icon_rect.position = (size - ICON_SIZE) * 0.5 + Vector2(0.0, -2.0)

	if amount_label:
		amount_label.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		var badge_width: float = maxf(32.0, float(amount_label.text.length() * 8 + 13))
		amount_label.size = Vector2(badge_width, 18.0)
		amount_label.position = Vector2(
			maxf(size.x - badge_width - 7.0, 0.0),
			maxf(size.y - 25.0, 0.0)
		)

	_position_water_bar()


func _position_water_bar() -> void:
	if water_bar_background == null:
		return

	water_bar_background.position = Vector2(
		WATER_BAR_MARGIN,
		maxf(size.y - WATER_BAR_MARGIN - WATER_BAR_HEIGHT, 0.0)
	)
	water_bar_background.size = Vector2(maxf(size.x - WATER_BAR_MARGIN * 2.0, 0.0), WATER_BAR_HEIGHT)
