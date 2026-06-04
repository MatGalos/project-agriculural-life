extends PanelContainer
class_name InventorySlotUI

const ICON_SIZE := Vector2(64, 64)

@onready var icon_rect: TextureRect = $Control/IconRect
@onready var amount_label: Label = $Control/AmountLabel

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


func clear() -> void:
	if icon_rect:
		icon_rect.texture = null
		icon_rect.visible = false

	if amount_label:
		amount_label.text = ""
		amount_label.visible = false


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
