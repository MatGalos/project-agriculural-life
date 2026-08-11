extends RefCounted

var runner: TestRunner
var wheat: ItemData = preload("res://Data/Items/Crops/wheat_item.tres")


func run() -> void:
	print("\n--- SalesStatsSaveTest ---")

	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()

	SalesStatsManager.record_sale(wheat, 300)
	SalesStatsManager._on_day_changed()
	SalesStatsManager.record_sale(wheat, 200)

	var save_data := SalesStatsManager.create_save_data()

	SalesStatsManager.current_day_sales.clear()
	SalesStatsManager.sales_history.clear()

	SalesStatsManager.apply_save_data(save_data)

	runner.assert_eq(
		int(SalesStatsManager.current_day_sales.get(wheat.id, 0)),
		200,
		"SalesStats current day restored"
	)

	runner.assert_eq(
		SalesStatsManager.get_recent_sales_amount(wheat.id, 7),
		500,
		"SalesStats total restored"
	)
