extends Interactable
class_name HouseInteractable


func get_prompt_text() -> String:
	return "E - Sleep"


func interact() -> void:
	TimeManager.skip_to_morning()
