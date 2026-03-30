class_name GameManager

extends Node

@onready var globalUIScene = preload("res://Scenes/UIs/global_ui.tscn")

var globalUIInstance
var isPaused = false

signal pauseChanged(paused: bool)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	
	globalUIInstance = globalUIScene.instantiate()
	get_tree().root.add_child.call_deferred(globalUIInstance)

# function to toggle pause
func togglePause():
	setPaused(!isPaused)

# function to set the pause for the game.
func setPaused(value: bool):
	if isPaused == value:
		return
	
	isPaused = value
	get_tree().paused = isPaused
	
	pauseChanged.emit(isPaused)

func _input(event):
	if event.is_action_pressed("pauseMenu"):
		togglePause()
