class_name OptionsMenu

extends Control 

signal closed
@export var button: Button
@onready var background = $background  # ColorRect
# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.button_down.connect(close)

func close():
	visible = false
	var ui = gamemanager
	
	match ui.optionsContext:
		ui.menuContext.Main_Menu:
			ui.mainMenu.visible = true
		ui.menuContext.Pause_Menu:
			ui.pauseMenu.setMenuVisible(true)

func setContext(context):
	match context:
		0:
			background.color = Color(0.102, 0.337, 0.157)
		1:
			background.color = Color(0.0, 0.0, 0.0, 0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
