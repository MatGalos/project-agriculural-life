extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- EventSaveTest ---")

	EventManager.active_market_events.clear()

	var event_data := EventManager.get_event_by_id("wheat_oversupply")
	if event_data == null:
		runner.assert_true(false, "Test event exists")
		return

	var active_event := ActiveMarketEvent.new()
	active_event.setup(event_data)
	active_event.remaining_days = 2

	EventManager.active_market_events.append(active_event)

	var save_data := SaveManager._create_events_save_data()

	EventManager.active_market_events.clear()
	runner.assert_eq(EventManager.active_market_events.size(), 0, "Events cleared before load")

	SaveManager._apply_events_save_data(save_data)

	runner.assert_eq(EventManager.active_market_events.size(), 1, "Event restored")
	runner.assert_eq(EventManager.active_market_events[0].event_data.event_id, "wheat_oversupply", "Event id restored")
	runner.assert_eq(EventManager.active_market_events[0].remaining_days, 2, "Event remaining days restored")
