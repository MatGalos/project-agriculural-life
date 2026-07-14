extends Control
class_name LoadGamePanel

@onready var slot_1_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Slot1Button
@onready var slot_2_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Slot2Button
@onready var slot_3_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Slot3Button
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BackButton
@onready var background: ColorRect = $Background

@onready var game_scene: PackedScene = preload("res://Scenes/Game/mainScene.tscn") as PackedScene


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	slot_1_button.process_mode = Node.PROCESS_MODE_ALWAYS
	slot_2_button.process_mode = Node.PROCESS_MODE_ALWAYS
	slot_3_button.process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.process_mode = Node.PROCESS_MODE_ALWAYS

	slot_1_button.pressed.connect(func(): _load_slot(1))
	slot_2_button.pressed.connect(func(): _load_slot(2))
	slot_3_button.pressed.connect(func(): _load_slot(3))
	back_button.pressed.connect(_on_back_pressed)


func open() -> void:
	visible = true
	_refresh_slots()


func close() -> void:
	visible = false


func refresh() -> void:
	_refresh_slots()


func setContext(context: int) -> void:
	match context:
		gamemanager.menuContext.Main_Menu:
			background.color = Color(0.102, 0.337, 0.157, 1.0)
		gamemanager.menuContext.Pause_Menu:
			background.color = Color(0.0, 0.0, 0.0, 0.0)


func _refresh_slots() -> void:
	_update_slot_button(slot_1_button, 1)
	_update_slot_button(slot_2_button, 2)
	_update_slot_button(slot_3_button, 3)


func _update_slot_button(button: Button, slot: int) -> void:
	var info := SaveManager.get_save_slot_info(slot)

	if not bool(info.get("exists", false)):
		button.text = "Slot %d\nEmpty Slot" % slot
		button.disabled = true
		return

	button.disabled = false
	button.text = "Slot %d\n%s\nMoney: %s" % [
		slot,
		UIFormatHelper.season_date(
			SaveManager.get_season_name_from_month(int(info["month"])),
			int(info["day"]),
			int(info["year"])
		),
		UIFormatHelper.money_int(int(info["money"]))
	]


func _load_slot(slot: int) -> void:
	SaveManager.set_current_save_slot(slot)
	gamemanager.startGame()
	get_tree().change_scene_to_packed.call_deferred(game_scene)
	_load_game_deferred.call_deferred()


func _on_back_pressed() -> void:
	gamemanager.closeLoadGamePanel()


func _load_game_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	SaveManager.load_game()
