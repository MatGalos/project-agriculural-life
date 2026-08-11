extends Control
class_name CommodityExchangePanel

const COLOR_POSITIVE := Color(0.37, 0.86, 0.52, 1.0)
const COLOR_NEGATIVE := Color(0.95, 0.36, 0.36, 1.0)
const COLOR_NEUTRAL := Color(0.86, 0.88, 0.9, 1.0)

@export var row_scene: PackedScene

@onready var back_button: Button = $PanelContainer/MarginContainer/RootStack/TopBar/BackButton
@onready var title_label: Label = $PanelContainer/MarginContainer/RootStack/TopBar/HeaderStack/TitleLabel
@onready var status_label: Label = $PanelContainer/MarginContainer/RootStack/TopBar/HeaderStack/StatusLabel
@onready var list_view: VBoxContainer = $PanelContainer/MarginContainer/RootStack/ListView
@onready var items_container: VBoxContainer = $PanelContainer/MarginContainer/RootStack/ListView/ContentScroll/ItemsContainer
@onready var details_view: VBoxContainer = $PanelContainer/MarginContainer/RootStack/DetailsView
@onready var detail_icon_rect: TextureRect = $PanelContainer/MarginContainer/RootStack/DetailsView/DetailHero/HeroMargin/HeroRow/DetailIconRect
@onready var detail_name_label: Label = $PanelContainer/MarginContainer/RootStack/DetailsView/DetailHero/HeroMargin/HeroRow/DetailNameStack/DetailNameLabel
@onready var detail_trend_label: Label = $PanelContainer/MarginContainer/RootStack/DetailsView/DetailHero/HeroMargin/HeroRow/DetailNameStack/DetailTrendLabel
@onready var detail_price_label: Label = $PanelContainer/MarginContainer/RootStack/DetailsView/DetailHero/HeroMargin/HeroRow/DetailPriceStack/DetailPriceLabel
@onready var detail_change_label: Label = $PanelContainer/MarginContainer/RootStack/DetailsView/DetailHero/HeroMargin/HeroRow/DetailPriceStack/DetailChangeLabel
@onready var history_chart: PriceHistoryChart = $PanelContainer/MarginContainer/RootStack/DetailsView/ChartPanel/ChartMargin/HistoryChart
@onready var min_value_label: Label = $PanelContainer/MarginContainer/RootStack/DetailsView/StatsGrid/MinValueLabel
@onready var max_value_label: Label = $PanelContainer/MarginContainer/RootStack/DetailsView/StatsGrid/MaxValueLabel
@onready var avg_value_label: Label = $PanelContainer/MarginContainer/RootStack/DetailsView/StatsGrid/AvgValueLabel

var selected_commodity: CommodityData = null
var _row_nodes: Array[CommodityItemRow] = []


func _ready() -> void:
	visible = false
	back_button.pressed.connect(_show_list_view)
	visibility_changed.connect(_on_visibility_changed)

	if not CommodityMarketManager.commodity_prices_updated.is_connected(refresh):
		CommodityMarketManager.commodity_prices_updated.connect(refresh)

	_show_list_view()
	refresh()


func refresh() -> void:
	_update_status()

	if selected_commodity == null and not CommodityMarketManager.commodities.is_empty():
		selected_commodity = CommodityMarketManager.commodities[0]

	_rebuild_list()

	if details_view.visible:
		_update_details(selected_commodity)


func _update_status() -> void:
	var hour := TimeManager.get_hour()

	if hour >= CommodityMarketManager.MARKET_OPEN_HOUR and hour <= CommodityMarketManager.MARKET_CLOSE_HOUR:
		status_label.text = "Market: Open"
	else:
		status_label.text = "Market: Closed"


func _rebuild_list() -> void:
	if row_scene == null:
		return

	for child in items_container.get_children():
		child.queue_free()

	_row_nodes.clear()

	for commodity in CommodityMarketManager.commodities:
		if commodity == null or commodity.item_data == null:
			continue

		var row := row_scene.instantiate() as CommodityItemRow

		if row == null:
			continue

		items_container.add_child(row)
		_row_nodes.append(row)
		row.setup(commodity)
		row.set_selected(commodity == selected_commodity)
		row.selected.connect(_on_commodity_selected)


func _on_commodity_selected(commodity: CommodityData) -> void:
	selected_commodity = commodity
	_update_row_selection()
	_show_details_view()
	_update_details(commodity)


func _show_list_view() -> void:
	title_label.text = "Market"
	back_button.visible = false
	list_view.visible = true
	details_view.visible = false


func _show_details_view() -> void:
	back_button.visible = true
	list_view.visible = false
	details_view.visible = true


func _update_row_selection() -> void:
	for row in _row_nodes:
		row.set_selected(row.commodity_data == selected_commodity)


func _update_details(commodity: CommodityData) -> void:
	if commodity == null or commodity.item_data == null:
		title_label.text = "Market"
		history_chart.set_commodity(null)
		_set_stats_empty()
		return

	var change := _get_change_percent(commodity)
	var change_color := _get_change_color(change)
	var display_name := UIFormatHelper.display_product_name(commodity.item_data)

	title_label.text = display_name
	detail_icon_rect.texture = commodity.item_data.icon
	detail_name_label.text = display_name
	detail_trend_label.text = UIFormatHelper.display_market_trend(commodity.trend)
	detail_price_label.text = UIFormatHelper.money_float(commodity.current_price)
	detail_change_label.text = UIFormatHelper.percent(change)
	detail_change_label.add_theme_color_override("font_color", change_color)

	history_chart.set_commodity(commodity)
	_update_stats(commodity)


func _update_stats(commodity: CommodityData) -> void:
	if commodity.price_history.is_empty():
		_set_stats_empty()
		return

	var min_price := INF
	var max_price := -INF
	var total := 0.0

	for price in commodity.price_history:
		var value := float(price)
		min_price = minf(min_price, value)
		max_price = maxf(max_price, value)
		total += value

	var average := total / float(commodity.price_history.size())

	min_value_label.text = UIFormatHelper.money_float(min_price)
	max_value_label.text = UIFormatHelper.money_float(max_price)
	avg_value_label.text = UIFormatHelper.money_float(average)


func _set_stats_empty() -> void:
	min_value_label.text = "-"
	max_value_label.text = "-"
	avg_value_label.text = "-"


func _get_change_percent(commodity: CommodityData) -> float:
	if commodity == null or commodity.price_history.size() < 2:
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


func _on_visibility_changed() -> void:
	if visible:
		_show_list_view()
