extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- UIResponsivenessSourceTest ---")

	var phone_source := _read_file("res://Scripts/UIs/PlayerHUD/phone_panel.gd")
	var inventory_source := _read_file("res://Scripts/UIs/PlayerHUD/inventory_panel.gd")
	var storage_source := _read_file("res://Scripts/UIs/PlayerHUD/storage_panel.gd")
	var options_source := _read_file("res://Scripts/UIs/Menus/OptionsMenu/optionsMenu.gd")
	var hud_source := _read_file("res://Scripts/UIs/PlayerHUD/player_hud.gd")

	runner.assert_true(phone_source.contains("BASE_PHONE_SIZE"), "FarmPhone has a responsive base size")
	runner.assert_true(phone_source.contains("_apply_responsive_layout"), "FarmPhone recalculates size for viewport/interface scale")
	runner.assert_true(phone_source.contains("pivot_offset = BASE_PHONE_SIZE * 0.5"), "FarmPhone scales from its center pivot")
	runner.assert_true(phone_source.contains("scale = Vector2.ONE * fit_scale"), "FarmPhone uses uniform panel scaling instead of shrinking inner layout")
	runner.assert_true(phone_source.contains("GraphicsSettingsManager.interface_scale_changed"), "FarmPhone responds to interface scale changes")

	runner.assert_true(inventory_source.contains("BASE_PANEL_SIZE"), "Inventory has a responsive base size")
	runner.assert_true(inventory_source.contains("_apply_slot_sizes"), "Inventory rescales hotbar/grid slots")
	runner.assert_true(inventory_source.contains("HOTBAR_SLOT_BASE_SIZE"), "Inventory keeps hotbar slot responsive sizing centralized")
	runner.assert_true(inventory_source.contains("INVENTORY_SLOT_BASE_SIZE"), "Inventory keeps grid slot responsive sizing centralized")

	runner.assert_true(storage_source.contains("BASE_PANEL_SIZE"), "Silo Storage has a responsive base size")
	runner.assert_true(storage_source.contains("_apply_responsive_layout"), "Silo Storage recalculates panel size")
	runner.assert_true(storage_source.contains("_position_scroll_lines_deferred"), "Silo Storage repositions custom scroll lines after responsive changes")
	runner.assert_true(storage_source.contains("func _drop_data(drop_position: Vector2, data: Variant)"), "Silo Storage drop handler avoids Control.position shadowing")
	runner.assert_true(storage_source.contains("ScrollContainer.SCROLL_MODE_SHOW_NEVER"), "Silo Storage uses typed scroll mode enum for custom scroll lines")

	runner.assert_true(options_source.contains("responsive_boards"), "Options menu tracks responsive boards")
	runner.assert_true(options_source.contains("_cache_board_base_sizes"), "Options menu caches board base sizes")
	runner.assert_true(options_source.contains("_apply_responsive_layout"), "Options menu rescales large submenu boards")

	runner.assert_true(hud_source.contains("_update_bottom_panels"), "HUD keeps bottom notification and hotbar layout centralized")
	runner.assert_true(hud_source.contains("_set_bottom_left_rect(event_controller"), "HUD positions notifications from bottom-left")
	runner.assert_true(hud_source.contains("_set_bottom_center_rect(quick_inventory_controller"), "HUD positions hotbar from bottom-center")
	runner.assert_true(hud_source.contains("func set_ui_mode(mode: UIMode)"), "HUD UI mode setter uses typed enum parameter")
	runner.assert_true(not hud_source.contains("(is_visible: bool)"), "HUD visibility helpers avoid CanvasLayer.is_visible shadowing")


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return ""

	var text := file.get_as_text()
	file.close()
	return text
