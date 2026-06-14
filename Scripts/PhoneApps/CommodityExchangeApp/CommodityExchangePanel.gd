extends Control
class_name CommodityExchangePanel

@export var row_scene: PackedScene

@onready var status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var items_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ItemsContainer
@onready var history_title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HistoryTitleLabel
@onready var history_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HistoryLabel

var selected_commodity: CommodityData = null

func _ready() -> void:
	visible = false

	if not CommodityMarketManager.commodity_prices_updated.is_connected(refresh):
		CommodityMarketManager.commodity_prices_updated.connect(refresh)

	refresh()

func refresh() -> void:
	_update_status()

	if row_scene == null:
		return

	for child in items_container.get_children():
		child.queue_free()

	for commodity in CommodityMarketManager.commodities:
		var row := row_scene.instantiate() as CommodityItemRow

		if row == null:
			continue

		items_container.add_child(row)
		row.setup(commodity)
		row.selected.connect(_on_commodity_selected)

		if selected_commodity == null:
			selected_commodity = commodity

	if selected_commodity:
		_update_history(selected_commodity)
	else:
		_update_history(null)

func _update_status() -> void:
	var hour := TimeManager.get_hour()

	if hour >= 9 and hour <= 17:
		status_label.text = "Market: OPEN"
	else:
		status_label.text = "Market: CLOSED"

func _on_commodity_selected(commodity: CommodityData) -> void:
	selected_commodity = commodity
	_update_history(commodity)


func _update_history(commodity: CommodityData) -> void:
	if commodity == null:
		history_title_label.text = "Price History"
		history_label.text = "No data"
		return

	history_title_label.text = "%s Price History" % commodity.item_data.display_name

	if commodity.price_history.is_empty():
		history_label.text = "No data"
		return

	var lines: Array[String] = []
	var history := commodity.price_history

	var start_index := maxi(0, history.size() - 8)

	for i in range(start_index, history.size()):
		var label := "Entry %d" % (i + 1)

		if i < commodity.price_history_labels.size():
			label = commodity.price_history_labels[i]

		lines.append("%s - %.2f$" % [
			label,
			float(history[i])
		])

	history_label.text = "\n".join(lines)
