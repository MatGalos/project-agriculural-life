@tool
extends Node3D

@export var tile_scene: PackedScene

@export var width: int = 10
@export var height: int = 10

@export var tile_spacing: float = 1.0

@export var grid_prefix: String = "small"

@export var regenerate := false:
	set(value):
		regenerate = false
		generate_grid()

func generate_grid() -> void:
	if tile_scene == null:
		print("FarmGridGenerator: missing tile_scene")
		return

	for child in get_children():
		child.free()

	var edited_root := get_tree().edited_scene_root

	for z in range(height):
		for x in range(width):
			var tile := tile_scene.instantiate() as FarmTile

			if tile == null:
				print("FarmGridGenerator: tile_scene root is not FarmTile")
				continue

			add_child(tile)
			tile.owner = edited_root

			tile.position = Vector3(
				x * tile_spacing,
				0.0,
				z * tile_spacing
			)

			tile.name = "Tile_%d_%d" % [x, z]
			tile.tile_id = "%s_%d_%d" % [grid_prefix, x, z]
