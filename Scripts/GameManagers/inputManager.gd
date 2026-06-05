extends Node

const CONFIG_PATH := "user://controls.cfg"
const DEFAULT_KEY_BINDS := {
	"move_forward": KEY_W,
	"move_backward": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"pauseMenu": KEY_ESCAPE,
	"hotbar_slot_1": KEY_1,
	"hotbar_slot_2": KEY_2,
	"hotbar_slot_3": KEY_3,
	"hotbar_slot_4": KEY_4,
	"hotbar_slot_5": KEY_5,
	"interact": KEY_E,
	"sprint": KEY_SHIFT,
	"open_inventory": KEY_T,
	"open_phone": KEY_Q
}
const DEFAULT_MOUSE_BINDS := {
	"use_tool": MOUSE_BUTTON_LEFT
}

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
	"open_phone",
	"use_tool"
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
	if not actions.has(action_name):
		return

	_ensure_action_exists(action_name)
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	save_controls()


func save_controls() -> void:
	var config: ConfigFile = ConfigFile.new()

	for action_name: String in actions:
		_ensure_action_exists(action_name)
		config.set_value("controls", action_name, _serialize_events(InputMap.action_get_events(action_name)))

	config.save(CONFIG_PATH)


func load_controls() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(CONFIG_PATH)

	if err != OK:
		return

	for action_name: String in actions:
		if not config.has_section_key("controls", action_name):
			continue

		var serialized: Array = config.get_value("controls", action_name, []) as Array
		if serialized.is_empty():
			continue

		_ensure_action_exists(action_name)
		InputMap.action_erase_events(action_name)
		_load_serialized_events(action_name, serialized)


func reset_to_defaults() -> void:
	for action_name: String in actions:
		_ensure_action_exists(action_name)
		InputMap.action_erase_events(action_name)

	for action_name: String in DEFAULT_KEY_BINDS:
		_add_key(action_name, DEFAULT_KEY_BINDS[action_name])

	for action_name: String in DEFAULT_MOUSE_BINDS:
		_add_mouse_button(action_name, DEFAULT_MOUSE_BINDS[action_name])

	save_controls()


func get_pressed_hotbar_slot() -> int:
	for slot_index in range(1, 6):
		if Input.is_action_just_pressed("hotbar_slot_%d" % slot_index):
			return slot_index

	return -1


func is_interact_pressed() -> bool:
	return Input.is_action_just_pressed("interact")


func is_sprint_pressed() -> bool:
	return Input.is_action_pressed("sprint")


func is_inventory_pressed() -> bool:
	return Input.is_action_just_pressed("open_inventory")


func is_phone_pressed() -> bool:
	return Input.is_action_just_pressed("open_phone")


func is_use_tool_pressed() -> bool:
	return Input.is_action_just_pressed("use_tool")


func _serialize_events(events: Array[InputEvent]) -> Array[Dictionary]:
	var serialized: Array[Dictionary] = []

	for event: InputEvent in events:
		if event is InputEventKey:
			serialized.append({
				"type": "key",
				"physical_keycode": (event as InputEventKey).physical_keycode
			})
		elif event is InputEventMouseButton:
			serialized.append({
				"type": "mouse_button",
				"button_index": (event as InputEventMouseButton).button_index
			})

	return serialized


func _load_serialized_events(action_name: String, serialized: Array) -> void:
	for data: Dictionary in serialized:
		if data.get("type", "") == "key":
			_add_key(action_name, int(data["physical_keycode"]))
		elif data.get("type", "") == "mouse_button":
			_add_mouse_button(action_name, int(data["button_index"]))


func _add_key(action_name: String, keycode: Key) -> void:
	_ensure_action_exists(action_name)
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


func _add_mouse_button(action_name: String, button_index: MouseButton) -> void:
	_ensure_action_exists(action_name)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)


func _ensure_action_exists(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
