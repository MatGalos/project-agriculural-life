extends Interactable
class_name SiloInteractable


func get_prompt_text() -> String:
	return "Press E to open Silo."


func interact() -> void:
	var player_hud := get_tree().get_first_node_in_group("player_hud") as PlayerHUD

	if player_hud:
		player_hud.toggle_storage()
