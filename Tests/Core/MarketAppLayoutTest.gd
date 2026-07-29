extends RefCounted

var runner: TestRunner

const MARKET_PANEL_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/CommodityExchangeApp/commodity_exchange_panel.tscn")
const MARKET_ROW_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/CommodityExchangeApp/commodity_item_row.tscn")


func run() -> void:
	print("\n--- MarketAppLayoutTest ---")

	var panel := MARKET_PANEL_SCENE.instantiate() as Control
	runner.assert_true(panel != null, "Market app scene instantiates")

	if panel:
		_assert_market_panel_layout(panel)
		_assert_removed_count_labels(panel)
		panel.free()

	var row := MARKET_ROW_SCENE.instantiate() as PanelContainer
	runner.assert_true(row != null, "Market commodity row scene instantiates as card row")

	if row:
		_assert_market_row_layout(row)
		row.free()


func _assert_market_panel_layout(panel: Control) -> void:
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/TopBar/BackButton") is Button, "Market app has local details back button")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/TopBar/HeaderStack/TitleLabel") is Label, "Market app has title label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/TopBar/HeaderStack/StatusLabel") is Label, "Market app has market status label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ListView") is VBoxContainer, "Market app has product list view")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ListView/ContentScroll") is ScrollContainer, "Market list uses scroll container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ListView/ContentScroll/ItemsContainer") is VBoxContainer, "Market list has item row container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/DetailsView") is VBoxContainer, "Market app has product details view")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/DetailsView/DetailHero") is PanelContainer, "Market details has hero summary card")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/DetailsView/ChartPanel/ChartMargin/HistoryChart") is PriceHistoryChart, "Market details has price history chart")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/DetailsView/StatsGrid") is GridContainer, "Market details has compact stats grid")

	var back_button := panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/TopBar/BackButton") as Button
	runner.assert_true(back_button != null and back_button.text == "<", "Market details back button uses arrow text")

	var list_view := panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ListView") as VBoxContainer
	var details_view := panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/DetailsView") as VBoxContainer
	runner.assert_true(list_view != null and list_view.visible, "Market app starts on list view")
	runner.assert_true(details_view != null and not details_view.visible, "Market details view starts hidden")


func _assert_removed_count_labels(panel: Control) -> void:
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ListView/ListHeader/CountLabel") == null, "Market list does not show product count")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/DetailsView/StatsGrid/EntriesKeyLabel") == null, "Market details does not show Samples label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/DetailsView/StatsGrid/EntriesValueLabel") == null, "Market details does not show sample count value")


func _assert_market_row_layout(row: PanelContainer) -> void:
	runner.assert_true(row.custom_minimum_size.y >= 54.0, "Market commodity row reserves readable phone height")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/IconRect") is TextureRect, "Market commodity row has product icon")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/NameLabel") is Label, "Market commodity row has product name")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/ValuesStack/PriceLabel") is Label, "Market commodity row has current price")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/ValuesStack/ChangeLabel") is Label, "Market commodity row has percent change")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/TrendLabel") == null, "Market commodity row omits trend text from compact list")

	var values_stack := row.get_node_or_null("MarginContainer/Row/ValuesStack") as VBoxContainer
	runner.assert_true(values_stack != null and values_stack.custom_minimum_size.x >= 82.0, "Market commodity row reserves right-side price column")
