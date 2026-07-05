extends Control
class_name ShopPanel

@export var shop_data: ShopData
@export var row_scene: PackedScene
@export var player_inventory: InventoryData

@onready var items_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ItemsScroll/ItemsContainer


func _ready() -> void:
	visible = false
	if not EconomyManager.buy_prices_changed.is_connected(_on_buy_prices_changed):
		EconomyManager.buy_prices_changed.connect(_on_buy_prices_changed)

	refresh()


func refresh() -> void:
	if shop_data == null or row_scene == null:
		return

	for child in items_container.get_children():
		child.queue_free()

	for shop_item in shop_data.get_available_items():
		var row := row_scene.instantiate() as ShopItemRow

		if row == null:
			continue

		items_container.add_child(row)
		row.setup(shop_item)
		row.buy_requested.connect(_on_buy_requested)


func _on_buy_requested(shop_item: ShopItemData) -> void:
	if shop_item == null or shop_item.item_data == null:
		return

	if player_inventory == null:
		return

	var item := shop_item.item_data
	var amount := shop_item.amount_per_purchase
	var price := EconomyManager.get_buy_price(item) * amount

	if not MoneyManager.spend_money(price):
		print("Not enough money")
		return

	var leftover := player_inventory.add_item(item, amount)

	if leftover > 0:
		MoneyManager.add_money(price)
		print("Inventory full")
		return

	_refresh_game_ui()
	refresh()


func _on_buy_prices_changed() -> void:
	refresh()


func _refresh_game_ui() -> void:
	var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")
	if inventory_panel:
		inventory_panel.refresh()

	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui:
		hotbar_ui.refresh()
