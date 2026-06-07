extends Resource
class_name CommodityData

@export var item_data: ItemData

@export var base_price: float = 10.0

@export var min_price_multiplier: float = 0.5
@export var max_price_multiplier: float = 2.0

@export var volatility: float = 0.05

@export var current_price: float = 10.0

@export var price_history: Array[float] = []

enum MarketTrend {
	BEARISH,
	NEUTRAL,
	BULLISH
}

@export var trend: MarketTrend = MarketTrend.NEUTRAL
@export var trend_strength: float = 0.01
