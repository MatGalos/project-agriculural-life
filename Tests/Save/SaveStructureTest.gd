extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- SaveStructureTest ---")

	var save_data := SaveManager._create_save_data()

	runner.assert_true(save_data.has("version"), "Save has version")
	runner.assert_true(save_data.has("player"), "Save has player section")
	runner.assert_true(save_data.has("time"), "Save has time section")
	runner.assert_true(save_data.has("weather"), "Save has weather section")
	runner.assert_true(save_data.has("storage"), "Save has storage section")
	runner.assert_true(save_data.has("market"), "Save has market section")
	runner.assert_true(save_data.has("sales_stats"), "Save has sales_stats section")
	runner.assert_true(save_data.has("events"), "Save has events section")
	runner.assert_true(save_data.has("news"), "Save has news section")
	runner.assert_true(save_data.has("world"), "Save has world section")

	var player_data: Dictionary = save_data["player"]
	runner.assert_true(player_data.has("money"), "Player save has money")
	runner.assert_true(player_data.has("inventory"), "Player save has inventory")
	runner.assert_true(player_data.has("hotbar"), "Player save has hotbar")
	runner.assert_true(player_data.has("position"), "Player save has position")
