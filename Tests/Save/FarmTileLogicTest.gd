extends RefCounted

var runner: TestRunner
var wheat_crop: CropData = preload("res://Data/Crops/wheat_crop.tres")


func run() -> void:
	print("\n--- FarmTileLogicTest ---")

	var tile := FarmTile.new()

	tile.set_state(FarmTile.TileState.GRASS)
	runner.assert_eq(int(tile.current_state), int(FarmTile.TileState.GRASS), "Tile starts as grass")

	tile.plow()
	runner.assert_eq(int(tile.current_state), int(FarmTile.TileState.PLOWED), "Tile plow changes state")

	tile.water()
	runner.assert_eq(int(tile.current_state), int(FarmTile.TileState.WATERED), "Tile water changes state")

	var planted := tile.plant_crop(wheat_crop)
	runner.assert_true(planted, "Can plant crop on watered tile")
	runner.assert_true(tile.has_crop(), "Tile has crop after planting")

	tile.advance_crop_growth()
	runner.assert_eq(tile.crop_growth_days, 1, "Crop growth advances")

	tile.clear_crop()
	runner.assert_true(not tile.has_crop(), "Clear crop removes crop")
