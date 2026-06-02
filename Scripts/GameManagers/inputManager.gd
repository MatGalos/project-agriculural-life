extends Node

const CONFIG_PATH := "user://controls.cfg"

var actions := [
	"move_forward",
	"move_backward",
	"move_left",
	"move_right",
	"pauseMenu",
	"hotbar_slot_1",
	"hotbar_slot_2",
	"hotbar_slot_3",
	"hotbar_slot_4",
	"hotbar_slot_5",
	"interact",
	"sprint"
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
	InputMap.action_erase_events("hotbar_slot_1")
	InputMap.action_erase_events("hotbar_slot_2")
	InputMap.action_erase_events("hotbar_slot_3")
	InputMap.action_erase_events("hotbar_slot_4")
	InputMap.action_erase_events("hotbar_slot_5")
	InputMap.action_erase_events("interact")
	InputMap.action_erase_events("sprint")

	_add_key("move_forward", KEY_W)
	_add_key("move_backward", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("pauseMenu", KEY_ESCAPE)
	_add_key("hotbar_slot_1", KEY_1)
	_add_key("hotbar_slot_2", KEY_2)
	_add_key("hotbar_slot_3", KEY_3)
	_add_key("hotbar_slot_4", KEY_4)
	_add_key("hotbar_slot_5", KEY_5)
	_add_key("interact", KEY_E)
	_add_key("sprint", KEY_SHIFT)

	save_controls()

func get_pressed_hotbar_slot() -> int:
	if Input.is_action_just_pressed("hotbar_slot_1"):
		return 1
	if Input.is_action_just_pressed("hotbar_slot_2"):
		return 2
	if Input.is_action_just_pressed("hotbar_slot_3"):
		return 3
	if Input.is_action_just_pressed("hotbar_slot_4"):
		return 4
	if Input.is_action_just_pressed("hotbar_slot_5"):
		return 5

	return -1

func _add_key(action_name: String, keycode: Key):
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)

func is_interact_pressed() -> bool:
	return Input.is_action_just_pressed("interact")

func is_sprint_pressed() -> bool:
	return Input.is_action_pressed("sprint")
