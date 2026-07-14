extends StaticBody3D
class_name Interactable

@export var prompt_text := "Press E to interact."

func interact() -> void:
	return

func get_prompt_text() -> String:
	return prompt_text

func get_display_name() -> String:
	if get_parent():
		return str(get_parent().name)

	return str(name)
