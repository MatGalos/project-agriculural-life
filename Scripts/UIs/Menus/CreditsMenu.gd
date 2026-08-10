class_name CreditsMenu

extends Control

signal closed

const VIEWPORT_SAFE_MARGIN := Vector2(48.0, 48.0)
const MIN_RESPONSIVE_SCALE := 0.55

const CREDITS_TEXT := """Project Agricultural Life
Created as part of a master's thesis prototype.

Engine
Godot Engine — MIT License

Fonts
Lato — SIL Open Font License 1.1
Super Chips by All Super Font — Freeware

Audio
UI, notification, gameplay and weather placeholder SFX were generated procedurally from scratch for this academic prototype.
No external audio samples were used.

Custom Assets
3D models, textures and icons were created by the project author.

See CREDITS.md for full details.
"""

@export var board: Control
@export var text_label: RichTextLabel
@export var back_button: Button

var _board_base_size := Vector2.ZERO


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

	if back_button != null:
		back_button.button_down.connect(close)

	if board != null:
		_board_base_size = board.custom_minimum_size

	get_viewport().size_changed.connect(_apply_responsive_layout)

	if not GraphicsSettingsManager.interface_scale_changed.is_connected(_on_interface_scale_changed):
		GraphicsSettingsManager.interface_scale_changed.connect(_on_interface_scale_changed)

	if text_label != null:
		text_label.text = CREDITS_TEXT

	_apply_responsive_layout()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("pauseMenu"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	UISoundManager.play_ui_click()
	visible = false
	closed.emit()
	gamemanager.mainMenu.visible = true
	gamemanager._updateMouseMode()


func _on_interface_scale_changed(_scale_multiplier: float) -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if board == null:
		return

	if _board_base_size == Vector2.ZERO:
		_board_base_size = board.custom_minimum_size

	var viewport_size := get_viewport().get_visible_rect().size
	var interface_scale := maxf(GraphicsSettingsManager.get_interface_scale_multiplier(), 0.1)
	var available_size := (viewport_size / interface_scale) - (VIEWPORT_SAFE_MARGIN * 2.0)
	var fit_scale := minf(available_size.x / _board_base_size.x, available_size.y / _board_base_size.y)
	fit_scale = clampf(fit_scale, MIN_RESPONSIVE_SCALE, 1.0)
	board.custom_minimum_size = _board_base_size * fit_scale
