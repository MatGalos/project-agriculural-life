extends HBoxContainer
class_name CommodityItemRow

const ICON_SIZE := Vector2(40, 40)

signal selected(commodity: CommodityData)

@onready var icon_rect: TextureRect = $IconRect
@onready var name_label: Label = $NameLabel
@onready var price_label: Label = $PriceLabel
@onready var trend_label: Label = $TrendLabel
@onready var change_label: Label = $ChangeLabel

var commodity_data: CommodityData

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

	if trend_label:
		trend_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if change_label:
		change_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_values()


func setup(commodity: CommodityData) -> void:
	if commodity == null or commodity.item_data == null:
		return

	commodity_data = commodity
	_apply_values()


func _apply_values() -> void:
	if commodity_data == null or commodity_data.item_data == null:
		return

	if icon_rect == null or name_label == null or price_label == null or trend_label == null or change_label == null:
		return

	icon_rect.texture = commodity_data.item_data.icon
	name_label.text = UIFormatHelper.display_product_name(commodity_data.item_data)
	price_label.text = UIFormatHelper.money_float(commodity_data.current_price)
	trend_label.text = UIFormatHelper.display_market_trend(commodity_data.trend)
	change_label.text = _get_change_text(commodity_data)


func _get_trend_text(commodity: CommodityData) -> String:
	return UIFormatHelper.display_market_trend(commodity.trend)


func _get_change_text(commodity: CommodityData) -> String:
	if commodity.price_history.size() < 2:
		return UIFormatHelper.percent(0.0)

	var previous_price := commodity.price_history[commodity.price_history.size() - 2]
	var current_price := commodity.current_price

	if previous_price <= 0:
		return UIFormatHelper.percent(0.0)

	var change := ((current_price - previous_price) / previous_price) * 100.0

	return UIFormatHelper.percent(change)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if commodity_data:
				selected.emit(commodity_data)
