extends Control
class_name InventoryPanel

@export var slot_ui_scene: PackedScene
@export var inventory_data: InventoryData

@onready var slots_grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/SlotsGrid

var slot_ui_nodes: Array[InventorySlotUI] = []

func _ready() -> void:
	visible = false
	add_to_group("inventory_panel")

	if inventory_data and not inventory_data.inventory_changed.is_connected(refresh):
		inventory_data.inventory_changed.connect(refresh)

	if not ToolManager.watering_can_changed.is_connected(refresh):
		ToolManager.watering_can_changed.connect(refresh)

	build_slots()
	refresh()


func open() -> void:
	refresh()
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close() -> void:
	visible = false

	if gamemanager.isInGame and not gamemanager.isPaused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func is_open() -> bool:
	return visible

func build_slots() -> void:
	for child in slots_grid.get_children():
		child.queue_free()

	slot_ui_nodes.clear()

	if inventory_data == null or slot_ui_scene == null:
		return

	inventory_data.setup()

	for _slot in inventory_data.slots:
		var slot_ui: InventorySlotUI = slot_ui_scene.instantiate() as InventorySlotUI
		if slot_ui == null:
			continue

		slots_grid.add_child(slot_ui)
		slot_ui_nodes.append(slot_ui)


func refresh() -> void:
	if inventory_data == null:
		return

	if slot_ui_nodes.size() != inventory_data.slots.size():
		build_slots()

	for i in range(mini(slot_ui_nodes.size(), inventory_data.slots.size())):
		slot_ui_nodes[i].set_slot(i, inventory_data.slots[i])

func move_or_merge_slot(from_index: int, to_index: int) -> void:
	if inventory_data == null:
		return

	inventory_data.move_or_merge_slot(from_index, to_index)

	var hotbar_ui = get_tree().get_first_node_in_group("hotbar_ui")
	if hotbar_ui and hotbar_ui.has_method("refresh"):
		hotbar_ui.refresh()
