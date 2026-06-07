class_name GameManager

extends Node

signal pauseChanged(paused: bool)

@onready var globalUIScene: PackedScene = preload("res://Scenes/UIs/global_ui.tscn")

var pauseMenu: PauseMenu
var optionsMenu: OptionsMenu
var mainMenu: MainMenu
var globalUIInstance: CanvasLayer
var optionsContext: int = 0

var isPaused: bool = false
var is_paused: bool:
	get:
		return isPaused
	set(value):
		setPaused(value)

var isInGame: bool = false
var is_in_game: bool:
	get:
		return isInGame
	set(value):
		isInGame = value

enum menuContext {
	Main_Menu,
	Pause_Menu
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

	globalUIInstance = globalUIScene.instantiate() as CanvasLayer
	get_tree().root.add_child.call_deferred(globalUIInstance)
	await get_tree().process_frame

	pauseMenu = globalUIInstance.get_node_or_null("PauseMenu") as PauseMenu
	optionsMenu = globalUIInstance.get_node_or_null("OptionsMenu") as OptionsMenu
	mainMenu = globalUIInstance.get_node_or_null("MainMenu") as MainMenu

	if pauseMenu == null or optionsMenu == null or mainMenu == null:
		push_error("Global UI is missing one or more required menus.")
		return

	mainMenu.visible = true
	pauseMenu.setMenuVisible(false)
	optionsMenu.visible = false
	_updateMouseMode()


func _input(event: InputEvent) -> void:
	if not isInGame:
		return

	if event.is_action_pressed("pauseMenu"):
		_handle_pause_action()


func togglePause() -> void:
	setPaused(!isPaused)


func setPaused(value: bool) -> void:
	if isPaused == value:
		get_tree().paused = value
		_updateMouseMode()
		return

	isPaused = value
	get_tree().paused = isPaused
	_updateMouseMode()
	pauseChanged.emit(isPaused)


func startGame() -> void:
	isInGame = true
	setPaused(false)
	mainMenu.visible = false
	_updateMouseMode()


func returnToMenu() -> void:
	isInGame = false
	setPaused(false)
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

	globalUIInstance.visible = true

	if mainMenu:
		mainMenu.visible = true
	if pauseMenu:
		pauseMenu.setMenuVisible(false)
	if optionsMenu:
		optionsMenu.visible = false

	setPaused(false)
	_updateMouseMode()


func _handle_pause_action() -> void:
	if optionsMenu and optionsMenu.visible:
		get_viewport().set_input_as_handled()
		return

	var player_hud: PlayerHUD = get_tree().get_first_node_in_group("player_hud") as PlayerHUD

	if player_hud and player_hud.is_inventory_open():
		player_hud.close_inventory()
		get_viewport().set_input_as_handled()
		return

	if player_hud and player_hud.is_storage_open():
		player_hud.close_storage()
		get_viewport().set_input_as_handled()
		return

	if player_hud and player_hud.is_phone_open():
		player_hud.close_phone()
		get_viewport().set_input_as_handled()
		return

	togglePause()


func _updateMouseMode() -> void:
	var options_visible: bool = optionsMenu != null and optionsMenu.visible

	if isInGame and not isPaused and not options_visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
