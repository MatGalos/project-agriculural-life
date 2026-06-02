extends Control

@onready var slots := [
	$PanelContainer/HBoxContainer/Slot1,
	$PanelContainer/HBoxContainer/Slot2,
	$PanelContainer/HBoxContainer/Slot3,
	$PanelContainer/HBoxContainer/Slot4,
	$PanelContainer/HBoxContainer/Slot5
]

func _ready():
	HotbarManager.selected_slot_changed.connect(_on_selected_slot_changed)
	_update_highlight(HotbarManager.get_selected_slot())


func _on_selected_slot_changed(slot_index: int):
	_update_highlight(slot_index)


func _update_highlight(active_slot: int):
	for i in range(slots.size()):
		var slot = slots[i]

		if i + 1 == active_slot:
			slot.modulate = Color(1, 1, 1, 1)
		else:
			slot.modulate = Color(0.45, 0.45, 0.45, 0.85)
