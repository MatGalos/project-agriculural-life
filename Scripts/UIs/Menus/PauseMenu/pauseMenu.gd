class_name PauseMenu

extends Control

@export var continueButton: Button
@export var saveButton: Button
@export var loadButton: Button
@export var optionsButton: Button
@export var saveAndQuitToMenu: Button
@export var saveAndQuitToDesktop: Button
@export var blurBg: ColorRect
@export var panel: Control

@onready var mainMenuScene: PackedScene = preload("res://Scenes/UIs/Menus/LaunchMenu/MainMenu.tscn") as PackedScene


func _ready() -> void:
	continueButton.button_down.connect(onContinueButtonPressed)
	saveButton.button_down.connect(onSaveGameButtonPressed)
	loadButton.button_down.connect(onLoadGameButtonPressed)
	optionsButton.button_down.connect(onOptionsButtonPressed)
	saveAndQuitToMenu.button_down.connect(onSaveAndQuitToMenuButtonPressed)
	saveAndQuitToDesktop.button_down.connect(onSaveAndQuitToDesktopButtonPressed)
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	blurBg.visible = false
	panel.visible = false
	gamemanager.pauseChanged.connect(onPauseButtonPressed)


func onPauseButtonPressed(paused: bool) -> void:
	setMenuVisible(paused)


func setMenuVisible(is_visible: bool) -> void:
	visible = is_visible
	blurBg.visible = is_visible
	panel.visible = is_visible


func showBlurOnly() -> void:
	visible = true
	blurBg.visible = true
	panel.visible = false


func onContinueButtonPressed() -> void:
	gamemanager.setPaused(false)


func onSaveGameButtonPressed() -> void:
	SaveManager.save_game()


func onLoadGameButtonPressed() -> void:
	gamemanager.openLoadGamePanel(gamemanager.menuContext.Pause_Menu)


func onOptionsButtonPressed() -> void:
	gamemanager.openOptions(gamemanager.menuContext.Pause_Menu)


func onSaveAndQuitToMenuButtonPressed() -> void:
	SaveManager.save_game()
	gamemanager.setPaused(false)
	gamemanager.returnToMenu()
	get_tree().change_scene_to_packed(mainMenuScene)


func onSaveAndQuitToDesktopButtonPressed() -> void:
	SaveManager.save_game()
	gamemanager.setPaused(false)
	get_tree().quit()


func onOptionsClosed() -> void:
	visible = true
