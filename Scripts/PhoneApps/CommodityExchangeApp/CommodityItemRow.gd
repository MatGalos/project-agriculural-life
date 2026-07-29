extends PanelContainer
class_name CommodityItemRow

const ICON_SIZE := Vector2(36, 36)
const COLOR_POSITIVE := Color(0.37, 0.86, 0.52, 1.0)
const COLOR_NEGATIVE := Color(0.95, 0.36, 0.36, 1.0)
const COLOR_NEUTRAL := Color(0.86, 0.88, 0.9, 1.0)

signal selected(commodity: CommodityData)

@onready var icon_rect: TextureRect = $MarginContainer/Row/IconRect
@onready var name_label: Label = $MarginContainer/Row/NameLabel
@onready var price_label: Label = $MarginContainer/Row/ValuesStack/PriceLabel
@onready var change_label: Label = $MarginContainer/Row/ValuesStack/ChangeLabel

var commodity_data: CommodityData
var _is_hovered := false
var _is_selected := false
var _normal_style := StyleBoxFlat.new()
var _hover_style := StyleBoxFlat.new()
var _selected_style := StyleBoxFlat.new()


func _ready() -> void:
	custom_minimum_size.y = 54.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	_prepare_styles()
	_apply_style()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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

	if change_label:
		change_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_values()


func setup(commodity: CommodityData) -> void:
	if commodity == null or commodity.item_data == null:
		return

	commodity_data = commodity
	_apply_values()


func set_selected(value: bool) -> void:
	_is_selected = value
	_apply_style()


func _apply_values() -> void:
	if commodity_data == null or commodity_data.item_data == null:
		return

	if icon_rect == null or name_label == null or price_label == null or change_label == null:
		return

	var change := _get_change_percent(commodity_data)

	icon_rect.texture = commodity_data.item_data.icon
	name_label.text = UIFormatHelper.display_product_name(commodity_data.item_data)
	price_label.text = UIFormatHelper.money_float(commodity_data.current_price)
	change_label.text = UIFormatHelper.percent(change)
	change_label.add_theme_color_override("font_color", _get_change_color(change))


func _get_change_percent(commodity: CommodityData) -> float:
	if commodity.price_history.size() < 2:
		return 0.0

	var previous_price := float(commodity.price_history[commodity.price_history.size() - 2])
	var current_price := commodity.current_price

	if previous_price <= 0.0:
		return 0.0

	return ((current_price - previous_price) / previous_price) * 100.0


func _get_change_color(change: float) -> Color:
	if change > 0.005:
		return COLOR_POSITIVE

	if change < -0.005:
		return COLOR_NEGATIVE

	return COLOR_NEUTRAL


func _prepare_styles() -> void:
	_configure_style(_normal_style, Color(0.055, 0.061, 0.072, 0.92), Color(0.12, 0.14, 0.16, 1.0))
	_configure_style(_hover_style, Color(0.075, 0.086, 0.096, 0.98), Color(0.2, 0.24, 0.22, 1.0))
	_configure_style(_selected_style, Color(0.065, 0.105, 0.085, 1.0), Color(0.22, 0.5, 0.34, 1.0))


func _configure_style(style: StyleBoxFlat, bg_color: Color, border_color: Color) -> void:
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4


func _apply_style() -> void:
	if _is_selected:
		add_theme_stylebox_override("panel", _selected_style)
	elif _is_hovered:
		add_theme_stylebox_override("panel", _hover_style)
	else:
		add_theme_stylebox_override("panel", _normal_style)


func _on_mouse_entered() -> void:
	_is_hovered = true
	_apply_style()


func _on_mouse_exited() -> void:
	_is_hovered = false
	_apply_style()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if commodity_data:
				selected.emit(commodity_data)
