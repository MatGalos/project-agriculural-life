class_name MainMenu

extends Control

@export var versionLabel: Label
@export var startButton: Button
@export var loadButton: Button
@export var optionsButton: Button
@export var creditsButton: Button
@export var exitButton: Button
 
@onready var newGameScene = preload("res://Scenes/Game/mainScene.tscn") as PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	var version = ProjectSettings.get_setting("application/config/version")
	versionLabel.text = "version " + str(version)
	startButton.button_down.connect(onStartButtonPressed)
	loadButton.button_down.connect(onLoadButtonPressed)
	optionsButton.button_down.connect(onOptionsButtonPressed)
	creditsButton.button_down.connect(onCreditsButtonPressed)
	exitButton.button_down.connect(onExitButtonPressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Function with behaviour for when start new game button is pressed, it should
# launch the new game
func onStartButtonPressed() -> void:
	get_tree().change_scene_to_packed(newGameScene)

# Function with behaviour for when load game button is pressed, it should
# direct to menu with load save selection
func onLoadButtonPressed() -> void:
	pass

# Function with behaviour for when options button is pressed, it should redirect
# to the options menu
func onOptionsButtonPressed() -> void:
	pass

# Function with behaviour for when credits button is pressed, it should redirect
# to the credits
func onCreditsButtonPressed() -> void:
	pass

# Function with behaviour for when exit button is pressed, it should close the game
# and exit to the desktop
func onExitButtonPressed() -> void:
	get_tree().quit()
