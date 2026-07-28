extends RefCounted

var runner: TestRunner

const PHONE_SCENE := preload("res://Scenes/UIs/PlayerHUD/phone_panel.tscn")


func run() -> void:
	print("\n--- FarmPhoneLayoutTest ---")

	var phone := PHONE_SCENE.instantiate() as Control
	runner.assert_true(phone != null, "FarmPhone scene instantiates")

	if phone == null:
		return

	_assert_required_nodes(phone)
	_assert_home_grid(phone)
	_assert_app_container(phone)
	_assert_no_branding(phone)

	phone.free()


func _assert_required_nodes(phone: Control) -> void:
	runner.assert_true(phone.get_node_or_null("PhoneShell") != null, "FarmPhone has outer shell")
	runner.assert_true(phone.get_node_or_null("PhoneShell/ShellMargin/DeviceStack/TopBezel/Speaker") != null, "FarmPhone has speaker detail")
	runner.assert_true(phone.get_node_or_null("PhoneShell/ShellMargin/DeviceStack/TopBezel/Camera") != null, "FarmPhone has camera detail")
	runner.assert_true(phone.get_node_or_null("PhoneShell/ShellMargin/DeviceStack/ScreenFrame") != null, "FarmPhone has screen frame")
	runner.assert_true(phone.get_node_or_null("PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/Wallpaper") != null, "FarmPhone has wallpaper")
	runner.assert_true(phone.get_node_or_null("PhoneShell/ShellMargin/DeviceStack/HomeBezel/HomeButton") != null, "FarmPhone has home button")


func _assert_home_grid(phone: Control) -> void:
	var grid := phone.get_node_or_null("PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/HomeScreen/HomeGrid") as GridContainer
	runner.assert_true(grid != null, "FarmPhone home screen has app grid")

	if grid == null:
		return

	runner.assert_eq(grid.columns, 4, "FarmPhone app grid uses 4 columns")
	runner.assert_eq(grid.get_child_count(), 16, "FarmPhone app grid has 16 slots")

	var expected_labels := {
		"NewsIcon": "News",
		"MarketIcon": "Market",
		"ShopIcon": "Shop",
		"WeatherIcon": "Weather",
		"SellIcon": "Sell",
		"StorageIcon": "Storage"
	}

	for icon_name in expected_labels.keys():
		var icon := grid.get_node_or_null(icon_name)
		runner.assert_true(icon != null, "FarmPhone grid has %s" % icon_name)

		if icon == null:
			continue

		var button := icon.get_node_or_null("IconButton") as Button
		var label := icon.get_node_or_null("NameLabel") as Label
		runner.assert_true(button != null, "%s has icon button" % icon_name)
		runner.assert_true(label != null, "%s has name label" % icon_name)

		if label:
			runner.assert_eq(label.text, expected_labels[icon_name], "%s uses expected label" % icon_name)

	var storage_button := grid.get_node_or_null("StorageIcon/IconButton") as Button
	runner.assert_true(storage_button != null and storage_button.disabled, "Storage icon is visible but not wired as a phone app yet")


func _assert_app_container(phone: Control) -> void:
	var app_container := phone.get_node_or_null("PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/AppContainer") as Control
	runner.assert_true(app_container != null, "FarmPhone has shared app container")

	if app_container == null:
		return

	for app_name in ["NewsApp", "StockMarketApp", "ShopApp", "WeatherApp", "SellApp"]:
		var app := app_container.get_node_or_null(app_name) as Control
		runner.assert_true(app != null, "FarmPhone app container has %s" % app_name)
		runner.assert_true(app == null or not app.visible, "%s starts hidden" % app_name)


func _assert_no_branding(phone: Control) -> void:
	var visible_texts: Array[String] = []
	_collect_visible_text(phone, visible_texts)

	for text in visible_texts:
		var normalized := text.to_lower()
		runner.assert_true(not normalized.contains("apple"), "FarmPhone visible text has no Apple branding")
		runner.assert_true(not normalized.contains("iphone"), "FarmPhone visible text has no iPhone branding")


func _collect_visible_text(node: Node, visible_texts: Array[String]) -> void:
	if node is Label:
		visible_texts.append((node as Label).text)
	elif node is Button:
		visible_texts.append((node as Button).text)

	for child in node.get_children():
		_collect_visible_text(child, visible_texts)
