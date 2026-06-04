extends Control

@export var control_bind_row_scene: PackedScene

@onready var controls_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ListMargin/ControlsList
@onready var reset_button: Button= $MarginContainer/VBoxContainer/ResetToDefault

var waiting_for_action := ""

var actions: Array[Dictionary] = [
	{"name": "move_forward", "display": "Move Forward"},
	{"name": "move_backward", "display": "Move Backward"},
	{"name": "move_left", "display": "Move Left"},
	{"name": "move_right", "display": "Move Right"},
	{"name": "interact", "display": "Interact"},
	{"name": "pauseMenu", "display": "Pause Menu"},
	{"name": "sprint", "display": "Sprint"},
	{"name": "hotbar_slot_1", "display": "Hotbar Slot 1"},
	{"name": "hotbar_slot_2", "display": "Hotbar Slot 2"},
	{"name": "hotbar_slot_3", "display": "Hotbar Slot 3"},
	{"name": "hotbar_slot_4", "display": "Hotbar Slot 4"},
	{"name": "hotbar_slot_5", "display": "Hotbar Slot 5"},
	{"name": "open_inventory", "display": "Open Inventory"},
	{"name": "open_phone", "display": "Open Phone"}
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

	if event is InputEventKey and event.pressed and not event.echo:
		InputManager.rebind_action(waiting_for_action, event)

		waiting_for_action = ""
		build_list()
		get_viewport().set_input_as_handled()

func _on_reset_button_pressed() -> void:
	InputManager.reset_to_defaults()
	build_list()
