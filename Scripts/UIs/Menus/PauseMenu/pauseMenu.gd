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
@onready var confirmation_overlay: Control = $ConfirmationOverlay
@onready var confirmation_message: Label = $ConfirmationOverlay/ConfirmCenter/WoodenBoard/MenuMargin/MenuContent/MessageLabel
@onready var confirm_button: Button = $ConfirmationOverlay/ConfirmCenter/WoodenBoard/MenuMargin/MenuContent/ButtonRow/ConfirmButton
@onready var cancel_button: Button = $ConfirmationOverlay/ConfirmCenter/WoodenBoard/MenuMargin/MenuContent/ButtonRow/CancelButton

enum ConfirmationAction {
	NONE,
	SAVE,
	SAVE_AND_QUIT_TO_MENU,
	SAVE_AND_QUIT_TO_DESKTOP
}

var _pending_confirmation_action: ConfirmationAction = ConfirmationAction.NONE


func _ready() -> void:
	continueButton.button_down.connect(onContinueButtonPressed)
	saveButton.button_down.connect(onSaveGameButtonPressed)
	loadButton.button_down.connect(onLoadGameButtonPressed)
	optionsButton.button_down.connect(onOptionsButtonPressed)
	saveAndQuitToMenu.button_down.connect(onSaveAndQuitToMenuButtonPressed)
	saveAndQuitToDesktop.button_down.connect(onSaveAndQuitToDesktopButtonPressed)
	confirm_button.button_down.connect(_on_confirmation_confirmed)
	cancel_button.button_down.connect(_hide_confirmation)
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	blurBg.visible = false
	panel.visible = false
	confirmation_overlay.visible = false
	gamemanager.pauseChanged.connect(onPauseButtonPressed)


func _input(event: InputEvent) -> void:
	if not visible or not confirmation_overlay.visible:
		return

	if event.is_action_pressed("pauseMenu"):
		_hide_confirmation()
		get_viewport().set_input_as_handled()


func onPauseButtonPressed(paused: bool) -> void:
	setMenuVisible(paused)


func setMenuVisible(is_visible: bool) -> void:
	visible = is_visible
	blurBg.visible = is_visible
	panel.visible = is_visible

	if not is_visible:
		_hide_confirmation()


func showBlurOnly() -> void:
	visible = true
	blurBg.visible = true
	panel.visible = false
	_hide_confirmation()


func onContinueButtonPressed() -> void:
	gamemanager.setPaused(false)


func onSaveGameButtonPressed() -> void:
	_show_confirmation(
		ConfirmationAction.SAVE,
		"Overwrite the current saved game?"
	)


func onLoadGameButtonPressed() -> void:
	gamemanager.openLoadGamePanel(gamemanager.menuContext.Pause_Menu)


func onOptionsButtonPressed() -> void:
	gamemanager.openOptions(gamemanager.menuContext.Pause_Menu)


func onSaveAndQuitToMenuButtonPressed() -> void:
	_show_confirmation(
		ConfirmationAction.SAVE_AND_QUIT_TO_MENU,
		"Save the game and quit to menu?"
	)


func onSaveAndQuitToDesktopButtonPressed() -> void:
	_show_confirmation(
		ConfirmationAction.SAVE_AND_QUIT_TO_DESKTOP,
		"Save the game and quit to desktop?"
	)


func onOptionsClosed() -> void:
	visible = true


func _show_confirmation(action: ConfirmationAction, message: String) -> void:
	_pending_confirmation_action = action
	confirmation_message.text = message

	match action:
		ConfirmationAction.SAVE:
			confirm_button.text = "Overwrite"
		ConfirmationAction.SAVE_AND_QUIT_TO_MENU:
			confirm_button.text = "Save and Quit"
		ConfirmationAction.SAVE_AND_QUIT_TO_DESKTOP:
			confirm_button.text = "Save and Quit"
		_:
			confirm_button.text = "Confirm"

	confirmation_overlay.visible = true
	confirmation_overlay.move_to_front()


func _hide_confirmation() -> void:
	_pending_confirmation_action = ConfirmationAction.NONE

	if confirmation_overlay != null:
		confirmation_overlay.visible = false


func _on_confirmation_confirmed() -> void:
	var action: ConfirmationAction = _pending_confirmation_action
	_hide_confirmation()

	match action:
		ConfirmationAction.SAVE:
			SaveManager.save_game()
		ConfirmationAction.SAVE_AND_QUIT_TO_MENU:
			SaveManager.save_game()
			gamemanager.setPaused(false)
			gamemanager.returnToMenu()
			get_tree().change_scene_to_packed(mainMenuScene)
		ConfirmationAction.SAVE_AND_QUIT_TO_DESKTOP:
			SaveManager.save_game()
			gamemanager.setPaused(false)
			get_tree().quit()
