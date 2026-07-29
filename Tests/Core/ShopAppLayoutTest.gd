extends RefCounted

var runner: TestRunner

const SHOP_PANEL_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/ShopApp/shop_Panel.tscn")
const SHOP_ROW_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/ShopApp/shop_item_row.tscn")
const CART_ROW_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/ShopApp/shop_cart_row.tscn")


func run() -> void:
	print("\n--- ShopAppLayoutTest ---")

	var panel := SHOP_PANEL_SCENE.instantiate() as Control
	runner.assert_true(panel != null, "Shop app scene instantiates")

	if panel:
		_assert_shop_panel_layout(panel)
		panel.free()

	var row := SHOP_ROW_SCENE.instantiate() as PanelContainer
	runner.assert_true(row != null, "Shop product row scene instantiates as card row")

	if row:
		_assert_product_row_layout(row)
		row.free()

	var cart_row := CART_ROW_SCENE.instantiate() as PanelContainer
	runner.assert_true(cart_row != null, "Shop cart row scene instantiates as card row")

	if cart_row:
		_assert_cart_row_layout(cart_row)
		cart_row.free()


func _assert_shop_panel_layout(panel: Control) -> void:
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/HeaderRow/TitleLabel") is Label, "Shop app has title label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/HeaderRow/MoneyLabel") is Label, "Shop app shows available money")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/FeedbackLabel") is Label, "Shop app has feedback label")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ItemsScroll") is ScrollContainer, "Shop app product list uses scroll container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/ItemsScroll/ItemsContainer") is VBoxContainer, "Shop app has product list container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel") is PanelContainer, "Shop app has cart panel")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartHeaderRow/ToggleCartButton") is Button, "Shop cart has collapse toggle button")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartHeaderRow/ClearButton") is Button, "Shop cart has clear button")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartBody") is VBoxContainer, "Shop cart has collapsible body")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartBody/CartScroll") is ScrollContainer, "Shop cart uses scroll container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartBody/CartScroll/CartItemsContainer") is VBoxContainer, "Shop cart has item list container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/TotalsRow/TotalLabel") is Label, "Shop cart shows total")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/TotalsRow/AvailableLabel") is Label, "Shop cart shows available money")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/PurchaseButton") is Button, "Shop cart has Purchase button")

	var purchase_button := panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/PurchaseButton") as Button
	runner.assert_true(purchase_button != null and purchase_button.text == "Purchase", "Shop checkout button uses Purchase label")

	var toggle_button := panel.get_node_or_null("PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartHeaderRow/ToggleCartButton") as Button
	runner.assert_true(toggle_button != null and toggle_button.text == "v", "Shop cart expanded state uses down caret")

	if panel.has_method("_on_toggle_cart_pressed"):
		panel.call("_on_toggle_cart_pressed")
		runner.assert_true(toggle_button != null and toggle_button.text == "^", "Shop cart collapsed state uses up caret")


func _assert_product_row_layout(row: PanelContainer) -> void:
	runner.assert_true(row.custom_minimum_size.y >= 62.0, "Shop product row reserves readable phone height")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/IconRect") is TextureRect, "Shop product row has seed icon")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/InfoStack/NameLabel") is Label, "Shop product row has seed name")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/InfoStack/MetaLabel") is Label, "Shop product row has owned count")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/ActionStack/PriceLabel") is Label, "Shop product row has unit price")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/ActionStack/AddButton") is Button, "Shop product row has Add button")
	runner.assert_true(row.get_node_or_null("BuyButton") == null, "Shop product row no longer has immediate Buy button")


func _assert_cart_row_layout(row: PanelContainer) -> void:
	runner.assert_true(row.custom_minimum_size.y >= 58.0, "Shop cart row reserves readable phone height")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/InfoStack/NameLabel") is Label, "Shop cart row has item name")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/InfoStack/SubtotalLabel") is Label, "Shop cart row has subtotal text")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/ControlsRow/MinusButton") is Button, "Shop cart row has decrease button")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/ControlsRow/QuantityEdit") is LineEdit, "Shop cart row has editable quantity field")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/ControlsRow/PlusButton") is Button, "Shop cart row has increase button")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/ControlsRow/RemoveButton") is Button, "Shop cart row has remove button")
