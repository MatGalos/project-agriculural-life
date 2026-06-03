extends Node

@onready var raycast: RayCast3D = $"../CameraPivot/Camera3D/InteractionRayCast"
@onready var prompt_label: Label = get_tree().get_first_node_in_group("interaction_prompt") as Label
@onready var crosshair_label: Label = get_tree().get_first_node_in_group("crosshair") as Label

var current_interactable: Interactable = null
var normal_crosshair_color := Color.WHITE
var interact_crosshair_color := Color.YELLOW

func _ready() -> void:
	raycast.enabled = true
	var player_body: CollisionObject3D = get_parent() as CollisionObject3D

	if player_body:
		raycast.add_exception(player_body)


func _process(_delta: float) -> void:
	var interactable: Interactable = _get_looked_at_interactable()

	if interactable == current_interactable:
		return

	current_interactable = interactable

	if current_interactable:
		print(current_interactable.get_display_name())

	_update_prompt_label()
	_update_crosshair_color()


func _input(_event: InputEvent) -> void:
	if not current_interactable:
		return

	if InputManager.is_interact_pressed():
		current_interactable.interact()


func _get_looked_at_interactable() -> Interactable:
	if not raycast.is_colliding():
		return null

	var collider: Object = raycast.get_collider()

	if collider is Interactable:
		return collider as Interactable

	return null


func _update_prompt_label() -> void:
	if not prompt_label:
		return

	if current_interactable:
		prompt_label.text = current_interactable.get_prompt_text()
		prompt_label.visible = true
	else:
		prompt_label.text = ""
		prompt_label.visible = false


func _update_crosshair_color() -> void:
	if not crosshair_label:
		return

	if current_interactable:
		crosshair_label.modulate = interact_crosshair_color
	else:
		crosshair_label.modulate = normal_crosshair_color
