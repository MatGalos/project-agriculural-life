extends Control

@onready var slots: Array[PanelContainer] = [
	$PanelContainer/HBoxContainer/Slot1 as PanelContainer,
	$PanelContainer/HBoxContainer/Slot2 as PanelContainer,
	$PanelContainer/HBoxContainer/Slot3 as PanelContainer,
	$PanelContainer/HBoxContainer/Slot4 as PanelContainer,
	$PanelContainer/HBoxContainer/Slot5 as PanelContainer
]

func _ready() -> void:
	HotbarManager.selected_slot_changed.connect(_on_selected_slot_changed)
	_update_highlight(HotbarManager.get_selected_slot())


func _on_selected_slot_changed(slot_index: int) -> void:
	_update_highlight(slot_index)


func _update_highlight(active_slot: int) -> void:
	for i: int in range(slots.size()):
		var slot: PanelContainer = slots[i]

		if i + 1 == active_slot:
			slot.modulate = Color(1, 1, 1, 1)
		else:
			slot.modulate = Color(0.45, 0.45, 0.45, 0.85)
