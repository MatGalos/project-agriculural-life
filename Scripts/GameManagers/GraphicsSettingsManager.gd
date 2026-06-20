extends Node

signal graphics_settings_changed
signal interface_scale_changed(scale_multiplier: float)

const CONFIG_PATH := "user://graphics.cfg"

const INTERFACE_SCALE_SMALL := "small"
const INTERFACE_SCALE_MEDIUM := "medium"
const INTERFACE_SCALE_BIG := "big"

const INTERFACE_SCALE_MULTIPLIERS := {
	INTERFACE_SCALE_SMALL: 0.85,
	INTERFACE_SCALE_MEDIUM: 1.0,
	INTERFACE_SCALE_BIG: 1.2
}

var resolution: Vector2i = Vector2i(1920, 1080)
var interface_scale: String = INTERFACE_SCALE_MEDIUM
var fullscreen: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_settings()


func set_resolution(new_resolution: Vector2i) -> void:
	if new_resolution.x <= 0 or new_resolution.y <= 0:
		return

	resolution = new_resolution
	save_settings()
	apply_settings()


func set_interface_scale(new_interface_scale: String) -> void:
	if not INTERFACE_SCALE_MULTIPLIERS.has(new_interface_scale):
		return

	interface_scale = new_interface_scale
	save_settings()
	apply_settings()


func set_fullscreen(is_fullscreen: bool) -> void:
	fullscreen = is_fullscreen
	save_settings()
	apply_settings()


func get_interface_scale_multiplier() -> float:
	return float(INTERFACE_SCALE_MULTIPLIERS.get(interface_scale, 1.0))


func apply_settings() -> void:
	var root_window: Window = get_tree().root

	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
		_center_window(resolution)

	root_window.content_scale_factor = get_interface_scale_multiplier()
	interface_scale_changed.emit(get_interface_scale_multiplier())
	graphics_settings_changed.emit()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "resolution_width", resolution.x)
	config.set_value("graphics", "resolution_height", resolution.y)
	config.set_value("graphics", "interface_scale", interface_scale)
	config.set_value("graphics", "fullscreen", fullscreen)
	config.save(CONFIG_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)

	if error != OK:
		return

	var width: int = int(config.get_value("graphics", "resolution_width", resolution.x))
	var height: int = int(config.get_value("graphics", "resolution_height", resolution.y))
	var loaded_scale: String = String(config.get_value("graphics", "interface_scale", interface_scale))

	resolution = Vector2i(width, height)

	if INTERFACE_SCALE_MULTIPLIERS.has(loaded_scale):
		interface_scale = loaded_scale

	fullscreen = bool(config.get_value("graphics", "fullscreen", fullscreen))


func _center_window(window_size: Vector2i) -> void:
	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen_position: Vector2i = DisplayServer.screen_get_position(screen_index)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)
	var centered_position := Vector2i(
		screen_position.x + ((screen_size.x - window_size.x) / 2),
		screen_position.y + ((screen_size.y - window_size.y) / 2)
	)

	DisplayServer.window_set_position(centered_position)
