extends RefCounted

var runner: TestRunner

const UI_SCENE_PATHS := [
	"res://Scenes/UIs/Menus/LaunchMenu/MainMenu.tscn",
	"res://Scenes/UIs/Menus/LaunchMenu/AdditionalMenus/load_game_panel.tscn",
	"res://Scenes/UIs/Menus/LaunchMenu/AdditionalMenus/new_game_panel.tscn",
	"res://Scenes/UIs/Menus/OptionsMenu/optionsMenu.tscn",
	"res://Scenes/UIs/Menus/PauseMenu/pauseMenu.tscn",
	"res://Scenes/UIs/PlayerHUD/inventory_panel.tscn",
	"res://Scenes/UIs/PlayerHUD/phone_panel.tscn",
	"res://Scenes/UIs/PlayerHUD/player_hud.tscn",
	"res://Scenes/UIs/PlayerHUD/Phone/CommodityExchangeApp/commodity_exchange_panel.tscn",
	"res://Scenes/UIs/PlayerHUD/Phone/NewsApp/news_panel.tscn",
	"res://Scenes/UIs/PlayerHUD/Phone/SellApp/SellingPanel.tscn",
	"res://Scenes/UIs/PlayerHUD/Phone/ShopApp/shop_Panel.tscn",
	"res://Scenes/UIs/PlayerHUD/Phone/WeatherApp/weather_panel.tscn",
	"res://Scenes/UIs/PlayerHUD/Storage/storage_panel.tscn"
]

const FORBIDDEN_VISIBLE_TEXT_TOKENS := [
	"potatoe",
	"tomatoe",
	"wheat_item",
	"crop_wheat",
	"event_id",
	"commodity_id",
	"Day +"
]


func run() -> void:
	print("\n--- UIVisualPolishSourceTest ---")

	_assert_visible_text_avoids_technical_ids()
	_assert_weather_forecast_uses_dates()
	_assert_phone_app_safe_insets()
	_assert_manual_checklist_tracks_visual_polish()


func _assert_visible_text_avoids_technical_ids() -> void:
	for path in UI_SCENE_PATHS:
		var text := _read_file(path)
		runner.assert_true(not text.is_empty(), "%s loads for visible text audit" % path)

		for line in text.split("\n"):
			if not line.strip_edges().begins_with("text = "):
				continue

			for token in FORBIDDEN_VISIBLE_TEXT_TOKENS:
				runner.assert_true(
					not line.contains(token),
					"%s visible text avoids technical token %s" % [path, token]
				)


func _assert_weather_forecast_uses_dates() -> void:
	var row_scene := _read_file("res://Scenes/UIs/PlayerHUD/Phone/WeatherApp/weather_forecast_row.tscn")
	var row_script := _read_file("res://Scripts/PhoneApps/WeatherApp/WeatherForecastRow.gd")
	var panel_script := _read_file("res://Scripts/PhoneApps/WeatherApp/WeatherPanel.gd")

	runner.assert_true(not row_scene.contains("Tomorrow"), "Weather forecast row scene no longer defaults to Tomorrow")
	runner.assert_true(not row_script.contains("Day +%d"), "Weather forecast row script no longer formats Day +N")
	runner.assert_true(panel_script.contains("_get_forecast_date_label"), "Weather panel owns future season date label formatting")
	runner.assert_true(panel_script.contains("UIFormatHelper.season_day"), "Weather panel uses shared season day formatting")


func _assert_phone_app_safe_insets() -> void:
	_assert_scene_margin_left(
		"res://Scenes/UIs/PlayerHUD/Phone/CommodityExchangeApp/commodity_exchange_panel.tscn",
		12,
		"Market app"
	)
	_assert_scene_margin_left(
		"res://Scenes/UIs/PlayerHUD/Phone/NewsApp/news_panel.tscn",
		12,
		"News app"
	)
	_assert_scene_margin_left(
		"res://Scenes/UIs/PlayerHUD/Phone/SellApp/SellingPanel.tscn",
		12,
		"Sell app"
	)
	_assert_scene_margin_left(
		"res://Scenes/UIs/PlayerHUD/Phone/ShopApp/shop_Panel.tscn",
		12,
		"Shop app"
	)
	_assert_scene_margin_left(
		"res://Scenes/UIs/PlayerHUD/Phone/WeatherApp/weather_panel.tscn",
		30,
		"Weather app"
	)


func _assert_manual_checklist_tracks_visual_polish() -> void:
	var testing_docs := _read_file("res://Docs/testing.md")
	runner.assert_true(
		testing_docs.contains("left-edge titles are not clipped"),
		"Manual UI checklist covers FarmPhone left-edge clipping"
	)
	runner.assert_true(
		testing_docs.contains("actual future season dates"),
		"Manual UI checklist covers Weather forecast date labels"
	)


func _assert_scene_margin_left(path: String, minimum: int, label: String) -> void:
	var text := _read_file(path)
	var marker := "theme_override_constants/margin_left = "
	var index := text.find(marker)
	runner.assert_true(index >= 0, "%s has a left margin constant" % label)

	if index < 0:
		return

	var line_end := text.find("\n", index)
	var line_length := line_end - index if line_end >= 0 else text.length() - index
	var line := text.substr(index, line_length)
	var value_text := line.replace(marker, "").strip_edges()
	runner.assert_true(float(value_text) >= float(minimum), "%s keeps safe left inset" % label)


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return ""

	var text := file.get_as_text()
	file.close()
	return text
