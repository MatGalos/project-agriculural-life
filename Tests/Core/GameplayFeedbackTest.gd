extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- GameplayFeedbackTest ---")

	var player_hud_source := _read_file("res://Scripts/UIs/PlayerHUD/player_hud.gd")
	var tool_manager_source := _read_file("res://Scripts/GameManagers/ToolManager.gd")
	var character_controller_source := _read_file("res://Scripts/Player/CharacterController.gd")
	var storage_panel_source := _read_file("res://Scripts/UIs/PlayerHUD/storage_panel.gd")
	var shop_panel_source := _read_file("res://Scripts/PhoneApps/ShopApp/ShopPanel.gd")
	var sell_panel_source := _read_file("res://Scripts/PhoneApps/SellApp/SellingPanel.gd")

	runner.assert_true(player_hud_source.contains("EVENT_MESSAGE_REPEAT_COOLDOWN"), "HUD gameplay feedback has repeat cooldown")
	runner.assert_true(player_hud_source.contains("_event_message_last_shown"), "HUD remembers recently shown feedback")

	runner.assert_true(shop_panel_source.contains("Cart is empty."), "Shop feedback covers empty cart")
	runner.assert_true(shop_panel_source.contains("Not enough money."), "Shop feedback covers not enough money")
	runner.assert_true(shop_panel_source.contains("Inventory is full."), "Shop feedback covers full inventory")
	runner.assert_true(shop_panel_source.contains("Could not add items to inventory."), "Shop feedback covers failed inventory add")
	runner.assert_true(shop_panel_source.contains("Bought %d items for %s."), "Shop feedback covers successful purchase")

	runner.assert_true(sell_panel_source.contains("Sold %dx %s for %s."), "Sell feedback covers single product sale")
	runner.assert_true(sell_panel_source.contains("Select an amount to sell."), "Sell feedback covers missing selected amount")
	runner.assert_true(sell_panel_source.contains("Storage is empty."), "Sell feedback covers empty storage")
	runner.assert_true(sell_panel_source.contains("Not enough items."), "Sell feedback covers missing storage items")
	runner.assert_true(sell_panel_source.contains("Sold selected items for %s."), "Sell feedback covers selected multi-item sale")

	runner.assert_true(storage_panel_source.contains("Transferred %dx %s to Silo."), "Silo feedback covers transfer to silo")
	runner.assert_true(storage_panel_source.contains("Transferred %dx %s to Inventory."), "Silo feedback covers transfer to inventory")
	runner.assert_true(storage_panel_source.contains("Empty Storage"), "Silo feedback covers empty storage")
	runner.assert_true(storage_panel_source.contains("Empty Inventory."), "Silo feedback covers empty inventory")
	runner.assert_true(storage_panel_source.contains("Not enough items."), "Silo feedback covers missing items")
	runner.assert_true(storage_panel_source.contains("Cannot transfer item."), "Silo feedback covers impossible transfers")

	runner.assert_true(tool_manager_source.contains("No tool selected.") or character_controller_source.contains("No tool selected."), "World feedback covers no selected tool")
	runner.assert_true(tool_manager_source.contains("Cannot use this here.") or character_controller_source.contains("Cannot use this here."), "World feedback covers invalid tool use")
	runner.assert_true(tool_manager_source.contains("Cannot plant here."), "World feedback covers invalid planting")
	runner.assert_true(tool_manager_source.contains("No seeds selected."), "World feedback covers missing seeds")
	runner.assert_true(tool_manager_source.contains("Need a watering can."), "World feedback covers watering can failures")
	runner.assert_true(tool_manager_source.contains("Crop is not ready."), "World feedback covers unready crops")
	runner.assert_true(tool_manager_source.contains("Cannot harvest this."), "World feedback covers invalid harvest")
	runner.assert_true(character_controller_source.contains("Nothing to interact with."), "World feedback covers empty interaction target")
	runner.assert_true(tool_manager_source.contains("Used 1x %s."), "Hotbar feedback covers item use")
	runner.assert_true(tool_manager_source.contains("Added %dx %s."), "Inventory feedback covers item gain")


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return ""

	var text := file.get_as_text()
	file.close()
	return text
