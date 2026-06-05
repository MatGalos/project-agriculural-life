extends Node

var farm_tiles: Array[FarmTile] = []


func _ready() -> void:
	if not TimeManager.day_changed.is_connected(_on_day_changed):
		TimeManager.day_changed.connect(_on_day_changed)


func register_tile(tile: FarmTile) -> void:
	if tile == null or farm_tiles.has(tile):
		return

	farm_tiles.append(tile)


func unregister_tile(tile: FarmTile) -> void:
	farm_tiles.erase(tile)


func _on_day_changed() -> void:
	for tile: FarmTile in farm_tiles:
		if tile != null and tile.has_crop():
			tile.process_new_day()
