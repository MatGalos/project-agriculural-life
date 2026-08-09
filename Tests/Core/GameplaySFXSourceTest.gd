extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- GameplaySFXSourceTest ---")

	var sound_source := _read_file("res://Scripts/GameManagers/UISoundManager.gd")
	var tool_source := _read_file("res://Scripts/GameManagers/ToolManager.gd")
	var shop_source := _read_file("res://Scripts/PhoneApps/ShopApp/ShopPanel.gd")
	var sell_source := _read_file("res://Scripts/PhoneApps/SellApp/SellingPanel.gd")
	var storage_source := _read_file("res://Scripts/UIs/PlayerHUD/storage_panel.gd")
	var hud_source := _read_file("res://Scripts/UIs/PlayerHUD/player_hud.gd")

	runner.assert_true(sound_source.contains("res://Assets/Audio/Gameplay/plant_seed.wav"), "Plant seed SFX path is wired")
	runner.assert_true(sound_source.contains("res://Assets/Audio/Gameplay/till_soil.wav"), "Till soil SFX path is wired")
	runner.assert_true(sound_source.contains("res://Assets/Audio/Gameplay/water_crop.wav"), "Water crop SFX path is wired")
	runner.assert_true(sound_source.contains("res://Assets/Audio/Gameplay/harvest_crop.wav"), "Harvest crop SFX path is wired")
	runner.assert_true(sound_source.contains("res://Assets/Audio/Gameplay/buy_item.wav"), "Buy item SFX path is wired")
	runner.assert_true(sound_source.contains("res://Assets/Audio/Gameplay/sell_item.wav"), "Sell item SFX path is wired")
	runner.assert_true(sound_source.contains("res://Assets/Audio/Gameplay/transfer_item.wav"), "Transfer item SFX path is wired")
	runner.assert_true(sound_source.contains("res://Assets/Audio/Gameplay/action_error.wav"), "Action error SFX path is wired")

	runner.assert_true(sound_source.contains("func play_plant_seed()"), "Plant seed playback method exists")
	runner.assert_true(sound_source.contains("func play_till_soil()"), "Till soil playback method exists")
	runner.assert_true(sound_source.contains("func play_water_crop()"), "Water crop playback method exists")
	runner.assert_true(sound_source.contains("func play_harvest_crop()"), "Harvest crop playback method exists")
	runner.assert_true(sound_source.contains("func play_buy_item()"), "Buy item playback method exists")
	runner.assert_true(sound_source.contains("func play_sell_item()"), "Sell item playback method exists")
	runner.assert_true(sound_source.contains("func play_transfer_item()"), "Transfer item playback method exists")
	runner.assert_true(sound_source.contains("func play_action_error()"), "Action error playback method exists")

	runner.assert_true(tool_source.contains("UISoundManager.play_plant_seed()"), "Successful planting plays plant seed SFX")
	runner.assert_true(tool_source.contains("UISoundManager.play_till_soil()"), "Successful tilling plays till soil SFX")
	runner.assert_true(tool_source.contains("UISoundManager.play_water_crop()"), "Successful watering plays water crop SFX")
	runner.assert_true(tool_source.contains("UISoundManager.play_harvest_crop()"), "Successful harvest plays harvest crop SFX")
	runner.assert_true(tool_source.contains("_show_action_error"), "Tool errors route through action error helper")
	runner.assert_true(tool_source.contains("PlayerHUD.EVENT_MESSAGE_DURATION, false"), "Tool gameplay feedback suppresses notification SFX duplicates")

	runner.assert_true(shop_source.contains("UISoundManager.play_buy_item()"), "Successful purchase plays buy item SFX")
	runner.assert_true(shop_source.contains("UISoundManager.play_action_error()"), "Shop purchase failures play action error SFX")
	runner.assert_true(sell_source.contains("UISoundManager.play_sell_item()"), "Successful sale plays sell item SFX")
	runner.assert_true(sell_source.contains("UISoundManager.play_action_error()"), "Sell failures play action error SFX")
	runner.assert_true(storage_source.contains("UISoundManager.play_transfer_item()"), "Successful storage transfer plays transfer item SFX")
	runner.assert_true(storage_source.contains("UISoundManager.play_action_error()"), "Storage transfer failures play action error SFX")
	runner.assert_true(hud_source.contains("play_notification_sound: bool = true"), "HUD notification sound can be suppressed for gameplay feedback")


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return ""

	var text := file.get_as_text()
	file.close()
	return text
