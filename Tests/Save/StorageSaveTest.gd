extends RefCounted

var runner: TestRunner
var wheat: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")


func run() -> void:
	print("\n--- StorageSaveTest ---")

	SaveManager.silo_storage.stored_items.clear()
	SaveManager.silo_storage.add_item(wheat, 250)

	var save_data := SaveManager._create_storage_save_data()

	SaveManager.silo_storage.stored_items.clear()
	runner.assert_eq(SaveManager.silo_storage.get_item_amount(wheat), 0, "Storage cleared before load")

	SaveManager._apply_storage_save_data(save_data)

	runner.assert_eq(SaveManager.silo_storage.get_item_amount(wheat), 250, "Storage wheat restored")
