extends Interactable
class_name SiloInteractable


func get_prompt_text() -> String:
	return "E - Open Silo"


func interact() -> void:
	var storage_panel = get_tree().get_first_node_in_group("storage_panel")

	if storage_panel:
		storage_panel.toggle()
