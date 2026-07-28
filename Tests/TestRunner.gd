extends Node
class_name TestRunner

var passed := 0
var failed := 0


func run_all_tests() -> void:
	passed = 0
	failed = 0

	print("\n========== RUNNING TESTS ==========")

	_run_test_script(preload("res://Tests/Core/UIFormatHelperTest.gd").new())
	_run_test_script(preload("res://Tests/Core/FarmPhoneLayoutTest.gd").new())
	_run_test_script(preload("res://Tests/Core/MoneyManagerTest.gd").new())
	_run_test_script(preload("res://Tests/Core/StorageDataTest.gd").new())
	_run_test_script(preload("res://Tests/Core/HotbarDataTest.gd").new())
	_run_test_script(preload("res://Tests/Core/SalesStatsManagerTest.gd").new())
	_run_test_script(preload("res://Tests/Core/InventoryDataTest.gd").new())
	_run_test_script(preload("res://Tests/Core/WeatherManagerTest.gd").new())
	_run_test_script(preload("res://Tests/Core/EventSystemTest.gd").new())
	_run_test_script(preload("res://Tests/Save/SaveStructureTest.gd").new())
	_run_test_script(preload("res://Tests/Save/SaveSlotTest.gd").new())
	_run_test_script(preload("res://Tests/Save/SalesStatsSaveTest.gd").new())
	_run_test_script(preload("res://Tests/Save/InventorySaveTest.gd").new())
	_run_test_script(preload("res://Tests/Save/StorageSaveTest.gd").new())
	_run_test_script(preload("res://Tests/Save/WeatherSaveTest.gd").new())
	_run_test_script(preload("res://Tests/Save/NewsSaveTest.gd").new())
	_run_test_script(preload("res://Tests/Save/MarketSaveTest.gd").new())
	_run_test_script(preload("res://Tests/Save/EventSaveTest.gd").new())
	_run_test_script(preload("res://Tests/Save/CropProductIntegrationTest.gd").new())
	_run_test_script(preload("res://Tests/Save/FarmTileLogicTest.gd").new())
	_run_test_script(preload("res://Tests/Save/TileCropSaveTest.gd").new())
	_run_test_script(preload("res://Tests/Simulation/FullYearSimulationTest.gd").new())
	_run_test_script(preload("res://Tests/Simulation/OversupplySalesSimulationTest.gd").new())
	_run_test_script(preload("res://Tests/Simulation/CropProfitabilityAnalysisTest.gd").new())

	print("========== TEST RESULTS ==========")
	print("Passed: ", passed)
	print("Failed: ", failed)
	print("==================================\n")


func _run_test_script(test_script: Object) -> void:
	if test_script == null:
		return

	test_script.runner = self
	test_script.run()


func assert_true(value: bool, message: String) -> void:
	if value:
		passed += 1
		print("✅ ", message)
	else:
		failed += 1
		push_error("❌ " + message)


func assert_eq(actual, expected, message: String) -> void:
	if actual == expected:
		passed += 1
		print("✅ ", message)
	else:
		failed += 1
		push_error("❌ %s | expected=%s actual=%s" % [message, str(expected), str(actual)])
