extends Control

@export var control_bind_row_scene: PackedScene

@onready var controls_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ControlsList
@onready var reset_button: Button= $MarginContainer/VBoxContainer/ResetToDefault

var waiting_for_action := ""

var actions: Array[Dictionary] = [
	{"name": "move_forward", "display": "Move Forward"},
	{"name": "move_backward", "display": "Move Backward"},
	{"name": "move_left", "display": "Move Left"},
	{"name": "move_right", "display": "Move Right"},
	{"name": "pauseMenu", "display": "Pause Menu"}
]

func _ready() -> void:
	reset_button.pressed.connect(_on_reset_button_pressed)
	build_list()


func build_list() -> void:
	for child: Node in controls_list.get_children():
		child.queue_free()

	for action_data: Dictionary in actions:
		var row: ControlBindRow = control_bind_row_scene.instantiate() as ControlBindRow
		controls_list.add_child(row)

		row.setup(str(action_data["name"]), str(action_data["display"]))
		row.rebind_requested.connect(_on_rebind_requested)


func _on_rebind_requested(action_name: String) -> void:
	waiting_for_action = action_name


func _input(event: InputEvent) -> void:
	if waiting_for_action == "":
		return

	if event is InputEventKey and event.pressed:
		InputManager.rebind_action(waiting_for_action, event)

		waiting_for_action = ""
		build_list()
		get_viewport().set_input_as_handled()

func _on_reset_button_pressed():
	InputManager.reset_to_defaults()
	build_list()
