@tool
extends Node3D
class_name FarmTile

enum TileState {
	GRASS,
	PLOWED,
	WATERED
}

var _current_state: TileState = TileState.GRASS
var crop_data = null
var crop_instance = null

@export var current_state: TileState = TileState.GRASS:
	set(value):
		_current_state = value
		call_deferred("update_visuals")
	get:
		return _current_state

@export var grass_model: Node3D:
	set(value):
		grass_model = value
		call_deferred("update_visuals")

@export var plowed_model: Node3D:
	set(value):
		plowed_model = value
		call_deferred("update_visuals")

@export var watered_model: Node3D:
	set(value):
		watered_model = value
		call_deferred("update_visuals")


func _ready() -> void:
	call_deferred("update_visuals")


func set_state(new_state: TileState) -> void:
	current_state = new_state
	update_visuals()


func update_visuals() -> void:
	if grass_model:
		grass_model.visible = _current_state == TileState.GRASS

	if plowed_model:
		plowed_model.visible = _current_state == TileState.PLOWED

	if watered_model:
		watered_model.visible = _current_state == TileState.WATERED


func plow() -> void:
	if _current_state != TileState.GRASS:
		return

	set_state(TileState.PLOWED)


func water() -> void:
	if _current_state != TileState.PLOWED:
		return

	set_state(TileState.WATERED)


func reset_to_grass() -> void:
	set_state(TileState.GRASS)

func can_plant() -> bool:
	return true

func plant_crop() :
	return

func can_harvest() -> bool:
	return true

func harvest():
	return
