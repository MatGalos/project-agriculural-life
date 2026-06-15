extends RefCounted

var runner: TestRunner
var wheat: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")
var wheat_seed: ItemData = preload("res://Data/Items/Seeds/wheat_seed_item.tres")


func run() -> void:
	print("\n--- InventorySaveTest ---")

	var inventory := HotbarManager.inventory_data
	inventory.setup()
	inventory.clear_inventory()

	inventory.add_item(wheat, 12)
	inventory.add_item(wheat_seed, 5)

	var save_data := SaveManager._create_inventory_save_data()

	inventory.clear_inventory()
	runner.assert_eq(inventory.get_item_count(wheat), 0, "Inventory cleared before load")

	SaveManager._apply_inventory_save_data(save_data)

	runner.assert_eq(inventory.get_item_count(wheat), 12, "Inventory wheat restored")
	runner.assert_eq(inventory.get_item_count(wheat_seed), 5, "Inventory wheat seeds restored")
