extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- SaveSlotTest ---")

	SaveManager.set_current_save_slot(1)
	runner.assert_eq(SaveManager.current_save_slot, 1, "Save slot 1 selected")

	SaveManager.set_current_save_slot(2)
	runner.assert_eq(SaveManager.current_save_slot, 2, "Save slot 2 selected")

	SaveManager.set_current_save_slot(3)
	runner.assert_eq(SaveManager.current_save_slot, 3, "Save slot 3 selected")

	SaveManager.set_current_save_slot(999)
	runner.assert_eq(SaveManager.current_save_slot, 3, "Invalid high slot clamps to 3")

	SaveManager.set_current_save_slot(-5)
	runner.assert_eq(SaveManager.current_save_slot, 1, "Invalid low slot clamps to 1")

	runner.assert_eq(SaveManager.get_save_path(1), "user://save_slot_1.json", "Slot 1 path")
	runner.assert_eq(SaveManager.get_save_path(2), "user://save_slot_2.json", "Slot 2 path")
	runner.assert_eq(SaveManager.get_save_path(3), "user://save_slot_3.json", "Slot 3 path")
