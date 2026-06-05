extends HBoxContainer
class_name ControlBindRow

signal rebind_requested(action_name: String)

@onready var action_label: Label = $ActionLabel
@onready var bind_button: Button = $BindButton

var action_name := ""

func setup(new_action_name: String, display_name: String) -> void:
	action_name = new_action_name
	action_label.text = display_name
	refresh()


func refresh() -> void:
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)

	if events.is_empty():
		bind_button.text = "Unassigned"
		return

	bind_button.text = events[0].as_text()


func _ready() -> void:
	bind_button.pressed.connect(_on_bind_button_pressed)


func _on_bind_button_pressed() -> void:
	bind_button.text = "Press input..."
	rebind_requested.emit(action_name)
