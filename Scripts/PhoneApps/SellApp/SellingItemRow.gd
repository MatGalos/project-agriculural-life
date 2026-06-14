extends HBoxContainer
class_name SellingItemRow

signal sell_one_requested(item_data: ItemData)
signal sell_all_requested(item_data: ItemData)

const ICON_SIZE := Vector2(40, 40)

@onready var icon_rect: TextureRect = $IconRect
@onready var name_label: Label = $NameLabel
@onready var amount_label: Label = $AmountLabel
@onready var price_label: Label = $PriceLabel
@onready var sell_one_button: Button = $SellOneButton
@onready var sell_all_button: Button = $SellAllButton

var item_data: ItemData
var amount: int = 0


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

	if price_label:
		price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	sell_one_button.pressed.connect(_on_sell_one_pressed)
	sell_all_button.pressed.connect(_on_sell_all_pressed)
	_apply_values()


func setup(new_item_data: ItemData, new_amount: int) -> void:
	item_data = new_item_data
	amount = new_amount

	if item_data == null:
		return

	_apply_values()


func _apply_values() -> void:
	if item_data == null or icon_rect == null or name_label == null or amount_label == null or price_label == null:
		return

	icon_rect.texture = item_data.icon
	name_label.text = item_data.display_name
	amount_label.text = "x%d" % amount
	price_label.text = "%d$ each" % EconomyManager.get_sell_price(item_data)


func _on_sell_one_pressed() -> void:
	if item_data == null:
		return

	sell_one_requested.emit(item_data)


func _on_sell_all_pressed() -> void:
	if item_data == null:
		return

	sell_all_requested.emit(item_data)
