extends Interactable
class_name WellInteractable


func get_prompt_text() -> String:
	return "Press E to fill watering can."


func interact() -> void:
	ToolManager.refill_watering_can()
