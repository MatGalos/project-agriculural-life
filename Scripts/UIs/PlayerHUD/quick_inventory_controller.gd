extends Control

const ICON_SIZE := Vector2(48, 48)

@onready var slots := [
	$PanelContainer/HBoxContainer/Slot1,
	$PanelContainer/HBoxContainer/Slot2,
	$PanelContainer/HBoxContainer/Slot3,
	$PanelContainer/HBoxContainer/Slot4,
	$PanelContainer/HBoxContainer/Slot5
]

func _ready() -> void:
	if HotbarManager.inventory_data and not HotbarManager.inventory_data.inventory_changed.is_connected(refresh):
		HotbarManager.inventory_data.inventory_changed.connect(refresh)

	HotbarManager.selected_slot_changed.connect(_on_selected_slot_changed)
	refresh()

func refresh() -> void:
	if HotbarManager.inventory_data == null or HotbarManager.hotbar_data == null:
		return

	HotbarManager.inventory_data.setup()

	for i in range(slots.size()):
		var slot_node = slots[i]
		var icon_rect: TextureRect = slot_node.get_node_or_null("IconRect") as TextureRect
		var amount_label: Label = slot_node.get_node_or_null("AmountLabel") as Label

		if icon_rect == null or amount_label == null:
			continue

		_setup_slot_ui(icon_rect, amount_label)

		var inventory_index := HotbarManager.hotbar_data.get_inventory_slot_index(i)
		var inventory_slot := HotbarManager.inventory_data.get_slot(inventory_index)

		if inventory_slot == null or inventory_slot.is_empty():
			icon_rect.texture = null
			icon_rect.visible = false
			amount_label.text = ""
			amount_label.visible = false
		else:
			icon_rect.texture = inventory_slot.item_data.icon
			icon_rect.visible = inventory_slot.item_data.icon != null

			if inventory_slot.amount > 1:
				amount_label.text = str(inventory_slot.amount)
				amount_label.visible = true
			else:
				amount_label.visible = false

	_update_highlight(HotbarManager.get_selected_slot())

func _on_selected_slot_changed(slot_index: int) -> void:
	_update_highlight(slot_index)


func _update_highlight(active_slot: int) -> void:
	for i in range(slots.size()):
		var slot = slots[i]

		if i + 1 == active_slot:
			slot.modulate = Color(1, 1, 1, 1)
		else:
			slot.modulate = Color(0.45, 0.45, 0.45, 0.85)


func _setup_slot_ui(icon_rect: TextureRect, amount_label: Label) -> void:
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
