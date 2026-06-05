extends PanelContainer
class_name InventorySlotUI

const ICON_SIZE := Vector2(64, 64)

@onready var icon_rect: TextureRect = $Control/IconRect
@onready var amount_label: Label = $Control/AmountLabel
@onready var water_bar_background: ColorRect = $Control/WaterBarBackground
@onready var water_bar_fill: ColorRect = $Control/WaterBarBackground/WaterBarFill

var slot_index: int = -1
var slot_data: InventorySlot = null


func _ready() -> void:
	custom_minimum_size = ICON_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP

	$Control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if icon_rect:
		icon_rect.custom_minimum_size = ICON_SIZE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if amount_label:
		amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if water_bar_background:
		water_bar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		water_bar_background.visible = false

	if water_bar_fill:
		water_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
		amount_label.text = str(slot.amount)
		amount_label.visible = true
	elif amount_label:
		amount_label.visible = false
	_update_water_bar(slot.item_data)


func clear() -> void:
	if icon_rect:
		icon_rect.texture = null
		icon_rect.visible = false

	if amount_label:
		amount_label.text = ""
		amount_label.visible = false
	_update_water_bar(null)


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

	water_bar_fill.position = Vector2.ZERO
	water_bar_fill.size = Vector2(water_bar_background.size.x * ratio, water_bar_background.size.y)
