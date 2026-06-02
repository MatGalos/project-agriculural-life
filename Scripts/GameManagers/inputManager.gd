extends Node

const CONFIG_PATH := "user://controls.cfg"

var actions := [
	"move_forward",
	"move_backward",
	"move_left",
	"move_right",
	"pauseMenu"
]

func _ready():
	load_controls()


func get_move_vector() -> Vector2:
	return Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)


func rebind_action(action_name: String, event: InputEvent):
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	save_controls()


func save_controls():
	var config := ConfigFile.new()

	for action_name in actions:
		var events := InputMap.action_get_events(action_name)
		var serialized := []

		for event in events:
			if event is InputEventKey:
				serialized.append({
					"type": "key",
					"physical_keycode": event.physical_keycode
				})

		config.set_value("controls", action_name, serialized)

	config.save(CONFIG_PATH)


func load_controls():
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	if err != OK:
		return

	for action_name in actions:
		if not config.has_section_key("controls", action_name):
			continue

		InputMap.action_erase_events(action_name)

		var serialized: Array = config.get_value("controls", action_name, [])

		for data in serialized:
			if data.get("type", "") == "key":
				var event := InputEventKey.new()
				event.physical_keycode = data["physical_keycode"]
				InputMap.action_add_event(action_name, event)

func reset_to_defaults():
	InputMap.action_erase_events("move_forward")
	InputMap.action_erase_events("move_backward")
	InputMap.action_erase_events("move_left")
	InputMap.action_erase_events("move_right")
	InputMap.action_erase_events("pauseMenu")

	_add_key("move_forward", KEY_W)
	_add_key("move_backward", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("pauseMenu", KEY_ESCAPE)

	save_controls()


func _add_key(action_name: String, keycode: Key):
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
