extends RefCounted

var runner: TestRunner
var wheat_crop: CropData = preload("res://Data/Crops/wheat_crop.tres")


func run() -> void:
	print("\n--- TileCropSaveTest ---")

	var world_manager = Engine.get_main_loop().root.get_tree().get_first_node_in_group("world_manager")

	if world_manager == null:
		runner.assert_true(false, "WorldManager exists for tile save test")
		return

	var tiles = world_manager.get_all_farm_tiles()

	if tiles.is_empty():
		runner.assert_true(false, "Farm tiles exist for tile save test")
		return

	var tile: FarmTile = tiles[0]

	tile.clear_crop()
	tile.set_state(FarmTile.TileState.WATERED)
	tile.load_crop(wheat_crop, 2)

	var save_data := SaveManager._create_world_save_data()

	tile.clear_crop()
	tile.set_state(FarmTile.TileState.GRASS)

	SaveManager._apply_world_save_data(save_data)

	var restored_tile: FarmTile = world_manager.get_tile_by_id(tile.tile_id)

	runner.assert_true(restored_tile != null, "Tile restored by id")
	runner.assert_eq(int(restored_tile.current_state), int(FarmTile.TileState.WATERED), "Tile state restored")
	runner.assert_true(restored_tile.has_crop(), "Crop restored on tile")
	runner.assert_eq(restored_tile.crop_data.crop_id, wheat_crop.crop_id, "Crop id restored")
	runner.assert_eq(restored_tile.crop_growth_days, 2, "Crop growth days restored")
