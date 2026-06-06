@tool
extends Node3D
class_name FarmTile

enum TileState {
	GRASS,
	PLOWED,
	WATERED
}

@export var crop_root: Node3D
@export var current_state: TileState = TileState.GRASS:
	set(value):
		_current_state = value
		call_deferred("update_visuals")
	get:
		return _current_state
@export var grass_model: Node3D:
	set(value):
		_grass_model = value
		call_deferred("update_visuals")
	get:
		return _grass_model
@export var plowed_model: Node3D:
	set(value):
		_plowed_model = value
		call_deferred("update_visuals")
	get:
		return _plowed_model
@export var watered_model: Node3D:
	set(value):
		_watered_model = value
		call_deferred("update_visuals")
	get:
		return _watered_model
@export var tile_id: String = ""

var crop_data: CropData = null
var crop_growth_days: int = 0
var crop_instance: Node3D = null

var _current_state: TileState = TileState.GRASS
var _grass_model: Node3D = null
var _plowed_model: Node3D = null
var _watered_model: Node3D = null


func _ready() -> void:
	call_deferred("update_visuals")

	if not Engine.is_editor_hint():
		CropGrowthManager.register_tile(self)


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		CropGrowthManager.unregister_tile(self)


func set_state(new_state: TileState) -> void:
	current_state = new_state
	update_visuals()


func update_visuals() -> void:
	if _grass_model:
		_grass_model.visible = _current_state == TileState.GRASS

	if _plowed_model:
		_plowed_model.visible = _current_state == TileState.PLOWED

	if _watered_model:
		_watered_model.visible = _current_state == TileState.WATERED


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


func has_crop() -> bool:
	return crop_data != null


func can_plant() -> bool:
	return _current_state == TileState.WATERED and not has_crop()


func plant_crop(new_crop_data: CropData) -> bool:
	if new_crop_data == null or not can_plant():
		return false

	crop_data = new_crop_data
	crop_growth_days = 0
	_spawn_crop_visual(crop_data.seeded_scene)

	return true


func process_new_day() -> void:
	if has_crop() and _current_state == TileState.WATERED:
		advance_crop_growth()

	if _current_state == TileState.WATERED:
		set_state(TileState.PLOWED)


func advance_crop_growth() -> void:
	if crop_data == null:
		return

	crop_growth_days += 1
	update_crop_visual()


func update_crop_visual() -> void:
	if crop_data == null:
		return

	if crop_growth_days >= crop_data.days_to_ready:
		_spawn_crop_visual(crop_data.ready_scene)
	elif crop_growth_days >= crop_data.days_to_stage_3:
		_spawn_crop_visual(crop_data.stage_3_scene)
	elif crop_growth_days >= crop_data.days_to_stage_2:
		_spawn_crop_visual(crop_data.stage_2_scene)
	elif crop_growth_days >= crop_data.days_to_stage_1:
		_spawn_crop_visual(crop_data.stage_1_scene)
	else:
		_spawn_crop_visual(crop_data.seeded_scene)


func is_crop_ready() -> bool:
	if crop_data == null:
		return false

	return crop_growth_days >= crop_data.days_to_ready


func get_crop_display_name() -> String:
	if crop_data == null:
		return ""

	return crop_data.display_name


func harvest_crop() -> ItemData:
	if crop_data == null or not is_crop_ready():
		return null

	var harvest_item: ItemData = crop_data.harvest_item
	_clear_crop()
	set_state(TileState.PLOWED)

	return harvest_item


func _spawn_crop_visual(scene: PackedScene) -> void:
	_clear_crop_visual()

	if scene == null:
		return

	var parent_node: Node3D = crop_root if crop_root != null else self
	crop_instance = scene.instantiate() as Node3D

	if crop_instance == null:
		return

	parent_node.add_child(crop_instance)
	crop_instance.position = Vector3.ZERO


func _clear_crop() -> void:
	_clear_crop_visual()
	crop_data = null
	crop_growth_days = 0


func _clear_crop_visual() -> void:
	if crop_instance == null:
		return

	crop_instance.queue_free()
	crop_instance = null
