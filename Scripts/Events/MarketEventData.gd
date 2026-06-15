extends Resource
class_name MarketEventData

@export var event_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var duration_days: int = 1
@export_range(0.0, 1.0, 0.01) var trigger_chance: float = 0.15

@export var target_item: ItemData

@export var trend_effect: CommodityData.MarketTrend = CommodityData.MarketTrend.NEUTRAL
@export var trend_strength_modifier: float = 0.0
@export var volatility_modifier: float = 0.0
