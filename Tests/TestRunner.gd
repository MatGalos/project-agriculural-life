extends Node
class_name TestRunner

var passed := 0
var failed := 0
var tests_run := 0
var tests_skipped := 0
var skipped_test_names: Array[String] = []


func should_run_heavy_simulation_tests() -> bool:
	var args: PackedStringArray = OS.get_cmdline_args()
	return args.has("--run-tests") or args.has("--run-heavy-simulations")


func should_print_passed_assertions() -> bool:
	return OS.get_cmdline_args().has("--verbose-tests")


func run_all_tests() -> void:
	passed = 0
	failed = 0
	tests_run = 0
	tests_skipped = 0
	skipped_test_names.clear()

	print("\n========== RUNNING TESTS ==========")

	_run_test_script(preload("res://Tests/Core/UIFormatHelperTest.gd").new())
	_run_test_script(preload("res://Tests/Core/FarmPhoneLayoutTest.gd").new())
	_run_test_script(preload("res://Tests/Core/MarketAppLayoutTest.gd").new())
	_run_test_script(preload("res://Tests/Core/ShopAppLayoutTest.gd").new())
	_run_test_script(preload("res://Tests/Core/SellAppLayoutTest.gd").new())
	_run_test_script(preload("res://Tests/Core/GameplayFeedbackTest.gd").new())
	_run_test_script(preload("res://Tests/Core/UIResponsivenessSourceTest.gd").new())
	_run_test_script(preload("res://Tests/Core/UIVisualPolishSourceTest.gd").new())
	_run_test_script(preload("res://Tests/Core/TestRunnerBehaviorTest.gd").new())
	_run_test_script(preload("res://Tests/Core/TimeManagerTest.gd").new())
	_run_test_script(preload("res://Tests/Core/WeatherAppLayoutTest.gd").new())
	_run_test_script(preload("res://Tests/Core/NewsAppLayoutTest.gd").new())
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

	if should_run_heavy_simulation_tests():
		_run_test_script(preload("res://Tests/Simulation/FullYearSimulationTest.gd").new())
		_run_test_script(preload("res://Tests/Simulation/OversupplySalesSimulationTest.gd").new())
		_run_test_script(preload("res://Tests/Simulation/CropProfitabilityAnalysisTest.gd").new())
	else:
		_skip_test("FullYearSimulationTest")
		_skip_test("OversupplySalesSimulationTest")
		_skip_test("CropProfitabilityAnalysisTest")

	print("========== TEST RESULTS ==========")
	print("Tests run: ", tests_run)
	print("Tests skipped: ", tests_skipped)
	if not skipped_test_names.is_empty():
		print("Skipped: ", ", ".join(skipped_test_names))
	print("Assertions passed: ", passed)
	print("Assertions failed: ", failed)
	print("==================================\n")


func _run_test_script(test_script: Object) -> void:
	if test_script == null:
		return

	var script: Script = test_script.get_script() as Script
	var test_name: String = "UnknownTest"
	if script != null:
		test_name = script.resource_path.get_file().get_basename()
	var passed_before := passed
	var failed_before := failed

	test_script.runner = self
	test_script.run()
	tests_run += 1

	var passed_delta := passed - passed_before
	var failed_delta := failed - failed_before
	var status: String = "PASS" if failed_delta == 0 else "FAIL"
	print("%s %s assertions=%d failed=%d" % [status, test_name, passed_delta + failed_delta, failed_delta])


func _skip_test(test_name: String) -> void:
	tests_skipped += 1
	skipped_test_names.append(test_name)
	print("SKIP %s heavy simulation. Run with --run-tests or launch with --run-heavy-simulations before F6." % test_name)


func assert_true(value: bool, message: String) -> void:
	if value:
		passed += 1
		if should_print_passed_assertions():
			print("PASS ", message)
	else:
		failed += 1
		push_error("FAIL " + message)


func assert_eq(actual, expected, message: String) -> void:
	if actual == expected:
		passed += 1
		if should_print_passed_assertions():
			print("PASS ", message)
	else:
		failed += 1
		push_error("FAIL %s | expected=%s actual=%s" % [message, str(expected), str(actual)])
