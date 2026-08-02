extends CharacterBody3D

@export var speed: float = 4.0
@export var sprint_speed: float = 6.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.003
@export var camera_distance: float = 4.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var player_hud: PlayerHUD = get_tree().get_first_node_in_group("player_hud") as PlayerHUD
@onready var interaction_raycast: RayCast3D = $CameraPivot/Camera3D/InteractionRayCast

var pitch: float = 0.0


func _ready() -> void:
	add_to_group("player")
	camera_pivot.position = Vector3(0, 1.4, 0)
	camera_pivot.rotation = Vector3.ZERO

	camera.position = Vector3(0, 0.5, camera_distance)
	camera.rotation = Vector3.ZERO
	camera.current = true
	interaction_raycast.collide_with_areas = true
	interaction_raycast.collide_with_bodies = true


func _input(event: InputEvent) -> void:
	if gamemanager.is_paused:
		return

	_ensure_player_hud()

	if InputManager.is_inventory_pressed() and player_hud:
		player_hud.toggle_inventory()
		return

	if InputManager.is_phone_pressed() and player_hud:
		player_hud.toggle_phone()
		return

	if _is_any_game_menu_open():
		return

	if InputManager.is_use_tool_pressed():
		_use_selected_tool()
		return
	
	if event.is_action_pressed("save_debug"):
		SaveManager.save_game()

	if event.is_action_pressed("load_debug"):
		SaveManager.load_game()
	
	if event.is_action_pressed("new_debug"):
		SaveManager.start_new_game(1)
		return

	if event is InputEventMouseMotion:
		_rotate_camera(event as InputEventMouseMotion)


func _physics_process(delta: float) -> void:
	_ensure_player_hud()

	if gamemanager.is_paused or _is_any_game_menu_open():
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	var input_dir: Vector2 = InputManager.get_move_vector()
	var forward: Vector3 = -camera_pivot.global_transform.basis.z
	var right: Vector3 = camera_pivot.global_transform.basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var direction: Vector3 = (right * input_dir.x - forward * input_dir.y).normalized()
	var current_speed: float = sprint_speed if InputManager.is_sprint_pressed() else speed
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()


func _rotate_camera(mouse_motion: InputEventMouseMotion) -> void:
	camera_pivot.rotate_y(-mouse_motion.relative.x * mouse_sensitivity)

	pitch -= mouse_motion.relative.y * mouse_sensitivity
	pitch = clamp(pitch, deg_to_rad(-75), deg_to_rad(35))
	camera_pivot.rotation.x = pitch


func _use_selected_tool() -> void:
	if HotbarManager.get_selected_item() == null:
		_show_hud_event_message("No tool selected.")
		return

	if not interaction_raycast.is_colliding():
		_show_hud_event_message("Nothing to interact with.")
		return

	var target := interaction_raycast.get_collider()
	if target is Node:
		ToolManager.use_active_tool(target as Node)
	else:
		_show_hud_event_message("Cannot use this here.")


func _is_inventory_open() -> bool:
	if not player_hud or not player_hud.has_method("is_inventory_open"):
		return false

	return player_hud.is_inventory_open()


func _is_phone_open() -> bool:
	if not player_hud or not player_hud.has_method("is_phone_open"):
		return false

	return player_hud.is_phone_open()


func _is_storage_open() -> bool:
	if not player_hud or not player_hud.has_method("is_storage_open"):
		return false

	return player_hud.is_storage_open()


func _is_any_game_menu_open() -> bool:
	if player_hud and player_hud.has_method("is_any_game_menu_open"):
		return player_hud.is_any_game_menu_open()

	return _is_inventory_open() or _is_phone_open() or _is_storage_open()


func _ensure_player_hud() -> void:
	if player_hud:
		return

	player_hud = get_tree().get_first_node_in_group("player_hud") as PlayerHUD


func _show_hud_event_message(message: String) -> void:
	_ensure_player_hud()

	if player_hud and player_hud.has_method("show_event_message"):
		player_hud.show_event_message(message)
