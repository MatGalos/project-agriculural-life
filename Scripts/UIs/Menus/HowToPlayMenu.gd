class_name HowToPlayMenu

extends Control

signal closed

const HOW_TO_PLAY_PATH := "res://HOW_TO_PLAY.md"
const VIEWPORT_SAFE_MARGIN := Vector2(48.0, 48.0)
const MIN_RESPONSIVE_SCALE := 0.55
const DEFAULT_HOW_TO_PLAY_TEXT := """1. Goal
Grow crops, store harvested products, sell them at the right time, and use the market information to make better decisions.

2. Basic Loop
- Buy seeds in the Shop app.
- Till soil on the farm field.
- Plant seeds on tilled tiles.
- Water crops every day.
- Wait for crops to grow.
- Harvest mature crops.
- Store products in the silo.
- Sell products when market prices are favorable.

3. Controls
- Move: WASD
- Sprint: Shift
- Interact: E
- Use selected tool/item: Left Mouse Button
- Open/close FarmPhone: Q
- Pause: Esc

4. Tools
- Hoe: till soil.
- Watering Can: water planted crops.
- Seeds: plant crops on tilled soil.
- Harvest: collect mature crops.

5. Silo and Storage
Harvested crops can be moved to the silo/storage.
Use the silo to store products before selling them.

6. Selling
Open the selling/storage interface to choose products and quantities.
Selling products gives money and can influence the simulated market.

7. Market
Market prices change over time.
Use the Market app to check current prices, trends, and history.
Selling large amounts may affect supply and future prices.

8. News and Events
News can inform the player about market events, demand changes, oversupply, seasonal effects, and other economic changes.

9. Weather
Weather changes daily.
Rain can water crops.
Storms and other conditions may affect the farm/economy depending on implemented systems.
Use the Weather app to check the forecast.

10. Saving and Loading
Use save/load slots to continue your game later.
Audio and options settings are saved separately from gameplay saves."""

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

	var help_text := DEFAULT_HOW_TO_PLAY_TEXT
	var file := FileAccess.open(HOW_TO_PLAY_PATH, FileAccess.READ)

	if file != null:
		help_text = file.get_as_text()
		file.close()

	text_label.text = _normalize_help_text(help_text)


func _normalize_help_text(help_text: String) -> String:
	help_text = help_text.replace("\r\n", "\n")

	if help_text.begins_with("How to Play\n\n"):
		help_text = help_text.trim_prefix("How to Play\n\n")

	return help_text.strip_edges()


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
