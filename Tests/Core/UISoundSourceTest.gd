extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- UISoundSourceTest ---")

	var project_source := _read_file("res://project.godot")
	var ui_sound_source := _read_file("res://Scripts/GameManagers/UISoundManager.gd")
	var main_menu_source := _read_file("res://Scripts/UIs/Menus/LaunchMenu/mainMenu.gd")
	var pause_menu_source := _read_file("res://Scripts/UIs/Menus/PauseMenu/pauseMenu.gd")
	var new_game_source := _read_file("res://Scripts/UIs/Menus/LaunchMenu/AdditionalMenus/NewGamePanel.gd")
	var load_game_source := _read_file("res://Scripts/UIs/Menus/LaunchMenu/AdditionalMenus/LoadGamePanel.gd")
	var options_source := _read_file("res://Scripts/UIs/Menus/OptionsMenu/optionsMenu.gd")
	var phone_source := _read_file("res://Scripts/UIs/PlayerHUD/phone_panel.gd")
	var hud_source := _read_file("res://Scripts/UIs/PlayerHUD/player_hud.gd")

	runner.assert_true(project_source.contains("UISoundManager"), "UI sound manager is registered as autoload")
	runner.assert_true(ui_sound_source.contains("const SFX_BUS := \"SFX\""), "UI sounds route to SFX bus")
	runner.assert_true(ui_sound_source.contains("const NOTIFICATIONS_BUS_FALLBACK := \"Notifications\""), "Notification sounds prefer Notifications bus")
	runner.assert_true(ui_sound_source.contains("const NOTIFICATION_BUS_FALLBACK := \"Notification\""), "Notification sounds support singular fallback bus")
	runner.assert_true(ui_sound_source.contains("AudioStreamPlayer"), "UI sound manager uses AudioStreamPlayer nodes")
	runner.assert_true(ui_sound_source.contains("res://Assets/Audio/UI/ui_click.wav"), "UI click WAV is wired")
	runner.assert_true(ui_sound_source.contains("res://Assets/Audio/UI/ui_phone_open.wav"), "Phone open WAV is wired")
	runner.assert_true(ui_sound_source.contains("res://Assets/Audio/UI/ui_phone_close.wav"), "Phone close WAV is wired")
	runner.assert_true(ui_sound_source.contains("res://Assets/Audio/UI/ui_app_switch.wav"), "App switch WAV is wired")
	runner.assert_true(ui_sound_source.contains("res://Assets/Audio/Notifications/notification_new.wav"), "Notification WAV is wired")
	runner.assert_true(ui_sound_source.contains("ResourceLoader.exists(path)"), "UI sound manager checks missing files safely")
	runner.assert_true(ui_sound_source.contains("NOTIFICATION_COOLDOWN_SECONDS"), "Notification sound has overlap cooldown")
	runner.assert_true(ui_sound_source.contains("func play_ui_click()"), "UI click sound method exists")
	runner.assert_true(ui_sound_source.contains("func play_phone_open()"), "Phone open sound method exists")
	runner.assert_true(ui_sound_source.contains("func play_phone_close()"), "Phone close sound method exists")
	runner.assert_true(ui_sound_source.contains("func play_phone_app_switch()"), "Phone app switch sound method exists")
	runner.assert_true(ui_sound_source.contains("func play_notification_new()"), "Notification sound method exists")
	runner.assert_true(main_menu_source.contains("UISoundManager.play_ui_click()"), "Main menu buttons play UI click")
	runner.assert_true(pause_menu_source.contains("UISoundManager.play_ui_click()"), "Pause menu buttons play UI click")
	runner.assert_true(new_game_source.contains("UISoundManager.play_ui_click()"), "New game slot UI plays UI click")
	runner.assert_true(load_game_source.contains("UISoundManager.play_ui_click()"), "Load game slot UI plays UI click")
	runner.assert_true(options_source.contains("UISoundManager.play_ui_click()"), "Options navigation plays UI click")

	runner.assert_true(phone_source.contains("UISoundManager.play_phone_app_switch()"), "FarmPhone app switching plays app switch sound")
	runner.assert_true(hud_source.contains("UISoundManager.play_phone_open()"), "FarmPhone opening plays phone open sound")
	runner.assert_true(hud_source.contains("UISoundManager.play_phone_close()"), "FarmPhone closing plays phone close sound")
	runner.assert_true(hud_source.contains("UISoundManager.play_notification_new()"), "New HUD notification messages play notification sound")

	runner.assert_true(not ui_sound_source.contains("Music"), "UI sound manager does not route UI or notification sounds to Music")


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return ""

	var text := file.get_as_text()
	file.close()
	return text
