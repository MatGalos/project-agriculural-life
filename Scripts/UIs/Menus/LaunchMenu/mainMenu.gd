class_name MainMenu

extends Control

@export var versionLabel: Label
@export var startButton: Button
@export var loadButton: Button
@export var optionsButton: Button
@export var creditsButton: Button
@export var exitButton: Button

@onready var newGameScene: PackedScene = preload("res://Scenes/Game/mainScene.tscn") as PackedScene
@onready var background: ColorRect = $ColorRect


func _ready() -> void:
	var version = ProjectSettings.get_setting("application/config/version")
	versionLabel.text = "version " + str(version)
	startButton.button_down.connect(onStartButtonPressed)
	loadButton.button_down.connect(onLoadButtonPressed)
	optionsButton.button_down.connect(onOptionsButtonPressed)
	creditsButton.button_down.connect(onCreditsButtonPressed)
	exitButton.button_down.connect(onExitButtonPressed)
	visible = true


func onStartButtonPressed() -> void:
	gamemanager.startGame()
	get_tree().change_scene_to_packed.call_deferred(newGameScene)


func onLoadButtonPressed() -> void:
	# Save loading is not implemented yet.
	pass


func onOptionsButtonPressed() -> void:
	gamemanager.openOptions(gamemanager.menuContext.Main_Menu)


func onCreditsButtonPressed() -> void:
	# Credits screen is not implemented yet.
	pass


func onExitButtonPressed() -> void:
	get_tree().quit()


func onOptionsClosed() -> void:
	show()
