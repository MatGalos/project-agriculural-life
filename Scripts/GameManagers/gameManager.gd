class_name GameManager

extends Node

@onready var globalUIScene: PackedScene = preload("res://Scenes/UIs/global_ui.tscn")
var pauseMenu
var optionsMenu
var mainMenu

var globalUIInstance
var isPaused: bool = false
var isInGame: bool = false 

enum menuContext {
	Main_Menu,
	Pause_Menu
}

var optionsContext: int = 0

signal pauseChanged(paused: bool)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	
	globalUIInstance = globalUIScene.instantiate()
	get_tree().root.add_child.call_deferred(globalUIInstance)
	await get_tree().process_frame
	
	pauseMenu = globalUIInstance.get_node("PauseMenu")
	optionsMenu = globalUIInstance.get_node("OptionsMenu")
	mainMenu = globalUIInstance.get_node("MainMenu")
	mainMenu.visible = true
	pauseMenu.visible = false
	optionsMenu.visible = false

# function to toggle pause
func togglePause():
	setPaused(!isPaused)

# function to set the pause for the game.
func setPaused(value: bool) -> void:
	if isPaused == value:
		return
	
	isPaused = value
	get_tree().paused = isPaused
	
	pauseChanged.emit(isPaused)

func _input(event):
	if not isInGame:
		return
	
	if event.is_action_pressed("pauseMenu"):
		togglePause()

func startGame():
	isInGame = true
	mainMenu.visible = false

func returnToMenu():
	isInGame = false
	mainMenu.visible = true
	pauseMenu.visible = false
	optionsMenu.visible = false

func openOptions(from_context):
	optionsContext = from_context
	pauseMenu.visible = false
	mainMenu.visible = false
	optionsMenu.setContext(from_context)
	optionsMenu.visible = true


func showGlobalUI():
	if not globalUIInstance:
		return
	if globalUIInstance:
		globalUIInstance.visible = true
	if mainMenu:
		mainMenu.visible = true
	if pauseMenu:
		pauseMenu.visible = false
	if optionsMenu:
		optionsMenu.visible = false
	isPaused = false
	get_tree().paused = false
