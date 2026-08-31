extends RefCounted

var runner: TestRunner
var tomato_crop: CropData = preload("res://Data/Crops/tomatoe_crop.tres")
var wheat_crop: CropData = preload("res://Data/Crops/wheat_crop.tres")


func run() -> void:
	print("\n--- ToolManagerHarvestTest ---")

	var saved_inventory := ToolManager.player_inventory
	var saved_current_weather := WeatherManager.current_weather

	WeatherManager.current_weather = WeatherManager.get_weather_by_name("Sunny")

	_test_harvest_amount_three_adds_three_products_and_removes_crop()
	_test_harvest_without_room_for_full_amount_does_not_partially_add()
	_test_harvest_amount_one_still_adds_one_product()

	ToolManager.player_inventory = saved_inventory
	WeatherManager.current_weather = saved_current_weather


func _test_harvest_amount_three_adds_three_products_and_removes_crop() -> void:
	var inventory := _make_inventory(1)
	ToolManager.player_inventory = inventory

	var tile := _make_ready_tile(tomato_crop)
	ToolManager._use_scythe(tile)

	runner.assert_eq(
		inventory.get_item_count(tomato_crop.harvest_item),
		3,
		"Harvest amount 3 adds three products"
	)
	runner.assert_true(not tile.has_crop(), "Successful harvest removes crop from tile")
	tile.free()


func _test_harvest_without_room_for_full_amount_does_not_partially_add() -> void:
	var inventory := _make_inventory(1)
	var harvest_item := tomato_crop.harvest_item
	var starting_amount := harvest_item.max_stack - 1
	var slot := inventory.get_slot(0)
	slot.item_data = harvest_item
	slot.amount = starting_amount
	ToolManager.player_inventory = inventory

	var tile := _make_ready_tile(tomato_crop)
	ToolManager._use_scythe(tile)

	runner.assert_true(tile.has_crop(), "Harvest without room for full amount leaves crop on tile")
	runner.assert_eq(
		inventory.get_item_count(harvest_item),
		starting_amount,
		"Harvest without room for full amount does not partially add products"
	)
	tile.free()


func _test_harvest_amount_one_still_adds_one_product() -> void:
	var inventory := _make_inventory(1)
	ToolManager.player_inventory = inventory

	var tile := _make_ready_tile(wheat_crop)
	ToolManager._use_scythe(tile)

	runner.assert_eq(
		inventory.get_item_count(wheat_crop.harvest_item),
		1,
		"Harvest amount 1 still adds one product"
	)
	runner.assert_true(not tile.has_crop(), "Harvest amount 1 removes crop from tile")
	tile.free()


func _make_inventory(slot_count: int) -> InventoryData:
	var inventory := InventoryData.new()
	inventory.slot_count = slot_count
	inventory.setup()
	return inventory


func _make_ready_tile(crop_data: CropData) -> FarmTile:
	var tile := FarmTile.new()
	tile.set_state(FarmTile.TileState.PLOWED)
	tile.crop_data = crop_data
	tile.crop_growth_days = crop_data.days_to_ready
	return tile
