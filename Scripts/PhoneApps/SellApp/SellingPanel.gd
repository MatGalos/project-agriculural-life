extends Control
class_name SellingPanel

const COLOR_SUCCESS := Color(0.37, 0.86, 0.52, 1.0)
const COLOR_ERROR := Color(0.95, 0.36, 0.36, 1.0)
const COLOR_NEUTRAL := Color(0.86, 0.88, 0.9, 1.0)

@export var storage_data: StorageData
@export var row_scene: PackedScene

@onready var feedback_label: Label = $PanelContainer/MarginContainer/RootStack/FeedbackLabel
@onready var items_container: VBoxContainer = $PanelContainer/MarginContainer/RootStack/ItemsScroll/ItemsContainer
@onready var empty_state_label: Label = $PanelContainer/MarginContainer/RootStack/EmptyStateLabel
@onready var selected_value_label: Label = $PanelContainer/MarginContainer/RootStack/SummaryPanel/SummaryMargin/SummaryRow/SelectedValueLabel
@onready var sell_selected_button: Button = $PanelContainer/MarginContainer/RootStack/SummaryPanel/SummaryMargin/SummaryRow/SellSelectedButton

var selected_sell_quantities: Dictionary = {}
var _is_refreshing := false


func _ready() -> void:
	visible = false
	add_to_group("selling_panel")

	if storage_data and not storage_data.storage_changed.is_connected(refresh):
		storage_data.storage_changed.connect(refresh)

	if not CommodityMarketManager.commodity_prices_updated.is_connected(_on_commodity_prices_updated):
		CommodityMarketManager.commodity_prices_updated.connect(_on_commodity_prices_updated)

	sell_selected_button.pressed.connect(sell_selected_products)
	refresh()


func open() -> void:
	refresh()
	visible = true


func close() -> void:
	visible = false


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func refresh() -> void:
	if storage_data == null or row_scene == null:
		return

	_is_refreshing = true

	for child in items_container.get_children():
		child.queue_free()

	var items := storage_data.get_all_items()
	var has_items := false
	var live_item_ids: Array[String] = []

	for item_entry in items:
		var item_data := item_entry["item_data"] as ItemData
		var amount := int(item_entry["amount"])

		if item_data == null or amount <= 0:
			continue

		has_items = true
		live_item_ids.append(item_data.id)

		var selected_amount := clampi(int(selected_sell_quantities.get(item_data.id, 0)), 0, amount)
		selected_sell_quantities[item_data.id] = selected_amount

		var row := row_scene.instantiate() as SellingItemRow
		if row == null:
			continue

		items_container.add_child(row)
		row.setup(item_data, amount, selected_amount)
		row.quantity_changed.connect(_on_row_quantity_changed)
		row.sell_requested.connect(_on_sell_requested)
		row.sell_all_requested.connect(_on_sell_all_requested)

	_remove_missing_selections(live_item_ids)
	empty_state_label.visible = not has_items
	_is_refreshing = false
	_update_summary()


func set_sell_quantity(item_id: String, quantity: int) -> void:
	if storage_data == null:
		return

	var item_data := storage_data.get_item_by_id(item_id)
	if item_data == null:
		selected_sell_quantities.erase(item_id)
		_update_summary()
		return

	var available := storage_data.get_item_amount(item_data)
	var clamped_quantity := clampi(quantity, 0, available)

	if clamped_quantity <= 0:
		selected_sell_quantities.erase(item_id)
	else:
		selected_sell_quantities[item_id] = clamped_quantity

	_update_summary()


func increase_sell_quantity(item_id: String, amount: int = 1) -> void:
	set_sell_quantity(item_id, int(selected_sell_quantities.get(item_id, 0)) + maxi(amount, 1))


func decrease_sell_quantity(item_id: String, amount: int = 1) -> void:
	set_sell_quantity(item_id, int(selected_sell_quantities.get(item_id, 0)) - maxi(amount, 1))


func set_half_quantity(item_id: String) -> void:
	if storage_data == null:
		return

	var item_data := storage_data.get_item_by_id(item_id)
	if item_data:
		set_sell_quantity(item_id, int(floor(float(storage_data.get_item_amount(item_data)) / 2.0)))


func set_all_quantity(item_id: String) -> void:
	if storage_data == null:
		return

	var item_data := storage_data.get_item_by_id(item_id)
	if item_data:
		set_sell_quantity(item_id, storage_data.get_item_amount(item_data))


func get_sell_value(item_id: String) -> int:
	if storage_data == null:
		return 0

	var item_data := storage_data.get_item_by_id(item_id)
	if item_data == null:
		return 0

	return EconomyManager.get_sell_price(item_data) * int(selected_sell_quantities.get(item_id, 0))


func get_total_selected_value() -> int:
	var total := 0

	for item_id in selected_sell_quantities.keys():
		total += get_sell_value(String(item_id))

	return total


func _on_row_quantity_changed(item_id: String, quantity: int) -> void:
	if _is_refreshing:
		return

	set_sell_quantity(item_id, quantity)
	_set_feedback("", COLOR_NEUTRAL)


func _on_commodity_prices_updated() -> void:
	refresh()


func _on_sell_requested(item_data: ItemData, amount: int) -> void:
	sell_product(item_data, amount)


func _on_sell_all_requested(item_data: ItemData) -> void:
	if storage_data == null or item_data == null:
		return

	sell_product(item_data, storage_data.get_item_amount(item_data))


func sell_product(item_data: ItemData, amount: int) -> void:
	if storage_data == null or item_data == null:
		UISoundManager.play_action_error()
		_set_feedback("Storage is empty.", COLOR_ERROR)
		return

	if amount <= 0:
		UISoundManager.play_action_error()
		_set_feedback("Select an amount to sell.", COLOR_ERROR)
		return

	var available := storage_data.get_item_amount(item_data)

	if available <= 0:
		UISoundManager.play_action_error()
		_set_feedback("Storage is empty.", COLOR_ERROR)
		selected_sell_quantities.erase(item_data.id)
		refresh()
		return

	if amount > available:
		UISoundManager.play_action_error()
		_set_feedback("Not enough items.", COLOR_ERROR)
		set_sell_quantity(item_data.id, available)
		refresh()
		return

	var sell_price := EconomyManager.get_sell_price(item_data)
	var total_value := sell_price * amount

	if not storage_data.remove_item(item_data, amount):
		UISoundManager.play_action_error()
		_set_feedback("Not enough items.", COLOR_ERROR)
		refresh()
		return

	MoneyManager.add_money(total_value)
	SalesStatsManager.record_sale(item_data, amount)
	UISoundManager.play_sell_item()
	selected_sell_quantities.erase(item_data.id)
	_refresh_game_ui()
	refresh()
	_set_feedback("Sold %dx %s for %s." % [
		amount,
		UIFormatHelper.display_product_name(item_data),
		UIFormatHelper.money_int(total_value)
	], COLOR_SUCCESS)


func sell_selected_products() -> void:
	if storage_data == null:
		UISoundManager.play_action_error()
		_set_feedback("Storage is empty.", COLOR_ERROR)
		return

	var sale_requests: Array[Dictionary] = []

	for item_id in selected_sell_quantities.keys():
		var item_data := storage_data.get_item_by_id(String(item_id))
		var amount := int(selected_sell_quantities.get(item_id, 0))

		if item_data == null or amount <= 0:
			continue

		var available := storage_data.get_item_amount(item_data)

		if available <= 0:
			continue

		sale_requests.append({
			"item_data": item_data,
			"amount": mini(amount, available)
		})

	if sale_requests.is_empty():
		UISoundManager.play_action_error()
		_set_feedback("Select an amount to sell.", COLOR_ERROR)
		refresh()
		return

	var sold_items := 0
	var total_value := 0

	for sale_request in sale_requests:
		var item_data := sale_request["item_data"] as ItemData
		var amount := int(sale_request["amount"])

		var sell_price := EconomyManager.get_sell_price(item_data)
		var item_value := sell_price * amount

		if not storage_data.remove_item(item_data, amount):
			continue

		MoneyManager.add_money(item_value)
		SalesStatsManager.record_sale(item_data, amount)
		sold_items += amount
		total_value += item_value

	if sold_items <= 0:
		UISoundManager.play_action_error()
		_set_feedback("Not enough items.", COLOR_ERROR)
		refresh()
		return

	selected_sell_quantities.clear()
	_refresh_game_ui()
	refresh()
	UISoundManager.play_sell_item()
	_set_feedback("Sold selected items for %s." % UIFormatHelper.money_int(total_value), COLOR_SUCCESS)


func _remove_missing_selections(live_item_ids: Array[String]) -> void:
	for item_id in selected_sell_quantities.keys():
		if not live_item_ids.has(String(item_id)):
			selected_sell_quantities.erase(item_id)


func _update_summary() -> void:
	var selected_value := get_total_selected_value()
	selected_value_label.text = "Selected value: %s" % UIFormatHelper.money_int(selected_value)
	sell_selected_button.disabled = selected_value <= 0


func _set_feedback(message: String, color: Color) -> void:
	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", color)


func _refresh_game_ui() -> void:
	var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")
	if inventory_panel:
		inventory_panel.refresh()

	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui:
		hotbar_ui.refresh()
