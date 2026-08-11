class_name MainMenu

extends Control

@export var versionLabel: Label
@export var startButton: Button
@export var loadButton: Button
@export var optionsButton: Button
@export var howToPlayButton: Button
@export var creditsButton: Button
@export var exitButton: Button

@onready var background: ColorRect = $ColorRect


func _ready() -> void:
	add_to_group("main_menu")
	var version = ProjectSettings.get_setting("application/config/version")
	versionLabel.text = "Version " + str(version)
	startButton.button_down.connect(onStartButtonPressed)
	loadButton.button_down.connect(onLoadButtonPressed)
	optionsButton.button_down.connect(onOptionsButtonPressed)
	howToPlayButton.button_down.connect(onHowToPlayButtonPressed)
	creditsButton.button_down.connect(onCreditsButtonPressed)
	exitButton.button_down.connect(onExitButtonPressed)
	visible = true


func onStartButtonPressed() -> void:
	UISoundManager.play_ui_click()
	gamemanager.openNewGamePanel()


func onLoadButtonPressed() -> void:
	UISoundManager.play_ui_click()
	gamemanager.openLoadGamePanel(gamemanager.menuContext.Main_Menu)


func onOptionsButtonPressed() -> void:
	UISoundManager.play_ui_click()
	gamemanager.openOptions(gamemanager.menuContext.Main_Menu)


func onHowToPlayButtonPressed() -> void:
	UISoundManager.play_ui_click()
	gamemanager.openHowToPlay(gamemanager.menuContext.Main_Menu)


func onCreditsButtonPressed() -> void:
	UISoundManager.play_ui_click()
	gamemanager.openCredits()


func onExitButtonPressed() -> void:
	UISoundManager.play_ui_click()
	get_tree().quit()


func onOptionsClosed() -> void:
	show()
