extends Node

signal sales_stats_changed

const HISTORY_DAYS := 7

var current_day_sales: Dictionary = {}
var sales_history: Array[Dictionary] = []


func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)


func record_sale(item_data: ItemData, amount: int) -> void:
	if item_data == null or amount <= 0:
		return

	var item_id := item_data.id

	current_day_sales[item_id] = int(current_day_sales.get(item_id, 0)) + amount

	print("[SalesStats] Sold ", amount, "x ", item_id, " today total=", current_day_sales[item_id])

	sales_stats_changed.emit()


func get_recent_sales_amount(item_id: String, days: int = HISTORY_DAYS) -> int:
	var total := int(current_day_sales.get(item_id, 0))

	var count := mini(days - 1, sales_history.size())

	for i in range(count):
		var index := sales_history.size() - 1 - i
		var day_data := sales_history[index]
		total += int(day_data.get(item_id, 0))

	return total


func _on_day_changed() -> void:
	sales_history.append(current_day_sales.duplicate(true))
	current_day_sales.clear()

	while sales_history.size() > HISTORY_DAYS:
		sales_history.pop_front()

	sales_stats_changed.emit()

func create_save_data() -> Dictionary:
	return {
		"current_day_sales": current_day_sales.duplicate(true),
		"sales_history": sales_history.duplicate(true)
	}


func apply_save_data(save_data: Dictionary) -> void:
	current_day_sales.clear()
	sales_history.clear()

	if save_data.has("current_day_sales") and save_data["current_day_sales"] is Dictionary:
		var saved_current := save_data["current_day_sales"] as Dictionary

		for item_id in saved_current.keys():
			current_day_sales[String(item_id)] = int(saved_current[item_id])

	if save_data.has("sales_history") and save_data["sales_history"] is Array:
		var saved_history := save_data["sales_history"] as Array

		for day_entry in saved_history:
			if not (day_entry is Dictionary):
				continue

			var clean_day := {}

			for item_id in day_entry.keys():
				clean_day[String(item_id)] = int(day_entry[item_id])

			sales_history.append(clean_day)

	while sales_history.size() > HISTORY_DAYS:
		sales_history.pop_front()

	sales_stats_changed.emit()
