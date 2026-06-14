extends Control
class_name NewGamePanel

@onready var slot_1_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Slot1Button
@onready var slot_2_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Slot2Button
@onready var slot_3_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Slot3Button
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

@onready var main_game_scene: PackedScene = preload("res://Scenes/Game/mainScene.tscn") as PackedScene


func _ready() -> void:
	slot_1_button.pressed.connect(func(): _start_slot(1))
	slot_2_button.pressed.connect(func(): _start_slot(2))
	slot_3_button.pressed.connect(func(): _start_slot(3))
	back_button.pressed.connect(_on_back_pressed)


func _start_slot(slot: int) -> void:
	SaveManager.start_new_game(slot)
	gamemanager.startGame()
	get_tree().change_scene_to_packed(main_game_scene)


func _on_back_pressed() -> void:
	gamemanager.showMainMenu()
