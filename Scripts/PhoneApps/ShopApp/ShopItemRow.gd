extends PanelContainer
class_name ShopItemRow

signal add_requested(shop_item: ShopItemData, amount: int)

const ICON_SIZE := Vector2(38, 38)

@onready var icon_rect: TextureRect = $MarginContainer/Row/IconRect
@onready var name_label: Label = $MarginContainer/Row/InfoStack/NameLabel
@onready var meta_label: Label = $MarginContainer/Row/InfoStack/MetaLabel
@onready var price_label: Label = $MarginContainer/Row/ActionStack/PriceLabel
@onready var add_button: Button = $MarginContainer/Row/ActionStack/AddButton

var shop_item_data: ShopItemData
var owned_count := 0


func _ready() -> void:
	custom_minimum_size.y = 62.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	if icon_rect:
		icon_rect.custom_minimum_size = ICON_SIZE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if name_label:
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if meta_label:
		meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if price_label:
		price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_button.pressed.connect(_on_add_pressed)
	_apply_values()


func setup(shop_item: ShopItemData, new_owned_count: int = 0) -> void:
	shop_item_data = shop_item
	owned_count = new_owned_count

	if shop_item_data == null or shop_item_data.item_data == null:
		return

	_apply_values()


func _apply_values() -> void:
	if shop_item_data == null or shop_item_data.item_data == null:
		return

	if icon_rect == null or name_label == null or meta_label == null or price_label == null:
		return

	var item := shop_item_data.item_data
	var unit_price := EconomyManager.get_buy_price(item)
	var amount := maxi(shop_item_data.amount_per_purchase, 1)
	var display_price := unit_price

	if amount > 1:
		display_price = unit_price * amount

	icon_rect.texture = item.icon
	name_label.text = UIFormatHelper.display_seed_name(item)
	meta_label.text = "Owned: %d" % owned_count
	price_label.text = UIFormatHelper.money_int(display_price)


func _on_add_pressed() -> void:
	if shop_item_data == null:
		return

	add_requested.emit(shop_item_data, maxi(shop_item_data.amount_per_purchase, 1))
