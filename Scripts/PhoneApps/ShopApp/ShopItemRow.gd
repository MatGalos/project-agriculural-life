extends HBoxContainer
class_name ShopItemRow

signal buy_requested(shop_item: ShopItemData)

const ICON_SIZE := Vector2(40, 40)

@onready var icon_rect: TextureRect = $IconRect
@onready var name_label: Label = $NameLabel
@onready var price_label: Label = $PriceLabel
@onready var buy_button: Button = $BuyButton

var shop_item_data: ShopItemData


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

	if price_label:
		price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	buy_button.pressed.connect(_on_buy_pressed)
	_apply_values()


func setup(shop_item: ShopItemData) -> void:
	shop_item_data = shop_item

	if shop_item_data == null or shop_item_data.item_data == null:
		return

	_apply_values()


func _apply_values() -> void:
	if shop_item_data == null or shop_item_data.item_data == null:
		return

	if icon_rect == null or name_label == null or price_label == null:
		return

	var item := shop_item_data.item_data
	var price := EconomyManager.get_buy_price(item)

	icon_rect.texture = item.icon
	name_label.text = item.display_name
	price_label.text = "%d$" % price


func _on_buy_pressed() -> void:
	if shop_item_data == null:
		return

	buy_requested.emit(shop_item_data)
