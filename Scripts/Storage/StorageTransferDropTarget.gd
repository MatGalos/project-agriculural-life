extends Control
class_name StorageTransferDropTarget

@export_enum("storage", "inventory") var target_type: String = "storage"

var storage_panel: StoragePanel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	storage_panel = _find_storage_panel()


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if storage_panel == null:
		storage_panel = _find_storage_panel()

	return storage_panel != null and storage_panel.can_accept_transfer_drop(target_type, data)


func _drop_data(_position: Vector2, data: Variant) -> void:
	if storage_panel == null:
		storage_panel = _find_storage_panel()

	if storage_panel:
		storage_panel.drop_transfer_to(target_type, data)


func _find_storage_panel() -> StoragePanel:
	var current := get_parent()

	while current:
		if current is StoragePanel:
			return current as StoragePanel

		current = current.get_parent()

	return null
