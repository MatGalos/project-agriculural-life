extends PanelContainer
class_name SellingItemRow

signal quantity_changed(item_id: String, quantity: int)
signal sell_requested(item_data: ItemData, amount: int)
signal sell_all_requested(item_data: ItemData)

const ICON_SIZE := Vector2(42, 42)

@onready var icon_rect: TextureRect = $MarginContainer/CardStack/TopRow/IconRect
@onready var name_label: Label = $MarginContainer/CardStack/TopRow/InfoStack/NameLabel
@onready var amount_label: Label = $MarginContainer/CardStack/TopRow/InfoStack/AmountLabel
@onready var price_label: Label = $MarginContainer/CardStack/TopRow/PriceStack/PriceLabel
@onready var value_label: Label = $MarginContainer/CardStack/TopRow/PriceStack/ValueLabel
@onready var minus_button: Button = $MarginContainer/CardStack/QuantityRow/MinusButton
@onready var selected_edit: LineEdit = $MarginContainer/CardStack/QuantityRow/SelectedEdit
@onready var plus_button: Button = $MarginContainer/CardStack/QuantityRow/PlusButton
@onready var half_button: Button = $MarginContainer/CardStack/QuantityRow/HalfButton
@onready var all_button: Button = $MarginContainer/CardStack/QuantityRow/AllButton
@onready var subtotal_label: Label = $MarginContainer/CardStack/ActionRow/SubtotalLabel
@onready var sell_button: Button = $MarginContainer/CardStack/ActionRow/SellButton
@onready var sell_all_button: Button = $MarginContainer/CardStack/ActionRow/SellAllButton

var item_data: ItemData
var amount: int = 0
var selected_amount: int = 0


func _ready() -> void:
	custom_minimum_size.y = 128.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	if icon_rect:
		icon_rect.custom_minimum_size = ICON_SIZE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for label in [name_label, amount_label, price_label, value_label, subtotal_label]:
		if label:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	minus_button.pressed.connect(_on_minus_pressed)
	plus_button.pressed.connect(_on_plus_pressed)
	half_button.pressed.connect(_on_half_pressed)
	all_button.pressed.connect(_on_all_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	sell_all_button.pressed.connect(_on_sell_all_pressed)
	selected_edit.text_submitted.connect(_on_selected_text_submitted)
	selected_edit.focus_exited.connect(_on_selected_focus_exited)
	_apply_values()


func setup(new_item_data: ItemData, new_amount: int, new_selected_amount: int = 0) -> void:
	item_data = new_item_data
	amount = maxi(new_amount, 0)
	selected_amount = clampi(new_selected_amount, 0, amount)

	if item_data == null:
		return

	_apply_values()


func _apply_values() -> void:
	if item_data == null or icon_rect == null or name_label == null or amount_label == null or price_label == null:
		return

	var unit_price := EconomyManager.get_sell_price(item_data)
	var selected_value := unit_price * selected_amount

	icon_rect.texture = item_data.icon
	name_label.text = UIFormatHelper.display_product_name(item_data)
	amount_label.text = "In storage: %dx" % amount
	price_label.text = UIFormatHelper.money_each(unit_price)
	value_label.text = UIFormatHelper.money_int(selected_value)
	selected_edit.text = "%d" % selected_amount
	subtotal_label.text = "Value: %s" % UIFormatHelper.money_int(selected_value)
	sell_button.disabled = selected_amount <= 0
	sell_all_button.disabled = amount <= 0


func _set_selected_amount(value: int) -> void:
	selected_amount = clampi(value, 0, amount)
	_apply_values()

	if item_data != null:
		quantity_changed.emit(item_data.id, selected_amount)


func _on_minus_pressed() -> void:
	_set_selected_amount(selected_amount - 1)


func _on_plus_pressed() -> void:
	_set_selected_amount(selected_amount + 1)


func _on_half_pressed() -> void:
	_set_selected_amount(int(amount / 2))


func _on_all_pressed() -> void:
	_set_selected_amount(amount)


func _on_selected_text_submitted(new_text: String) -> void:
	_commit_selected_text(new_text)


func _on_selected_focus_exited() -> void:
	_commit_selected_text(selected_edit.text)


func _commit_selected_text(new_text: String) -> void:
	var clean_text := new_text.strip_edges()

	if clean_text.is_empty() or not clean_text.is_valid_int():
		selected_edit.text = "%d" % selected_amount
		return

	_set_selected_amount(clean_text.to_int())


func _on_sell_pressed() -> void:
	if item_data == null:
		return

	sell_requested.emit(item_data, selected_amount)


func _on_sell_all_pressed() -> void:
	if item_data == null:
		return

	sell_all_requested.emit(item_data)
