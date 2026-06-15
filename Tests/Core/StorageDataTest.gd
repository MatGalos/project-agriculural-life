extends RefCounted

var runner: TestRunner
var wheat: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")


func run() -> void:
	print("\n--- StorageDataTest ---")

	var storage := StorageData.new()

	storage.add_item(wheat, 10)
	runner.assert_eq(storage.get_item_amount(wheat), 10, "Storage add item")

	var removed := storage.remove_item(wheat, 4)
	runner.assert_true(removed, "Storage remove item returns true")
	runner.assert_eq(storage.get_item_amount(wheat), 6, "Storage amount after remove")

	var failed_remove := storage.remove_item(wheat, 999)
	runner.assert_true(not failed_remove, "Storage cannot remove more than stored")
	runner.assert_eq(storage.get_item_amount(wheat), 6, "Storage unchanged after failed remove")
