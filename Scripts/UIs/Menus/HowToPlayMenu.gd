class_name HowToPlayMenu

extends Control

signal closed

const HOW_TO_PLAY_PATH := "res://HOW_TO_PLAY.md"
const VIEWPORT_SAFE_MARGIN := Vector2(48.0, 48.0)
const MIN_RESPONSIVE_SCALE := 0.55

@export var background: ColorRect
@export var board: Control
@export var text_label: RichTextLabel
@export var back_button: Button

var _board_base_size := Vector2.ZERO
var _context: int = 0


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

	_load_text()
	_apply_responsive_layout()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("pauseMenu"):
		close()
		get_viewport().set_input_as_handled()


func set_context(context: int) -> void:
	_context = context

	match context:
		gamemanager.menuContext.Main_Menu:
			if background != null:
				background.color = Color(0.102, 0.337, 0.157, 1.0)
		gamemanager.menuContext.Pause_Menu:
			if background != null:
				background.color = Color(0.0, 0.0, 0.0, 0.10)


func close() -> void:
	UISoundManager.play_ui_click()
	visible = false
	closed.emit()

	match _context:
		gamemanager.menuContext.Main_Menu:
			gamemanager.mainMenu.visible = true
		gamemanager.menuContext.Pause_Menu:
			gamemanager.pauseMenu.setMenuVisible(true)

	gamemanager._updateMouseMode()


func _load_text() -> void:
	if text_label == null:
		return

	var file := FileAccess.open(HOW_TO_PLAY_PATH, FileAccess.READ)

	if file == null:
		text_label.text = "How to Play\n\nHelp text is missing."
		return

	var help_text := file.get_as_text()
	file.close()

	if help_text.begins_with("How to Play\n\n"):
		help_text = help_text.trim_prefix("How to Play\n\n")

	text_label.text = help_text


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
