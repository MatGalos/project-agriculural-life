extends Resource
class_name ActiveMarketEvent

var event_data: MarketEventData
var remaining_days: int = 0

func setup(data: MarketEventData) -> void:
	event_data = data

	if event_data:
		remaining_days = event_data.duration_days
