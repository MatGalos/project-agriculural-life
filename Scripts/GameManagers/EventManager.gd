extends Node

signal market_event_started(event_data: MarketEventData)
signal market_event_ended(event_data: MarketEventData)
signal market_events_changed

var possible_market_events: Array[MarketEventData] = [
	preload("res://Data/Events/wheat_demand_spike_event.tres"),
	preload("res://Data/Events/wheat_oversupply_event.tres"),
	preload("res://Data/Events/bad_harvest_event.tres")
]

var active_market_events: Array[ActiveMarketEvent] = []

func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)

func _on_day_changed() -> void:
	_process_active_events()
	_try_trigger_market_event()
	_apply_market_event_effects()

	market_events_changed.emit()

func _process_active_events() -> void:
	var ended_events: Array[ActiveMarketEvent] = []

	for active_event in active_market_events:
		active_event.remaining_days -= 1

		if active_event.remaining_days <= 0:
			ended_events.append(active_event)

	for ended_event in ended_events:
		active_market_events.erase(ended_event)
		market_event_ended.emit(ended_event.event_data)

func _try_trigger_market_event() -> void:
	for event_data in possible_market_events:
		if event_data == null:
			continue

		if _is_event_already_active(event_data):
			continue

		if randf() <= event_data.trigger_chance:
			var active_event := ActiveMarketEvent.new()
			active_event.setup(event_data)

			active_market_events.append(active_event)
			market_event_started.emit(event_data)
			print(
				"[NewsDebug][EventManager] emitted market_event_started for ",
				event_data.display_name,
				", NewsManager available=",
				NewsManager != null
			)
			NewsManager.add_market_event_news(event_data)

			print("Market event started: ", event_data.display_name)

func _is_event_already_active(event_data: MarketEventData) -> bool:
	for active_event in active_market_events:
		if active_event.event_data == event_data:
			return true

	return false

func _apply_market_event_effects() -> void:
	CommodityMarketManager.reset_event_modifiers()

	for active_event in active_market_events:
		var event_data := active_event.event_data

		if event_data == null:
			continue

		CommodityMarketManager.apply_event_modifier(event_data)

func get_active_market_events() -> Array[ActiveMarketEvent]:
	return active_market_events

func get_event_by_id(event_id: String) -> MarketEventData:
	for event_data in possible_market_events:
		if event_data != null and event_data.event_id == event_id:
			return event_data

	return null
