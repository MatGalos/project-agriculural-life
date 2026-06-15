extends RefCounted

var runner: TestRunner
var wheat: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")
var wheat_seed: ItemData = preload("res://Data/Items/Seeds/wheat_seed_item.tres")


func run() -> void:
	print("\n--- InventoryDataTest ---")

	var inventory := InventoryData.new()
	inventory.slot_count = 3
	inventory.setup()

	runner.assert_eq(inventory.slots.size(), 3, "Inventory creates correct slot count")

	var leftover := inventory.add_item(wheat, 10)
	runner.assert_eq(leftover, 0, "Inventory add item without leftover")
	runner.assert_true(inventory.has_item(wheat, 10), "Inventory has added item")
	runner.assert_eq(inventory.get_item_count(wheat), 10, "Inventory item count works")

	var removed := inventory.remove_item(wheat, 4)
	runner.assert_true(removed, "Inventory remove item returns true")
	runner.assert_eq(inventory.get_item_count(wheat), 6, "Inventory amount after remove")

	var failed_remove := inventory.remove_item(wheat, 999)
	runner.assert_true(not failed_remove, "Inventory cannot remove more than owned")
	runner.assert_eq(inventory.get_item_count(wheat), 6, "Inventory unchanged after failed remove")

	inventory.add_item(wheat_seed, 5)
	runner.assert_true(inventory.has_item(wheat_seed, 5), "Inventory can store second item")
