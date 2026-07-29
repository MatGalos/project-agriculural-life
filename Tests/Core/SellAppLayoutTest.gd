extends RefCounted

var runner: TestRunner

const SELL_PANEL_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/SellApp/SellingPanel.tscn")
const SELL_ROW_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/SellApp/selling_item_row.tscn")


func run() -> void:
	print("\n--- SellAppLayoutTest ---")

	var panel := SELL_PANEL_SCENE.instantiate() as Control
	runner.assert_true(panel != null, "Sell app scene instantiates")

	if panel:
		_assert_sell_panel_layout(panel)
		panel.free()

	var row := SELL_ROW_SCENE.instantiate() as PanelContainer
	runner.assert_true(row != null, "Sell item row scene instantiates as card row")

	if row:
		_assert_sell_row_layout(row)
		row.free()


func _assert_sell_panel_layout(panel: Control) -> void:
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/TitleLabel") is Label, "Sell app has title label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/SubtitleLabel") is Label, "Sell app has subtitle label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/FeedbackLabel") is Label, "Sell app has feedback label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ItemsScroll") is ScrollContainer, "Sell app list uses scroll container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ItemsScroll/ItemsContainer") is VBoxContainer, "Sell app has item list container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/EmptyStateLabel") is Label, "Sell app has empty state label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/SummaryPanel") is PanelContainer, "Sell app has summary panel")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/SummaryPanel/SummaryMargin/SummaryRow/SelectedValueLabel") is Label, "Sell app shows selected sale value")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/SummaryPanel/SummaryMargin/SummaryRow/SellSelectedButton") is Button, "Sell app summary has Sell Selected button")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/SummaryPanel/SummaryMargin/SummaryRow/SellAllButton") == null, "Sell app summary no longer has global Sell All button")

	var sell_selected_button := panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/SummaryPanel/SummaryMargin/SummaryRow/SellSelectedButton") as Button
	runner.assert_true(sell_selected_button != null and sell_selected_button.text == "Sell Selected", "Sell app summary action is labeled Sell Selected")

	var empty_label := panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/EmptyStateLabel") as Label
	runner.assert_true(empty_label != null and empty_label.text == "No products in storage.", "Sell app empty state text is user-facing")


func _assert_sell_row_layout(row: PanelContainer) -> void:
	runner.assert_true(row.custom_minimum_size.y >= 128.0, "Sell row reserves readable phone card height")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/TopRow/IconRect") is TextureRect, "Sell row has product icon")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/TopRow/InfoStack/NameLabel") is Label, "Sell row has product name")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/TopRow/InfoStack/AmountLabel") is Label, "Sell row has storage amount")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/TopRow/PriceStack/PriceLabel") is Label, "Sell row has unit price")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/TopRow/PriceStack/ValueLabel") is Label, "Sell row has selected value")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/QuantityRow/MinusButton") is Button, "Sell row has decrease button")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/QuantityRow/SelectedEdit") is LineEdit, "Sell row has editable selected amount field")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/QuantityRow/PlusButton") is Button, "Sell row has increase button")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/QuantityRow/HalfButton") is Button, "Sell row has Half button")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/QuantityRow/AllButton") is Button, "Sell row has All button")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/ActionRow/SubtotalLabel") is Label, "Sell row has subtotal label")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/ActionRow/SellButton") is Button, "Sell row has Sell button")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/ActionRow/SellAllButton") is Button, "Sell row has Sell All button")
	runner.assert_true(row.get_node_or_null("MarginContainer/CardStack/QuantityRow/SelectedLabel") == null, "Sell row no longer uses a non-editable selected amount label")
	runner.assert_true(row.get_node_or_null("SellOneButton") == null, "Sell row no longer has one-click SellOneButton")

	var selected_edit := row.get_node_or_null("MarginContainer/CardStack/QuantityRow/SelectedEdit") as LineEdit
	runner.assert_true(selected_edit != null and selected_edit.virtual_keyboard_type == LineEdit.KEYBOARD_TYPE_NUMBER, "Sell row quantity edit uses numeric keyboard")
