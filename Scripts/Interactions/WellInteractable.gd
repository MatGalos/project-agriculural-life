extends Interactable
class_name WellInteractable


func get_prompt_text() -> String:
	return "E - Fill Watering Can"


func interact() -> void:
	ToolManager.refill_watering_can()
