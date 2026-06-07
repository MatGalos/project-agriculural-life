extends Control
class_name StoragePanel

@export var storage_data: StorageData
@export var row_scene: PackedScene

@onready var items_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ItemsContainer


func _ready() -> void:
	visible = false
	add_to_group("storage_panel")

	if storage_data and not storage_data.storage_changed.is_connected(refresh):
		storage_data.storage_changed.connect(refresh)

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


func refresh() -> void:
	if storage_data == null or row_scene == null:
		return

	for child in items_container.get_children():
		child.queue_free()

	var items := storage_data.get_all_items()

	for item_entry in items:
		var row := row_scene.instantiate() as StorageItemRow

		if row == null:
			continue

		items_container.add_child(row)
		row.setup(item_entry["item_data"], int(item_entry["amount"]))
