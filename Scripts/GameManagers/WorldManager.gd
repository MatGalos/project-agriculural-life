extends Node
class_name WorldManager

@export var world_root: Node3D
@export var home_area: Node3D
@export var farm_root: Node3D
@export var farm_tiles_root: Node3D

var farm_tiles_by_id: Dictionary = {}


func _ready() -> void:
	register_farm_tiles()


func register_farm_tiles() -> void:
	farm_tiles_by_id.clear()

	if farm_tiles_root == null:
		print("WorldManager: farm_tiles_root is null")
		return

	for child in farm_tiles_root.get_children():
		if child is FarmTile:
			var tile := child as FarmTile

			if tile.tile_id == "":
				print("WorldManager: tile without id: ", tile.name)
				continue

			farm_tiles_by_id[tile.tile_id] = tile

	print("WorldManager: registered tiles: ", farm_tiles_by_id.size())


func get_tile_by_id(tile_id: String) -> FarmTile:
	return farm_tiles_by_id.get(tile_id, null)


func get_all_farm_tiles() -> Array:
	return farm_tiles_by_id.values()
