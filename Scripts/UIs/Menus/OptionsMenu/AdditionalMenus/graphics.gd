extends Control

const RESOLUTION_OPTIONS: Array[Dictionary] = [
	{"label": "480p - 854 x 480 (16:9)", "size": Vector2i(854, 480)},
	{"label": "720p - 1280 x 720 (16:9)", "size": Vector2i(1280, 720)},
	{"label": "1080p - 1920 x 1080 (16:9)", "size": Vector2i(1920, 1080)},
	{"label": "1440p - 2560 x 1440 (16:9)", "size": Vector2i(2560, 1440)},
	{"label": "4K / 2160p - 3840 x 2160 (16:9)", "size": Vector2i(3840, 2160)},
	{"label": "1024 x 768 (4:3)", "size": Vector2i(1024, 768)},
	{"label": "1280 x 960 (4:3)", "size": Vector2i(1280, 960)},
	{"label": "1440 x 900 (16:10)", "size": Vector2i(1440, 900)},
	{"label": "1680 x 1050 (16:10)", "size": Vector2i(1680, 1050)},
	{"label": "MacBook Air - 2560 x 1664", "size": Vector2i(2560, 1664)},
	{"label": "MacBook Pro 14 - 3024 x 1964", "size": Vector2i(3024, 1964)},
	{"label": "MacBook Pro 16 - 3456 x 2234", "size": Vector2i(3456, 2234)},
	{"label": "Ultrawide - 2560 x 1080 (21:9)", "size": Vector2i(2560, 1080)},
	{"label": "Ultrawide - 3440 x 1440 (21:9)", "size": Vector2i(3440, 1440)}
]

const INTERFACE_SCALE_OPTIONS: Array[Dictionary] = [
	{"label": "Small", "value": "small"},
	{"label": "Medium", "value": "medium"},
	{"label": "Big", "value": "big"}
]

@onready var resolution_option: OptionButton = $MarginContainer/VBoxContainer/ResolutionSection/ResolutionOption
@onready var interface_scale_option: OptionButton = $MarginContainer/VBoxContainer/InterfaceScaleSection/InterfaceScaleOption
@onready var fullscreen_check: CheckButton = $MarginContainer/VBoxContainer/FullscreenSection/FullscreenCheck

var _is_loading_values: bool = false


func _ready() -> void:
	_build_resolution_options()
	_build_interface_scale_options()
	_load_values_from_settings()

	resolution_option.item_selected.connect(_on_resolution_selected)
	interface_scale_option.item_selected.connect(_on_interface_scale_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func _build_resolution_options() -> void:
	resolution_option.clear()

	for i in range(RESOLUTION_OPTIONS.size()):
		var option: Dictionary = RESOLUTION_OPTIONS[i]
		resolution_option.add_item(String(option["label"]), i)
		resolution_option.set_item_metadata(i, option["size"])


func _build_interface_scale_options() -> void:
	interface_scale_option.clear()

	for i in range(INTERFACE_SCALE_OPTIONS.size()):
		var option: Dictionary = INTERFACE_SCALE_OPTIONS[i]
		interface_scale_option.add_item(String(option["label"]), i)
		interface_scale_option.set_item_metadata(i, option["value"])


func _load_values_from_settings() -> void:
	_is_loading_values = true
	resolution_option.select(_find_resolution_index(GraphicsSettingsManager.resolution))
	interface_scale_option.select(_find_interface_scale_index(GraphicsSettingsManager.interface_scale))
	fullscreen_check.button_pressed = GraphicsSettingsManager.fullscreen
	_update_fullscreen_text(GraphicsSettingsManager.fullscreen)
	_is_loading_values = false


func _find_resolution_index(target_resolution: Vector2i) -> int:
	for i in range(RESOLUTION_OPTIONS.size()):
		var option: Dictionary = RESOLUTION_OPTIONS[i]

		if option["size"] == target_resolution:
			return i

	return 2


func _find_interface_scale_index(target_interface_scale: String) -> int:
	for i in range(INTERFACE_SCALE_OPTIONS.size()):
		var option: Dictionary = INTERFACE_SCALE_OPTIONS[i]

		if String(option["value"]) == target_interface_scale:
			return i

	return 1


func _on_resolution_selected(index: int) -> void:
	if _is_loading_values:
		return

	var selected_resolution: Vector2i = resolution_option.get_item_metadata(index)
	GraphicsSettingsManager.set_resolution(selected_resolution)


func _on_interface_scale_selected(index: int) -> void:
	if _is_loading_values:
		return

	var selected_interface_scale: String = String(interface_scale_option.get_item_metadata(index))
	GraphicsSettingsManager.set_interface_scale(selected_interface_scale)


func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	_update_fullscreen_text(is_fullscreen)

	if _is_loading_values:
		return

	GraphicsSettingsManager.set_fullscreen(is_fullscreen)


func _update_fullscreen_text(is_fullscreen: bool) -> void:
	fullscreen_check.text = "Enabled" if is_fullscreen else "Disabled"
