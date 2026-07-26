extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- HotbarDataTest ---")

	var hotbar := HotbarData.new()
	hotbar.hotbar_size = 5
	hotbar.inventory_slot_indexes = [0, 1, 2, 3, 4]
	hotbar.setup()

	runner.assert_eq(hotbar.hotbar_size, 5, "Hotbar size is 5")
	runner.assert_eq(hotbar.inventory_slot_indexes.size(), 5, "Hotbar slot indexes match size")
	runner.assert_eq(hotbar.inventory_slot_indexes, [0, 1, 2, 3, 4], "Hotbar uses the first five inventory slots")

	hotbar.select_slot(2)
	runner.assert_eq(hotbar.selected_slot_index, 2, "Hotbar select slot works")
	runner.assert_eq(hotbar.get_selected_inventory_slot_index(), 2, "Hotbar selected inventory index works")

	hotbar.select_slot(99)
	runner.assert_eq(hotbar.selected_slot_index, 2, "Hotbar ignores invalid high index")

	hotbar.select_slot(-1)
	runner.assert_eq(hotbar.selected_slot_index, 2, "Hotbar ignores invalid low index")

	runner.assert_eq(hotbar.get_inventory_slot_index(4), 4, "Hotbar gets inventory index")
	runner.assert_eq(hotbar.get_inventory_slot_index(99), -1, "Hotbar invalid inventory index returns -1")
