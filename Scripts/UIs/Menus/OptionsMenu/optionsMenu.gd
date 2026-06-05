class_name OptionsMenu

extends Control

signal closed

@export var button: Button
@onready var background: ColorRect = $background


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.button_down.connect(close)


func close() -> void:
	visible = false
	closed.emit()

	match gamemanager.optionsContext:
		gamemanager.menuContext.Main_Menu:
			gamemanager.mainMenu.visible = true
		gamemanager.menuContext.Pause_Menu:
			gamemanager.pauseMenu.setMenuVisible(true)

	gamemanager._updateMouseMode()


func setContext(context: int) -> void:
	match context:
		gamemanager.menuContext.Main_Menu:
			background.color = Color(0.102, 0.337, 0.157)
		gamemanager.menuContext.Pause_Menu:
			background.color = Color(0.0, 0.0, 0.0, 0.0)
