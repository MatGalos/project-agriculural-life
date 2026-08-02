extends Node

signal watering_can_changed

var wheat_crop_data: CropData = preload("res://Data/Crops/wheat_crop.tres")
var wheat_seed_item: SeedItemData = preload("res://Data/Items/Seeds/wheat_seed_item.tres")
var player_inventory: InventoryData = preload("res://Data/Inventory/player_inventory.tres")
var all_crops: Array[CropData] = [
	preload("res://Data/Crops/beetroot_crop.tres"),
	preload("res://Data/Crops/cabbage_crop.tres"),
	preload("res://Data/Crops/carrot_crop.tres"),
	preload("res://Data/Crops/corn_crop.tres"),
	preload("res://Data/Crops/lettuce_crop.tres"),
	preload("res://Data/Crops/potatoe_crop.tres"),
	preload("res://Data/Crops/pumpkin_crop.tres"),
	preload("res://Data/Crops/strawberry_crop.tres"),
	preload("res://Data/Crops/tomatoe_crop.tres"),
	wheat_crop_data
]
var watering_can_water := 0
var watering_can_capacity := 10


func get_active_tool() -> ToolItemData:
	var item: ItemData = HotbarManager.get_selected_item()

	if item is ToolItemData:
		return item as ToolItemData

	return null


func use_active_tool(target: Node) -> void:
	if target == null:
		_show_hud_event_message("Nothing to interact with.")
		return

	var item: ItemData = HotbarManager.get_selected_item()

	if item == null:
		_show_hud_event_message("No tool selected.")
		return

	if item is SeedItemData:
		_use_seed_item(target, item as SeedItemData)
		return

	if item is ToolItemData:
		_use_tool_item(target, item as ToolItemData)
		return

	_show_hud_event_message("Cannot use this here.")


func refill_watering_can() -> void:
	watering_can_water = watering_can_capacity
	watering_can_changed.emit()
	_show_hud_event_message("Watering can filled.")


func get_tool_prompt_for_target(target: Node) -> String:
	if target == null:
		return ""

	var item: ItemData = HotbarManager.get_selected_item()
	if item == null:
		return ""

	var tile := _find_farm_tile(target)
	if tile == null:
		return ""

	if item is SeedItemData:
		if tile.can_plant():
			return "LMB — Plant %s" % UIFormatHelper.display_seed_name(item)
		return ""

	if item is ToolItemData:
		return _get_tool_item_prompt(tile, item as ToolItemData)

	return ""


func _use_tool_item(target: Node, tool: ToolItemData) -> void:
	match tool.tool_type:
		ToolItemData.ToolType.HOE:
			_use_hoe(target)
		ToolItemData.ToolType.WATERING_CAN:
			_use_watering_can(target)
		ToolItemData.ToolType.SEED_BAG:
			_use_seed_item(target, wheat_seed_item)
		ToolItemData.ToolType.SCYTHE:
			_use_scythe(target)


func _use_hoe(target: Node) -> void:
	var tile := _find_farm_tile(target)

	if tile == null:
		_show_hud_event_message("Cannot use this here.")
		return

	if tile.current_state != FarmTile.TileState.GRASS:
		_show_hud_event_message("Cannot use this here.")
		return

	tile.plow()


func _use_watering_can(target: Node) -> void:
	var tile := _find_farm_tile(target)

	if tile == null:
		_show_hud_event_message("Cannot use this here.")
		return

	if watering_can_water <= 0:
		_show_hud_event_message("Need a watering can.")
		return

	if tile.current_state != FarmTile.TileState.PLOWED:
		_show_hud_event_message("Cannot use this here.")
		return

	tile.water()
	watering_can_water -= 1
	watering_can_changed.emit()


func _use_seed_item(target: Node, seed_item: SeedItemData) -> void:
	var tile := _find_farm_tile(target)

	if tile == null:
		_show_hud_event_message("Cannot plant here.")
		return

	if not tile.can_plant():
		_show_hud_event_message("Cannot plant here.")
		return

	var crop_data := _get_crop_data_for_seed(seed_item)

	if crop_data == null:
		_show_hud_event_message("No seeds selected.")
		return

	if not crop_data.can_grow_in_current_season():
		var message := "Cannot plant %s in %s" % [
			crop_data.display_name,
			TimeManager.get_current_season_display_name()
		]
		print(message)
		_show_hud_event_message(message)
		return

	if not player_inventory.has_item(seed_item, 1):
		_show_hud_event_message("No seeds selected.")
		return

	if tile.plant_crop(crop_data):
		player_inventory.remove_item(seed_item, 1)
		_refresh_inventory_ui()
		_show_hud_event_message("Used 1x %s." % UIFormatHelper.display_seed_name(seed_item))


func _use_scythe(target: Node) -> void:
	var tile := _find_farm_tile(target)

	if tile == null:
		_show_hud_event_message("Cannot harvest this.")
		return

	if not tile.is_crop_ready():
		_show_hud_event_message("Crop is not ready.")
		return

	var expected_item: ItemData = tile.crop_data.harvest_item if tile.crop_data != null else null
	if expected_item == null:
		_show_hud_event_message("Cannot harvest this.")
		return

	if not _can_inventory_fit(expected_item, 1):
		_show_hud_event_message("Inventory is full.")
		return

	var harvested_item := tile.harvest_crop()

	if harvested_item == null:
		_show_hud_event_message("Cannot harvest this.")
		return

	player_inventory.add_item(harvested_item, 1)
	_refresh_inventory_ui()
	_show_hud_event_message("Added 1x %s." % UIFormatHelper.display_product_name(harvested_item))


func _can_inventory_fit(item_data: ItemData, amount: int) -> bool:
	if player_inventory == null or item_data == null or amount <= 0:
		return false

	player_inventory.setup()
	var remaining := amount

	for slot in player_inventory.slots:
		if slot == null or slot.is_empty() or slot.item_data != item_data:
			continue

		remaining -= maxi(item_data.max_stack - slot.amount, 0)

		if remaining <= 0:
			return true

	for slot in player_inventory.slots:
		if slot != null and slot.is_empty():
			remaining -= item_data.max_stack

			if remaining <= 0:
				return true

	return false


func _find_farm_tile(target: Node) -> FarmTile:
	if target is FarmTile:
		return target as FarmTile

	var current := target

	while current != null:
		if current is FarmTile:
			return current as FarmTile

		current = current.get_parent()

	return null


func _get_crop_data_for_seed(seed_item: SeedItemData) -> CropData:
	if seed_item == null:
		return null

	for crop_data: CropData in all_crops:
		if crop_data == null:
			continue

		if crop_data.seed_item == seed_item or crop_data.crop_id == seed_item.crop_id:
			return crop_data

	return null


func _get_tool_item_prompt(tile: FarmTile, tool: ToolItemData) -> String:
	match tool.tool_type:
		ToolItemData.ToolType.HOE:
			if tile.current_state == FarmTile.TileState.GRASS:
				return "LMB — Plow"
		ToolItemData.ToolType.WATERING_CAN:
			if tile.current_state == FarmTile.TileState.PLOWED and watering_can_water > 0:
				return "LMB — Water"
		ToolItemData.ToolType.SCYTHE:
			if tile.is_crop_ready():
				return "LMB — Harvest %s" % UIFormatHelper.display_product_name(tile.get_crop_display_name())

	return ""


func _refresh_inventory_ui() -> void:
	var inventory_panel := get_tree().get_first_node_in_group("inventory_panel")
	if inventory_panel and inventory_panel.has_method("refresh"):
		inventory_panel.refresh()

	var hotbar_ui := get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui and hotbar_ui.has_method("refresh"):
		hotbar_ui.refresh()


func _show_hud_event_message(message: String) -> void:
	var player_hud := get_tree().get_first_node_in_group("player_hud")
	if player_hud and player_hud.has_method("show_event_message"):
		player_hud.show_event_message(message)
