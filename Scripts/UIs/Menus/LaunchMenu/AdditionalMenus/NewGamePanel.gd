extends Control
class_name NewGamePanel

@onready var slot_1_button: Button = $MenuCenter/WoodenBoard/MenuMargin/MenuContent/SlotButtons/Slot1Button
@onready var slot_2_button: Button = $MenuCenter/WoodenBoard/MenuMargin/MenuContent/SlotButtons/Slot2Button
@onready var slot_3_button: Button = $MenuCenter/WoodenBoard/MenuMargin/MenuContent/SlotButtons/Slot3Button
@onready var back_button: Button = $MenuCenter/WoodenBoard/MenuMargin/MenuContent/BackButton
@onready var overwrite_overlay: Control = $OverwriteOverlay
@onready var overwrite_message: Label = $OverwriteOverlay/ConfirmCenter/WoodenBoard/MenuMargin/MenuContent/MessageLabel
@onready var overwrite_button: Button = $OverwriteOverlay/ConfirmCenter/WoodenBoard/MenuMargin/MenuContent/ButtonRow/OverwriteButton
@onready var cancel_button: Button = $OverwriteOverlay/ConfirmCenter/WoodenBoard/MenuMargin/MenuContent/ButtonRow/CancelButton

@onready var main_game_scene: PackedScene = preload("res://Scenes/Game/mainScene.tscn") as PackedScene

var _pending_overwrite_slot: int = 0


func _ready() -> void:
	slot_1_button.pressed.connect(func(): _on_slot_pressed(1))
	slot_2_button.pressed.connect(func(): _on_slot_pressed(2))
	slot_3_button.pressed.connect(func(): _on_slot_pressed(3))
	back_button.pressed.connect(_on_back_pressed)
	overwrite_button.pressed.connect(_on_overwrite_confirmed)
	cancel_button.pressed.connect(_hide_overwrite_confirmation)
	overwrite_overlay.visible = false
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and is_node_ready():
		refresh()


func refresh() -> void:
	_update_slot_button(slot_1_button, 1)
	_update_slot_button(slot_2_button, 2)
	_update_slot_button(slot_3_button, 3)


func _update_slot_button(button: Button, slot: int) -> void:
	var info: Dictionary = SaveManager.get_save_slot_info(slot)

	if not bool(info.get("exists", false)):
		button.text = "Slot %d\nEmpty" % slot
		return

	button.text = "Slot %d\n%s, Day %d, Year %d\nMoney: %d" % [
		slot,
		SaveManager.get_season_name_from_month(int(info.get("month", 1))),
		int(info.get("day", 1)),
		int(info.get("year", 1)),
		int(info.get("money", 0))
	]


func _start_slot(slot: int) -> void:
	SaveManager.start_new_game(slot)
	gamemanager.startGame()
	get_tree().change_scene_to_packed(main_game_scene)


func _on_back_pressed() -> void:
	gamemanager.showMainMenu()


func _on_slot_pressed(slot: int) -> void:
	if SaveManager.has_save(slot):
		_show_overwrite_confirmation(slot)
		return

	_start_slot(slot)


func _show_overwrite_confirmation(slot: int) -> void:
	_pending_overwrite_slot = slot
	overwrite_message.text = "Slot %d already has a saved game.\nOverwrite it and start a new game?" % slot
	overwrite_overlay.visible = true
	overwrite_overlay.move_to_front()


func _hide_overwrite_confirmation() -> void:
	_pending_overwrite_slot = 0
	overwrite_overlay.visible = false


func _on_overwrite_confirmed() -> void:
	if _pending_overwrite_slot <= 0:
		_hide_overwrite_confirmation()
		return

	_start_slot(_pending_overwrite_slot)
