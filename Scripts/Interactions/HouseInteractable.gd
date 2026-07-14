extends Interactable
class_name HouseInteractable


func get_prompt_text() -> String:
	return "Press E to sleep."


func interact() -> void:
	TimeManager.skip_to_morning()
