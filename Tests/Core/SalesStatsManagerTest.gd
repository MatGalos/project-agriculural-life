extends RefCounted

var runner: TestRunner
var wheat: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")


func run() -> void:
	print("\n--- SalesStatsManagerTest ---")

	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()

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
