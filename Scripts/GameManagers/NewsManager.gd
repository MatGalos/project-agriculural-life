extends Node

signal news_added(news_item: NewsItem)

var news_items: Array[NewsItem] = []

func _ready() -> void:
	EventManager.market_event_started.connect(_on_market_event_started)

func _on_market_event_started(event_data: MarketEventData) -> void:
	if event_data == null:
		return

	var news := NewsItem.new()
	news.title = event_data.display_name
	news.body = event_data.description
	news.day = TimeManager.current_day
	news.month = TimeManager.current_month
	news.year = TimeManager.current_year
	news.category = "Market"

	add_news(news)

func add_news(news_item: NewsItem) -> void:
	if news_item == null:
		return

	news_items.insert(0, news_item)
	news_added.emit(news_item)

func get_latest_news() -> Array[NewsItem]:
	return news_items
