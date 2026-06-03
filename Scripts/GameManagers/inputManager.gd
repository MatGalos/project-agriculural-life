extends Node

const CONFIG_PATH := "user://controls.cfg"

var actions: Array[String] = [
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
	"sprint",
	"open_inventory",
	"open_phone"
]

func _ready() -> void:
	load_controls()


func get_move_vector() -> Vector2:
	return Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)


func rebind_action(action_name: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	save_controls()


func save_controls() -> void:
	var config: ConfigFile = ConfigFile.new()

	for action_name: String in actions:
		var events: Array[InputEvent] = InputMap.action_get_events(action_name)
		var serialized: Array[Dictionary] = []

		for event: InputEvent in events:
			if event is InputEventKey:
				serialized.append({
					"type": "key",
					"physical_keycode": (event as InputEventKey).physical_keycode
				})

		config.set_value("controls", action_name, serialized)

	config.save(CONFIG_PATH)


func load_controls() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(CONFIG_PATH)

	if err != OK:
		return

	for action_name: String in actions:
		if not config.has_section_key("controls", action_name):
			continue

		InputMap.action_erase_events(action_name)

		var serialized: Array = config.get_value("controls", action_name, []) as Array

		for data: Dictionary in serialized:
			if data.get("type", "") == "key":
				var event: InputEventKey = InputEventKey.new()
				event.physical_keycode = int(data["physical_keycode"])
				InputMap.action_add_event(action_name, event)

func reset_to_defaults() -> void:
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
	InputMap.action_erase_events("open_inventory")
	InputMap.action_erase_events("open_phone")

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
	_add_key("open_inventory", KEY_T)
	_add_key("open_phone", KEY_Q)

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

func _add_key(action_name: String, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)

func is_interact_pressed() -> bool:
	return Input.is_action_just_pressed("interact")

func is_sprint_pressed() -> bool:
	return Input.is_action_pressed("sprint")


func is_inventory_pressed() -> bool:
	return Input.is_action_just_pressed("open_inventory")

func is_phone_pressed() -> bool:
	return Input.is_action_just_pressed("open_phone")
