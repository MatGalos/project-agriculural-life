extends Node

var wheat_crop_data: CropData = preload("res://Data/Crops/wheat_crop.tres")
var wheat_seed_item: SeedItemData = preload("res://Data/Items/Seeds/wheat_seed_item.tres")
var player_inventory: InventoryData = preload("res://Data/Inventory/player_inventory.tres")
var all_crops: Array[CropData] = [
	wheat_crop_data
]

func get_active_tool() -> ToolItemData:
	var item: ItemData = HotbarManager.get_selected_item()

	if item == null:
		return null

	if item is ToolItemData:
		return item as ToolItemData

	return null


func use_active_tool(target: Node) -> void:
	if target == null:
		return

	var item: ItemData = HotbarManager.get_selected_item()

	if item == null:
		return

	if item is SeedItemData:
		_use_seed_item(target, item as SeedItemData)
		return

	if item is ToolItemData:
		var tool: ToolItemData = item as ToolItemData

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
		return

	tile.plow()


func _use_watering_can(target: Node) -> void:
	var tile := _find_farm_tile(target)

	if tile == null:
		return

	tile.water()


func _find_farm_tile(target: Node) -> FarmTile:
	if target is FarmTile:
		return target as FarmTile

	var current := target

	while current != null:
		if current is FarmTile:
			return current as FarmTile

		current = current.get_parent()

	return null

func _use_seed_item(target: Node, seed_item: SeedItemData) -> void:
	var tile := _find_farm_tile(target)

	if tile == null:
		return

	if not tile.can_plant():
		return

	var crop_data := _get_crop_data_for_seed(seed_item)

	if crop_data == null:
		return

	if not player_inventory.has_item(seed_item, 1):
		print("No seeds")
		return

	var planted := tile.plant_crop(crop_data)

	if planted:
		player_inventory.remove_item(seed_item, 1)
		_refresh_inventory_ui()
		print("Planted ", crop_data.display_name)

func _get_crop_data_for_seed(seed_item: SeedItemData) -> CropData:
	if seed_item == null:
		return null

	for crop_data: CropData in all_crops:
		if crop_data == null:
			continue

		if crop_data.seed_item == seed_item or crop_data.crop_id == seed_item.crop_id:
			return crop_data

	return null

func _use_scythe(target: Node) -> void:
	var tile := _find_farm_tile(target)

	if tile == null:
		return

	if not tile.is_crop_ready():
		return

	var harvested_item := tile.harvest_crop()

	if harvested_item == null:
		return

	player_inventory.add_item(harvested_item, 1)
	_refresh_inventory_ui()

	print("Harvested ", harvested_item.display_name)

func _refresh_inventory_ui() -> void:
	var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")
	if inventory_panel:
		inventory_panel.refresh()

	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui:
		hotbar_ui.refresh()

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
			return "LPM - Plant " + item.display_name
		return ""
	
	if item is ToolItemData:
		var tool := item as ToolItemData
	
		match tool.tool_type:
			ToolItemData.ToolType.HOE:
				if tile.current_state == FarmTile.TileState.GRASS:
					return "LPM - Plow"
	
			ToolItemData.ToolType.WATERING_CAN:
				if tile.current_state == FarmTile.TileState.PLOWED:
					return "LPM - Water"
	
			ToolItemData.ToolType.SCYTHE:
				if tile.is_crop_ready():
					return "LPM - Harvest " + tile.get_crop_display_name()
	return ""
