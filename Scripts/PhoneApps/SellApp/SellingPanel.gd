extends Control
class_name SellingPanel

@export var storage_data: StorageData
@export var row_scene: PackedScene

@onready var items_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ItemsContainer


func _ready() -> void:
	visible = false
	add_to_group("selling_panel")

	if storage_data and not storage_data.storage_changed.is_connected(refresh):
		storage_data.storage_changed.connect(refresh)

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

	for child in items_container.get_children():
		child.queue_free()

	var items := storage_data.get_all_items()

	for item_entry in items:
		var row := row_scene.instantiate() as SellingItemRow
		if row == null:
			continue

		items_container.add_child(row)

		var item_data := item_entry["item_data"] as ItemData
		var amount := int(item_entry["amount"])

		row.setup(item_data, amount)
		row.sell_one_requested.connect(_on_sell_one_requested)
		row.sell_all_requested.connect(_on_sell_all_requested)


func _on_sell_one_requested(item_data: ItemData) -> void:
	_sell_item(item_data, 1)


func _on_sell_all_requested(item_data: ItemData) -> void:
	if storage_data == null:
		return

	var amount := storage_data.get_item_amount(item_data)
	_sell_item(item_data, amount)


func _sell_item(item_data: ItemData, amount: int) -> void:
	if storage_data == null or item_data == null or amount <= 0:
		return

	if not storage_data.has_item(item_data, amount):
		return

	var sell_price := EconomyManager.get_sell_price(item_data)
	var total_value := sell_price * amount

	if not storage_data.remove_item(item_data, amount):
		return

	MoneyManager.add_money(total_value)

	refresh()
