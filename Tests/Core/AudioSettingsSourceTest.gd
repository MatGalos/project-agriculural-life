extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- AudioSettingsSourceTest ---")

	var project_source := _read_file("res://project.godot")
	var manager_source := _read_file("res://Scripts/GameManagers/AudioSettingsManager.gd")
	var panel_source := _read_file("res://Scripts/UIs/Menus/OptionsMenu/AdditionalMenus/audio.gd")
	var options_scene := _read_file("res://Scenes/UIs/Menus/OptionsMenu/optionsMenu.tscn")
	var bus_layout := _read_file("res://default_bus_layout.tres")
	var save_source := _read_file("res://Scripts/GameManagers/SaveManager.gd")

	runner.assert_true(project_source.contains("AudioSettingsManager"), "Audio settings manager is registered as autoload")
	runner.assert_true(project_source.contains("buses/default_bus_layout=\"res://default_bus_layout.tres\""), "Project uses audio bus layout")

	runner.assert_true(bus_layout.contains("bus/1/name = &\"SFX\""), "SFX bus exists")
	runner.assert_true(bus_layout.contains("bus/2/name = &\"Notifications\""), "Notifications bus exists")
	runner.assert_true(bus_layout.contains("bus/3/name = &\"Music\""), "Music bus exists")
	runner.assert_true(bus_layout.contains("bus/1/send = &\"Master\""), "SFX sends to Master")
	runner.assert_true(bus_layout.contains("bus/2/send = &\"Master\""), "Notifications sends to Master")
	runner.assert_true(bus_layout.contains("bus/3/send = &\"Master\""), "Music sends to Master")

	runner.assert_true(manager_source.contains("const CONFIG_PATH := \"user://settings.cfg\""), "Audio settings use settings config file")
	runner.assert_true(manager_source.contains("linear_to_db(clamped_value)"), "Audio manager converts linear volume to dB")
	runner.assert_true(manager_source.contains("AudioServer.set_bus_mute(bus_index, should_mute)"), "Audio manager mutes 0 percent volume")
	runner.assert_true(manager_source.contains("AudioServer.get_bus_index(bus_name)"), "Audio manager resolves buses by name")
	runner.assert_true(manager_source.contains("master_volume"), "Audio manager stores master volume")
	runner.assert_true(manager_source.contains("sfx_volume"), "Audio manager stores SFX volume")
	runner.assert_true(manager_source.contains("notifications_volume"), "Audio manager stores notifications volume")
	runner.assert_true(manager_source.contains("music_volume"), "Audio manager stores music volume")

	runner.assert_true(panel_source.contains("Master Volume"), "Sound options expose Master Volume")
	runner.assert_true(panel_source.contains("SFX Volume"), "Sound options expose SFX Volume")
	runner.assert_true(panel_source.contains("Notifications Volume"), "Sound options expose Notifications Volume")
	runner.assert_true(panel_source.contains("Music Volume"), "Sound options expose Music Volume")
	runner.assert_true(panel_source.contains("HSlider.new()"), "Sound options use sliders")
	runner.assert_true(panel_source.contains("value / 100.0"), "Sound options convert percent to 0-1 values")
	runner.assert_true(options_scene.contains("AdditionalMenus/audio.gd"), "Sound options content is wired to audio panel script")

	runner.assert_true(not save_source.contains("master_volume"), "Gameplay saves do not store audio settings")
	runner.assert_true(not save_source.contains("music_volume"), "Gameplay save format remains separate from audio settings")


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return ""

	var text := file.get_as_text()
	file.close()
	return text
