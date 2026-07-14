extends HBoxContainer
class_name StorageItemRow

signal transfer_requested(row: StorageItemRow)
signal item_dropped(row: StorageItemRow, payload: Dictionary)

const ICON_SIZE := Vector2(40, 40)

@onready var icon_rect: TextureRect = $IconRect
@onready var name_label: Label = $NameLabel
@onready var amount_label: Label = $AmountLabel

var item_data: ItemData
var amount: int = 0
var source_type: String = ""
var inventory_slot_index: int = -1
var _drag_started := false
var _press_position := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size.y = ICON_SIZE.y
	mouse_filter = Control.MOUSE_FILTER_STOP

	if icon_rect:
		icon_rect.custom_minimum_size = ICON_SIZE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if name_label:
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if amount_label:
		amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_values()


func setup(new_item_data: ItemData, new_amount: int, new_source_type: String = "", new_inventory_slot_index: int = -1) -> void:
	if new_item_data == null:
		return

	item_data = new_item_data
	amount = new_amount
	source_type = new_source_type
	inventory_slot_index = new_inventory_slot_index

	_apply_values()


func _apply_values() -> void:
	if item_data == null or icon_rect == null or name_label == null or amount_label == null:
		return

	icon_rect.texture = item_data.icon
	name_label.text = UIFormatHelper.display_product_name(item_data)
	amount_label.text = "%dx" % amount


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_drag_started = false
			_press_position = mouse_event.position
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			if not _drag_started and mouse_event.position.distance_to(_press_position) < 6.0:
				transfer_requested.emit(self)


func _get_drag_data(_position: Vector2) -> Variant:
	if item_data == null or source_type.is_empty():
		return null

	_drag_started = true

	var preview := TextureRect.new()
	preview.texture = item_data.icon
	preview.custom_minimum_size = ICON_SIZE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {
		"type": "storage_transfer_item",
		"source": source_type,
		"item_data": item_data,
		"amount": amount,
		"inventory_slot_index": inventory_slot_index
	}


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type", "") == "storage_transfer_item"


func _drop_data(_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_position, data):
		return

	item_dropped.emit(self, data)
