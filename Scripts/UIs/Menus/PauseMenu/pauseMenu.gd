class_name PauseMenu

extends Control

@export var continueButton: Button
@export var saveButton: Button
@export var loadButton: Button
@export var optionsButton: Button
@export var saveAndQuitToMenu: Button
@export var saveAndQuitToDesktop:Button
@export var blurBg: ColorRect

@onready var mainMenuScene = preload("res://Scenes/UIs/Menus/LaunchMenu/MainMenu.tscn") as PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	continueButton.button_down.connect(onContinueButtonPressed)
	saveButton.button_down.connect(onSaveGameButtonPressed)
	loadButton.button_down.connect(onLoadGameButtonPressed)
	optionsButton.button_down.connect(onOptionsButtonPressed)
	saveAndQuitToMenu.button_down.connect(onSaveAndQuitToMenuButtonPressed)
	saveAndQuitToDesktop.button_down.connect(onSaveAndQuitToDesktopButtonPressed)
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	blurBg.visible = false
	print("readu")
	
	gamemanager.pauseChanged.connect(onPauseButtonPressed)

func onPauseButtonPressed (paused: bool) -> void:
	visible = paused
	blurBg.visible = paused

# Function with behaviour for when continue button is pressed, it should resume
# the game
func onContinueButtonPressed () -> void:
	gamemanager.setPaused(false)

# Function with behaviour for when save button is pressed, it should redirect to
# save the game menu
func onSaveGameButtonPressed() -> void:
	pass

# Function with behaviour for when load button is pressed, it should redirect to
# load the game menu
func onLoadGameButtonPressed() -> void:
	pass

# Function with behaviour for when options button is pressed, it should redirect to
# options menu
func onOptionsButtonPressed() -> void:
	pass

# Function with behaviour for when save and quit to menu button is pressed, 
# it should save the game and redirect to main menu
func onSaveAndQuitToMenuButtonPressed() -> void:
	gamemanager.setPaused(false)
	get_tree().change_scene_to_packed(mainMenuScene)

# Function with behaviour for when load button is pressed, it should redirect to
# load the game menu
func onSaveAndQuitToDesktopButtonPressed() -> void:
	gamemanager.setPaused(false)
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
