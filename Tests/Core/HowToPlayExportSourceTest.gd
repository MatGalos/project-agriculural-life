extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- HowToPlayExportSourceTest ---")

	var menu_source := _read_file("res://Scripts/UIs/Menus/HowToPlayMenu.gd")
	var export_preset := _read_file("res://export_presets.cfg")

	runner.assert_true(
		menu_source.contains("DEFAULT_HOW_TO_PLAY_TEXT"),
		"How to Play menu has embedded fallback text for exported builds"
	)
	runner.assert_true(
		menu_source.contains("Buy seeds in the Shop app."),
		"How to Play fallback contains real gameplay help text"
	)
	runner.assert_true(
		not menu_source.contains("Help text is missing."),
		"How to Play export no longer shows missing file fallback text"
	)
	runner.assert_true(
		export_preset.contains("HOW_TO_PLAY.md"),
		"Windows export preset includes the How to Play markdown file"
	)


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return ""

	var text := file.get_as_text()
	file.close()
	return text
