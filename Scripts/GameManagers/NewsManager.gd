extends Node

const MAX_NEWS_COUNT := 20

signal news_added(news_item: NewsItem)
signal news_cleared

var news_items: Array[NewsItem] = []
var _announced_market_event_ids: Dictionary = {}

func _ready() -> void:
	print("[NewsDebug][NewsManager] ready")

	if not EventManager.market_event_started.is_connected(_on_market_event_started):
		EventManager.market_event_started.connect(_on_market_event_started)

	if not EventManager.market_event_ended.is_connected(_on_market_event_ended):
		EventManager.market_event_ended.connect(_on_market_event_ended)

	if not EventManager.market_events_changed.is_connected(sync_active_market_event_news):
		EventManager.market_events_changed.connect(sync_active_market_event_news)

	sync_active_market_event_news.call_deferred()

func _on_market_event_started(event_data: MarketEventData) -> void:
	print("[NewsDebug][NewsManager] market_event_started signal received: ", _get_event_debug_name(event_data))
	add_market_event_news(event_data)

func _on_market_event_ended(event_data: MarketEventData) -> void:
	if event_data == null:
		return

	_announced_market_event_ids.erase(_get_market_event_key(event_data))

func sync_active_market_event_news() -> void:
	print(
		"[NewsDebug][NewsManager] sync active events count=",
		EventManager.get_active_market_events().size(),
		", current news count=",
		news_items.size()
	)

	for active_event in EventManager.get_active_market_events():
		if active_event == null:
			continue

		add_market_event_news(active_event.event_data)

func add_market_event_news(event_data: MarketEventData) -> void:
	if event_data == null:
		print("[NewsDebug][NewsManager] skipped null event")
		return

	var event_key := _get_market_event_key(event_data)

	print(
		"[NewsDebug][NewsManager] add_market_event_news key=",
		event_key,
		", title=",
		event_data.display_name,
		", already_announced=",
		_announced_market_event_ids.has(event_key)
	)

	if _announced_market_event_ids.has(event_key):
		return

	_announced_market_event_ids[event_key] = true

	var news := NewsItem.new()
	news.title = event_data.display_name
	news.body = event_data.description
	news.day = TimeManager.current_day
	news.month = TimeManager.current_month
	news.year = TimeManager.current_year
	news.category = "Market"

	add_news(news)

func _get_market_event_key(event_data: MarketEventData) -> String:
	if event_data.event_id != "":
		return event_data.event_id

	return event_data.display_name

func add_news(news_item: NewsItem) -> void:
	if news_item == null:
		print("[NewsDebug][NewsManager] add_news skipped null")
		return

	news_items.insert(0, news_item)

	if news_items.size() > MAX_NEWS_COUNT:
		news_items.resize(MAX_NEWS_COUNT)

	print(
		"[NewsDebug][NewsManager] news added title=",
		news_item.title,
		", total=",
		news_items.size()
	)

	news_added.emit(news_item)

func clear_news() -> void:
	news_items.clear()
	_announced_market_event_ids.clear()

	print("[NewsDebug][NewsManager] news cleared")

	news_cleared.emit()

func replace_news_items(saved_news_items: Array[NewsItem]) -> void:
	news_items.clear()

	for news_item in saved_news_items:
		if news_item == null:
			continue

		news_items.append(news_item)

	if news_items.size() > MAX_NEWS_COUNT:
		news_items.resize(MAX_NEWS_COUNT)

	rebuild_announced_event_ids_from_active_events()
	print("[NewsDebug][NewsManager] news replaced from save total=", news_items.size())

func get_latest_news() -> Array[NewsItem]:
	return news_items

func _get_event_debug_name(event_data: MarketEventData) -> String:
	if event_data == null:
		return "<null>"

	return "%s (%s)" % [event_data.display_name, event_data.event_id]

func rebuild_announced_event_ids_from_active_events() -> void:
	_announced_market_event_ids.clear()

	for active_event in EventManager.get_active_market_events():
		if active_event == null or active_event.event_data == null:
			continue

		var event_key := _get_market_event_key(active_event.event_data)
		_announced_market_event_ids[event_key] = true
