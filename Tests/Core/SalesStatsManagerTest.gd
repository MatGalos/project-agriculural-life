extends RefCounted

var runner: TestRunner
var wheat: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")


func run() -> void:
	print("\n--- SalesStatsManagerTest ---")

	var previous_suppress_logs := SalesStatsManager.suppress_logs
	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()
	SalesStatsManager.suppress_logs = true

	SalesStatsManager.record_sale(wheat, 100)
	runner.assert_eq(
		SalesStatsManager.get_recent_sales_amount(wheat.id, 7),
		100,
		"SalesStats records current day sale"
	)

	SalesStatsManager._on_day_changed()
	runner.assert_eq(
		SalesStatsManager.get_recent_sales_amount(wheat.id, 7),
		100,
		"SalesStats keeps previous day sale in history"
	)

	SalesStatsManager.record_sale(wheat, 50)
	runner.assert_eq(
		SalesStatsManager.get_recent_sales_amount(wheat.id, 7),
		150,
		"SalesStats combines current day and history"
	)

	for i in range(10):
		SalesStatsManager._on_day_changed()

	runner.assert_true(
		SalesStatsManager.sales_history.size() <= SalesStatsManager.HISTORY_DAYS,
		"SalesStats history is limited"
	)

	_assert_sales_stats_logging_can_be_suppressed()
	SalesStatsManager.suppress_logs = previous_suppress_logs


func _assert_sales_stats_logging_can_be_suppressed() -> void:
	var source := _read_file("res://Scripts/GameManagers/SalesStatsManager.gd").replace("\r\n", "\n")
	runner.assert_true(
		source.contains("var suppress_logs := false"),
		"SalesStats exposes a suppress_logs flag for simulation tests"
	)
	runner.assert_true(
		source.contains("if not suppress_logs:\n\t\tprint(\"[SalesStats] Sold "),
		"SalesStats sale debug print is guarded by suppress_logs"
	)


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	var content := file.get_as_text()
	file.close()
	return content
