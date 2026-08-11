extends Resource
class_name MarketEventData

enum EventCategory {
	MARKET,
	WEATHER,
	SEASONAL
}

enum TriggerMode {
	RANDOM,
	CONDITION_BASED,
	FIXED_DATE
}

@export_group("Basic Information")
@export var event_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var duration_days: int = 1
@export_range(0.0, 1.0, 0.01) var trigger_chance: float = 0.15
@export_range(0, 30, 1) var cooldown_days: int = 0
@export var event_category: EventCategory = EventCategory.MARKET
@export var trigger_mode: TriggerMode = TriggerMode.RANDOM
@export var once_per_season: bool = false
@export var once_per_year: bool = false

@export_group("Affected Products")
@export var target_item: ItemData
@export var affected_items: Array[ItemData] = []

@export_group("Commodity Market Effects")
@export var trend_effect: CommodityData.MarketTrend = CommodityData.MarketTrend.NEUTRAL
@export var trend_strength_modifier: float = 0.0
@export var volatility_modifier: float = 0.0

@export_group("Buy Price Effects")
@export var affects_buy_prices: bool = false
@export var affected_buy_price_items: Array[ItemData] = []
@export var buy_price_multiplier: float = 1.0

@export_group("Sales Requirements")
@export var requires_recent_sales: bool = false
@export var recent_sales_threshold: int = 0
@export var recent_sales_days: int = 7

@export_group("Season Requirements")
@export var requires_season: bool = false
@export var required_seasons: Array[SeasonData.Season] = []

@export_group("Season Day Range Requirements")
@export var requires_day_range: bool = false
@export_range(1, 30, 1) var start_day: int = 1
@export_range(1, 30, 1) var end_day: int = 30

@export_group("Weather History Requirements")
@export var requires_weather_history: bool = false
@export var required_dry_days: int = 0
@export var required_rain_days: int = 0

@export_group("Temperature Requirements")
@export var requires_temperature: bool = false
@export var minimum_temperature: float = -100.0
@export var maximum_temperature: float = 100.0


func get_affected_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	var seen_ids := {}
	var source_items := affected_items

	if source_items.is_empty() and target_item != null:
		source_items = [target_item]

	for item in source_items:
		if item == null:
			continue

		if seen_ids.has(item.id):
			continue

		seen_ids[item.id] = true
		result.append(item)

	return result


func get_affected_buy_price_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	var seen_ids := {}

	for item in affected_buy_price_items:
		if item == null:
			continue

		if seen_ids.has(item.id):
			continue

		seen_ids[item.id] = true
		result.append(item)

	return result
