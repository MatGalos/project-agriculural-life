extends Node

func get_active_tool() -> ToolItemData:
	var item := HotbarManager.get_selected_item()

	if item == null:
		return null

	if item is ToolItemData:
		return item as ToolItemData

	return null


func use_active_tool(target: Node) -> void:
	var tool := get_active_tool()

	if tool == null:
		return

	if target == null:
		return

	match tool.tool_type:
		ToolItemData.ToolType.HOE:
			_use_hoe(target)

		ToolItemData.ToolType.WATERING_CAN:
			_use_watering_can(target)

		ToolItemData.ToolType.SEED_BAG:
			print("Seed Bag use later")

		ToolItemData.ToolType.SCYTHE:
			print("Scythe use later")


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
