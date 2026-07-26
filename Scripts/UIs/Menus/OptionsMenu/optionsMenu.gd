class_name OptionsMenu

extends Control

signal closed

@onready var background: ColorRect = $background
@onready var main_panel: Control = $Panel/MainOptions
@onready var sound_panel: Control = $Panel/SoundOptions
@onready var controls_panel: Control = $Panel/ControlsOptions
@onready var graphics_panel: Control = $Panel/GraphicsOptions
@onready var feedback_panel: Control = $Panel/FeedbackOptions

@onready var sound_button: Button = $Panel/MainOptions/WoodenBoard/MenuMargin/MenuContent/MenuButtons/SoundButton
@onready var controls_button: Button = $Panel/MainOptions/WoodenBoard/MenuMargin/MenuContent/MenuButtons/ControlsButton
@onready var graphics_button: Button = $Panel/MainOptions/WoodenBoard/MenuMargin/MenuContent/MenuButtons/GraphicsButton
@onready var feedback_button: Button = $Panel/MainOptions/WoodenBoard/MenuMargin/MenuContent/MenuButtons/FeedbackButton
@onready var back_button: Button = $Panel/MainOptions/WoodenBoard/MenuMargin/MenuContent/MenuButtons/BackButton

@onready var sound_back_button: Button = $Panel/SoundOptions/WoodenBoard/MenuMargin/MenuContent/BackToOptionsButton
@onready var controls_back_button: Button = $Panel/ControlsOptions/WoodenBoard/MenuMargin/MenuContent/BackToOptionsButton
@onready var graphics_back_button: Button = $Panel/GraphicsOptions/WoodenBoard/MenuMargin/MenuContent/BackToOptionsButton
@onready var feedback_back_button: Button = $Panel/FeedbackOptions/WoodenBoard/MenuMargin/MenuContent/BackToOptionsButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

	sound_button.button_down.connect(_show_sound_options)
	controls_button.button_down.connect(_show_controls_options)
	graphics_button.button_down.connect(_show_graphics_options)
	feedback_button.button_down.connect(_show_feedback_options)
	back_button.button_down.connect(close)

	sound_back_button.button_down.connect(_show_main_options)
	controls_back_button.button_down.connect(_show_main_options)
	graphics_back_button.button_down.connect(_show_main_options)
	feedback_back_button.button_down.connect(_show_main_options)

	_show_main_options()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("pauseMenu"):
		handle_back_action()
		get_viewport().set_input_as_handled()


func close() -> void:
	visible = false
	_show_main_options()
	closed.emit()

	match gamemanager.optionsContext:
		gamemanager.menuContext.Main_Menu:
			gamemanager.mainMenu.visible = true
		gamemanager.menuContext.Pause_Menu:
			gamemanager.pauseMenu.setMenuVisible(true)

	gamemanager._updateMouseMode()


func handle_back_action() -> void:
	if main_panel.visible:
		close()
	else:
		_show_main_options()


func setContext(context: int) -> void:
	_show_main_options()

	match context:
		gamemanager.menuContext.Main_Menu:
			background.color = Color(0.102, 0.337, 0.157, 1.0)
		gamemanager.menuContext.Pause_Menu:
			background.color = Color(0.0, 0.0, 0.0, 0.10)


func _show_main_options() -> void:
	_set_active_panel(main_panel)


func _show_sound_options() -> void:
	_set_active_panel(sound_panel)


func _show_controls_options() -> void:
	_set_active_panel(controls_panel)


func _show_graphics_options() -> void:
	_set_active_panel(graphics_panel)


func _show_feedback_options() -> void:
	_set_active_panel(feedback_panel)


func _set_active_panel(active_panel: Control) -> void:
	main_panel.visible = active_panel == main_panel
	sound_panel.visible = active_panel == sound_panel
	controls_panel.visible = active_panel == controls_panel
	graphics_panel.visible = active_panel == graphics_panel
	feedback_panel.visible = active_panel == feedback_panel
