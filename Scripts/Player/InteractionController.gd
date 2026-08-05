extends Node

@onready var raycast: RayCast3D = $"../CameraPivot/Camera3D/InteractionRayCast"
@onready var prompt_label: Label = get_tree().get_first_node_in_group("interaction_prompt") as Label
@onready var crosshair_label: Label = get_tree().get_first_node_in_group("crosshair") as Label

var current_interactable: Interactable = null
var current_tool_prompt := ""
var current_can_show_gameplay_prompt := true

var normal_crosshair_color := Color.WHITE
var interact_crosshair_color := Color.YELLOW


func _ready() -> void:
	raycast.enabled = true

	var player_body: CollisionObject3D = get_parent() as CollisionObject3D

	if player_body:
		raycast.add_exception(player_body)


func _process(_delta: float) -> void:
	_ensure_ui_nodes()

	var tool_prompt := _get_looked_at_tool_prompt()
	var interactable: Interactable = null
	var can_show_gameplay_prompt := _can_show_gameplay_prompt()

	if tool_prompt == "":
		interactable = _get_looked_at_interactable()

	if (
		interactable == current_interactable
		and tool_prompt == current_tool_prompt
		and can_show_gameplay_prompt == current_can_show_gameplay_prompt
	):
		return

	current_interactable = interactable
	current_tool_prompt = tool_prompt
	current_can_show_gameplay_prompt = can_show_gameplay_prompt

	_update_prompt_label()
	_update_crosshair_color()


func _input(_event: InputEvent) -> void:
	if _is_storage_open() and InputManager.is_interact_pressed():
		var player_hud := get_tree().get_first_node_in_group("player_hud") as PlayerHUD

		if player_hud:
			player_hud.close_storage()
			get_viewport().set_input_as_handled()
		return

	if _is_any_game_menu_open():
		return

	if current_tool_prompt != "":
		return

	if not current_interactable:
		return

	if InputManager.is_interact_pressed():
		current_interactable.interact()


func _get_looked_at_tool_prompt() -> String:
	if not raycast.is_colliding():
		return ""

	var collider: Object = raycast.get_collider()

	if collider == null:
		return ""

	return ToolManager.get_tool_prompt_for_target(collider as Node)


func _get_looked_at_interactable() -> Interactable:
	if not raycast.is_colliding():
		return null

	var collider: Object = raycast.get_collider()

	if collider is Interactable:
		return collider as Interactable

	if collider is Node:
		var current := collider as Node

		while current != null:
			if current is Interactable:
				return current as Interactable

			current = current.get_parent()

	return null


func _update_prompt_label() -> void:
	if not prompt_label:
		return

	var can_show_prompt := current_can_show_gameplay_prompt

	if current_tool_prompt != "":
		prompt_label.text = current_tool_prompt
		prompt_label.visible = can_show_prompt
		return

	if current_interactable:
		prompt_label.text = current_interactable.get_prompt_text()
		prompt_label.visible = can_show_prompt
	else:
		prompt_label.text = ""
		prompt_label.visible = false


func _update_crosshair_color() -> void:
	if not crosshair_label:
		return

	if current_can_show_gameplay_prompt and (current_tool_prompt != "" or current_interactable):
		crosshair_label.modulate = interact_crosshair_color
	else:
		crosshair_label.modulate = normal_crosshair_color


func _ensure_ui_nodes() -> void:
	if not prompt_label:
		prompt_label = get_tree().get_first_node_in_group("interaction_prompt") as Label

	if not crosshair_label:
		crosshair_label = get_tree().get_first_node_in_group("crosshair") as Label


func _is_storage_open() -> bool:
	var player_hud := get_tree().get_first_node_in_group("player_hud") as PlayerHUD
	return player_hud != null and player_hud.is_storage_open()


func _is_any_game_menu_open() -> bool:
	var player_hud := get_tree().get_first_node_in_group("player_hud") as PlayerHUD
	return player_hud != null and player_hud.is_any_game_menu_open()


func _can_show_gameplay_prompt() -> bool:
	if gamemanager.isPaused:
		return false

	var player_hud := get_tree().get_first_node_in_group("player_hud") as PlayerHUD

	if player_hud == null:
		return true

	if player_hud.has_method("is_gameplay_hud_visible"):
		return player_hud.is_gameplay_hud_visible()

	return not player_hud.is_any_game_menu_open()
