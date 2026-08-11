extends PanelContainer
class_name ShopCartRow

signal quantity_changed(item_id: String, delta: int)
signal quantity_set(item_id: String, quantity: int)
signal remove_requested(item_id: String)

@onready var name_label: Label = $MarginContainer/Row/InfoStack/NameLabel
@onready var subtotal_label: Label = $MarginContainer/Row/InfoStack/SubtotalLabel
@onready var minus_button: Button = $MarginContainer/Row/ControlsRow/MinusButton
@onready var quantity_edit: LineEdit = $MarginContainer/Row/ControlsRow/QuantityEdit
@onready var plus_button: Button = $MarginContainer/Row/ControlsRow/PlusButton
@onready var remove_button: Button = $MarginContainer/Row/ControlsRow/RemoveButton

var item_data: ItemData
var item_id := ""
var quantity := 0
var unit_price := 0


func _ready() -> void:
	minus_button.pressed.connect(_on_minus_pressed)
	plus_button.pressed.connect(_on_plus_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	quantity_edit.text_submitted.connect(_on_quantity_submitted)
	quantity_edit.focus_exited.connect(_on_quantity_focus_exited)
	_apply_values()


func setup(item: ItemData, new_quantity: int, new_unit_price: int) -> void:
	item_data = item
	item_id = ""

	if item_data != null:
		item_id = item_data.id

	quantity = maxi(new_quantity, 0)
	unit_price = maxi(new_unit_price, 0)
	_apply_values()


func _apply_values() -> void:
	if item_data == null or name_label == null or subtotal_label == null or quantity_edit == null:
		return

	var subtotal := quantity * unit_price

	name_label.text = UIFormatHelper.display_seed_name(item_data)
	quantity_edit.text = "%d" % quantity
	subtotal_label.text = "%d x %s = %s" % [
		quantity,
		UIFormatHelper.money_int(unit_price),
		UIFormatHelper.money_int(subtotal)
	]


func _on_minus_pressed() -> void:
	if not item_id.is_empty():
		quantity_changed.emit(item_id, -1)


func _on_plus_pressed() -> void:
	if not item_id.is_empty():
		quantity_changed.emit(item_id, 1)


func _on_remove_pressed() -> void:
	if not item_id.is_empty():
		remove_requested.emit(item_id)


func _on_quantity_submitted(new_text: String) -> void:
	_commit_quantity_text(new_text)


func _on_quantity_focus_exited() -> void:
	_commit_quantity_text(quantity_edit.text)


func _commit_quantity_text(new_text: String) -> void:
	if item_id.is_empty():
		return

	var clean_text := new_text.strip_edges()

	if clean_text.is_empty() or not clean_text.is_valid_int():
		quantity_edit.text = "%d" % quantity
		return

	var new_quantity := maxi(clean_text.to_int(), 0)
	quantity_set.emit(item_id, new_quantity)
