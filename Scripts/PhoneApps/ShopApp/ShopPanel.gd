extends Control
class_name ShopPanel

const COLOR_SUCCESS := Color(0.37, 0.86, 0.52, 1.0)
const COLOR_ERROR := Color(0.95, 0.36, 0.36, 1.0)
const COLOR_NEUTRAL := Color(0.86, 0.88, 0.9, 1.0)
const CART_EXPANDED_HEIGHT := 190.0
const CART_COLLAPSED_HEIGHT := 108.0

@export var shop_data: ShopData
@export var row_scene: PackedScene
@export var cart_row_scene: PackedScene
@export var player_inventory: InventoryData

@onready var money_label: Label = $PanelContainer/MarginContainer/RootStack/HeaderRow/MoneyLabel
@onready var feedback_label: Label = $PanelContainer/MarginContainer/RootStack/FeedbackLabel
@onready var items_container: VBoxContainer = $PanelContainer/MarginContainer/RootStack/ItemsScroll/ItemsContainer
@onready var cart_panel: PanelContainer = $PanelContainer/MarginContainer/RootStack/CartPanel
@onready var toggle_cart_button: Button = $PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartHeaderRow/ToggleCartButton
@onready var clear_button: Button = $PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartHeaderRow/ClearButton
@onready var cart_body: VBoxContainer = $PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartBody
@onready var cart_items_container: VBoxContainer = $PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartBody/CartScroll/CartItemsContainer
@onready var cart_empty_label: Label = $PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/CartBody/CartEmptyLabel
@onready var total_label: Label = $PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/TotalsRow/TotalLabel
@onready var available_label: Label = $PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/TotalsRow/AvailableLabel
@onready var purchase_button: Button = $PanelContainer/MarginContainer/RootStack/CartPanel/CartMargin/CartStack/PurchaseButton

var cart: Dictionary = {}
var _shop_item_by_id: Dictionary = {}
var _is_cart_collapsed := false


func _ready() -> void:
	visible = false
	toggle_cart_button.pressed.connect(_on_toggle_cart_pressed)
	clear_button.pressed.connect(clear_cart)
	purchase_button.pressed.connect(purchase_cart)

	if not EconomyManager.buy_prices_changed.is_connected(_on_buy_prices_changed):
		EconomyManager.buy_prices_changed.connect(_on_buy_prices_changed)

	if not MoneyManager.money_changed.is_connected(_on_money_changed):
		MoneyManager.money_changed.connect(_on_money_changed)

	refresh()


func refresh() -> void:
	_rebuild_shop_item_lookup()
	refresh_product_list()
	refresh_cart_view()


func refresh_product_list() -> void:
	if shop_data == null or row_scene == null:
		return

	for child in items_container.get_children():
		child.queue_free()

	for shop_item in shop_data.get_available_items():
		if shop_item == null or shop_item.item_data == null:
			continue

		var row := row_scene.instantiate() as ShopItemRow

		if row == null:
			continue

		items_container.add_child(row)
		row.setup(shop_item, _get_owned_count(shop_item.item_data))
		row.add_requested.connect(add_to_cart)


func refresh_cart_view() -> void:
	for child in cart_items_container.get_children():
		child.queue_free()

	var has_items := false

	if cart_row_scene != null:
		for item_id in cart.keys():
			var quantity := int(cart[item_id])

			if quantity <= 0:
				continue

			var shop_item := _get_shop_item(item_id)

			if shop_item == null or shop_item.item_data == null:
				continue

			var row := cart_row_scene.instantiate() as ShopCartRow

			if row == null:
				continue

			has_items = true
			cart_items_container.add_child(row)
			row.setup(shop_item.item_data, quantity, EconomyManager.get_buy_price(shop_item.item_data))
			row.quantity_changed.connect(_on_cart_quantity_changed)
			row.quantity_set.connect(_on_cart_quantity_set)
			row.remove_requested.connect(_on_cart_remove_requested)

	cart_empty_label.visible = not has_items
	clear_button.disabled = cart.is_empty()
	_apply_cart_collapsed_state()
	_update_summary()


func add_to_cart(shop_item: ShopItemData, amount: int = 1) -> void:
	if shop_item == null or shop_item.item_data == null:
		return

	var item_id := shop_item.item_data.id
	var current_quantity := int(cart.get(item_id, 0))
	cart[item_id] = current_quantity + maxi(amount, 1)

	_set_feedback("", COLOR_NEUTRAL)
	refresh_cart_view()


func remove_from_cart(item_id: String, amount: int = 1) -> void:
	if not cart.has(item_id):
		return

	var next_quantity := int(cart[item_id]) - maxi(amount, 1)

	if next_quantity <= 0:
		cart.erase(item_id)
	else:
		cart[item_id] = next_quantity

	refresh_cart_view()


func clear_cart() -> void:
	if cart.is_empty():
		return

	cart.clear()
	_set_feedback("", COLOR_NEUTRAL)
	refresh_cart_view()


func get_cart_total() -> int:
	var total := 0

	for item_id in cart.keys():
		var shop_item := _get_shop_item(item_id)

		if shop_item == null or shop_item.item_data == null:
			continue

		total += EconomyManager.get_buy_price(shop_item.item_data) * int(cart[item_id])

	return total


func can_afford_cart() -> bool:
	return MoneyManager.can_afford(get_cart_total())


func purchase_cart() -> void:
	if cart.is_empty():
		UISoundManager.play_action_error()
		_set_feedback("Cart is empty.", COLOR_ERROR)
		_update_summary()
		return

	var total := get_cart_total()

	if total <= 0:
		UISoundManager.play_action_error()
		_set_feedback("Cart is empty.", COLOR_ERROR)
		_update_summary()
		return

	if not MoneyManager.can_afford(total):
		UISoundManager.play_action_error()
		_set_feedback("Not enough money.", COLOR_ERROR)
		_update_summary()
		return

	if player_inventory == null or not _can_fit_cart():
		UISoundManager.play_action_error()
		_set_feedback("Inventory is full.", COLOR_ERROR)
		_update_summary()
		return

	if not MoneyManager.spend_money(total):
		UISoundManager.play_action_error()
		_set_feedback("Not enough money.", COLOR_ERROR)
		_update_summary()
		return

	var added_items: Array[Dictionary] = []

	for item_id in cart.keys():
		var shop_item := _get_shop_item(item_id)

		if shop_item == null or shop_item.item_data == null:
			continue

		var requested_amount := int(cart[item_id])
		var leftover := player_inventory.add_item(shop_item.item_data, requested_amount)
		var added_amount := requested_amount - leftover

		if added_amount > 0:
			added_items.append({
				"item": shop_item.item_data,
				"amount": added_amount
			})

		if leftover > 0:
			_rollback_added_items(added_items)
			MoneyManager.add_money(total)
			UISoundManager.play_action_error()
			_set_feedback("Could not add items to inventory.", COLOR_ERROR)
			refresh()
			return

	var item_count := _get_cart_item_count()
	cart.clear()
	_refresh_game_ui()
	refresh()
	UISoundManager.play_buy_item()
	_set_feedback("Bought %d items for %s." % [item_count, UIFormatHelper.money_int(total)], COLOR_SUCCESS)


func _rebuild_shop_item_lookup() -> void:
	_shop_item_by_id.clear()

	if shop_data == null:
		return

	for shop_item in shop_data.get_available_items():
		if shop_item == null or shop_item.item_data == null:
			continue

		_shop_item_by_id[shop_item.item_data.id] = shop_item


func _get_shop_item(item_id: String) -> ShopItemData:
	return _shop_item_by_id.get(item_id, null) as ShopItemData


func _get_owned_count(item_data: ItemData) -> int:
	if player_inventory == null or item_data == null:
		return 0

	return player_inventory.get_item_count(item_data)


func _can_fit_cart() -> bool:
	if player_inventory == null:
		return false

	var remaining_by_id: Dictionary = {}
	var item_by_id: Dictionary = {}

	for item_id in cart.keys():
		var shop_item := _get_shop_item(item_id)

		if shop_item == null or shop_item.item_data == null:
			continue

		remaining_by_id[item_id] = int(cart[item_id])
		item_by_id[item_id] = shop_item.item_data

	player_inventory.setup()

	for slot in player_inventory.slots:
		if slot == null or slot.is_empty():
			continue

		var slot_item := slot.item_data

		if slot_item == null or not remaining_by_id.has(slot_item.id):
			continue

		var remaining := int(remaining_by_id[slot_item.id])
		var space_left := maxi(slot_item.max_stack - slot.amount, 0)
		remaining_by_id[slot_item.id] = maxi(remaining - space_left, 0)

	for slot in player_inventory.slots:
		if slot == null or not slot.is_empty():
			continue

		var target_id := _get_first_remaining_item_id(remaining_by_id)

		if target_id.is_empty():
			return true

		var item_data := item_by_id.get(target_id, null) as ItemData

		if item_data == null:
			return false

		var remaining := int(remaining_by_id[target_id])
		remaining_by_id[target_id] = maxi(remaining - item_data.max_stack, 0)

	return _get_first_remaining_item_id(remaining_by_id).is_empty()


func _get_first_remaining_item_id(remaining_by_id: Dictionary) -> String:
	for item_id in remaining_by_id.keys():
		if int(remaining_by_id[item_id]) > 0:
			return String(item_id)

	return ""


func _get_cart_item_count() -> int:
	var total := 0

	for item_id in cart.keys():
		total += int(cart[item_id])

	return total


func _rollback_added_items(added_items: Array[Dictionary]) -> void:
	if player_inventory == null:
		return

	for entry in added_items:
		var item := entry.get("item", null) as ItemData
		var amount := int(entry.get("amount", 0))

		if item != null and amount > 0:
			player_inventory.remove_item(item, amount)


func _update_summary() -> void:
	var total := get_cart_total()
	var money := MoneyManager.get_money()
	var can_purchase := not cart.is_empty() and total > 0 and money >= total

	money_label.text = UIFormatHelper.money_int(money)
	total_label.text = "Total: %s" % UIFormatHelper.money_int(total)
	available_label.text = "Available: %s" % UIFormatHelper.money_int(money)
	purchase_button.disabled = not can_purchase

	if not cart.is_empty() and money < total:
		_set_feedback("Not enough money.", COLOR_ERROR)
	elif feedback_label.text == "Not enough money.":
		_set_feedback("", COLOR_NEUTRAL)


func _set_feedback(message: String, color: Color) -> void:
	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", color)


func _apply_cart_collapsed_state() -> void:
	cart_body.visible = not _is_cart_collapsed
	toggle_cart_button.text = "^" if _is_cart_collapsed else "v"
	cart_panel.custom_minimum_size.y = CART_COLLAPSED_HEIGHT if _is_cart_collapsed else CART_EXPANDED_HEIGHT


func _on_toggle_cart_pressed() -> void:
	_is_cart_collapsed = not _is_cart_collapsed
	_apply_cart_collapsed_state()


func _on_cart_quantity_changed(item_id: String, delta: int) -> void:
	if delta > 0:
		var shop_item := _get_shop_item(item_id)
		add_to_cart(shop_item, delta)
	elif delta < 0:
		remove_from_cart(item_id, abs(delta))


func _on_cart_quantity_set(item_id: String, quantity: int) -> void:
	if quantity <= 0:
		cart.erase(item_id)
	else:
		cart[item_id] = quantity

	_set_feedback("", COLOR_NEUTRAL)
	refresh_cart_view()


func _on_cart_remove_requested(item_id: String) -> void:
	if cart.has(item_id):
		cart.erase(item_id)
		refresh_cart_view()


func _on_buy_prices_changed() -> void:
	refresh()


func _on_money_changed(_new_amount: int) -> void:
	_update_summary()


func _refresh_game_ui() -> void:
	var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")
	if inventory_panel:
		inventory_panel.refresh()

	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui:
		hotbar_ui.refresh()
