class_name GameManager

extends Node

@onready var globalUIScene: PackedScene = preload("res://Scenes/UIs/global_ui.tscn")
var pauseMenu: PauseMenu
var optionsMenu: OptionsMenu
var mainMenu: MainMenu

var globalUIInstance: CanvasLayer
var isPaused: bool = false
var isInGame: bool = false 

enum menuContext {
	Main_Menu,
	Pause_Menu
}

var optionsContext: int = 0

signal pauseChanged(paused: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	
	globalUIInstance = globalUIScene.instantiate() as CanvasLayer
	get_tree().root.add_child.call_deferred(globalUIInstance)
	await get_tree().process_frame
	
	pauseMenu = globalUIInstance.get_node("PauseMenu") as PauseMenu
	optionsMenu = globalUIInstance.get_node("OptionsMenu") as OptionsMenu
	mainMenu = globalUIInstance.get_node("MainMenu") as MainMenu
	mainMenu.visible = true
	pauseMenu.setMenuVisible(false)
	optionsMenu.visible = false
	_updateMouseMode()

# function to toggle pause
func togglePause() -> void:
	setPaused(!isPaused)

# function to set the pause for the game.
func setPaused(value: bool) -> void:
	if isPaused == value:
		return
	
	isPaused = value
	get_tree().paused = isPaused
	_updateMouseMode()
	
	pauseChanged.emit(isPaused)

func _input(event: InputEvent) -> void:
	if not isInGame:
		return
	
	if event.is_action_pressed("pauseMenu"):
		var player_hud: PlayerHUD = get_tree().get_first_node_in_group("player_hud") as PlayerHUD

		if player_hud and player_hud.is_inventory_open():
			player_hud.close_inventory()
			get_viewport().set_input_as_handled()
			return

		togglePause()

func startGame() -> void:
	isInGame = true
	mainMenu.visible = false
	_updateMouseMode()

func returnToMenu() -> void:
	isInGame = false
	mainMenu.visible = true
	pauseMenu.setMenuVisible(false)
	optionsMenu.visible = false
	_updateMouseMode()

func openOptions(from_context: int) -> void:
	optionsContext = from_context
	if from_context == menuContext.Pause_Menu:
		pauseMenu.showBlurOnly()
	else:
		pauseMenu.setMenuVisible(false)
	mainMenu.visible = false
	optionsMenu.setContext(from_context)
	optionsMenu.visible = true
	_updateMouseMode()


func showGlobalUI() -> void:
	if not globalUIInstance:
		return
	if globalUIInstance:
		globalUIInstance.visible = true
	if mainMenu:
		mainMenu.visible = true
	if pauseMenu:
		pauseMenu.setMenuVisible(false)
	if optionsMenu:
		optionsMenu.visible = false
	isPaused = false
	get_tree().paused = false
	_updateMouseMode()

func _updateMouseMode() -> void:
	if isInGame and not isPaused and not optionsMenu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
