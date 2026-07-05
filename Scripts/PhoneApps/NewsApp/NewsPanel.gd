extends Control
class_name NewsPanel

@export var row_scene: PackedScene

const DEFAULT_ROW_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/NewsApp/news_item_row.tscn")

@onready var news_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/NewsScroll/NewsContainer

func _ready() -> void:
	visible = false
	add_to_group("news_panel")

	if not NewsManager.news_added.is_connected(_on_news_added):
		NewsManager.news_added.connect(_on_news_added)

	if not NewsManager.news_cleared.is_connected(_on_news_cleared):
		NewsManager.news_cleared.connect(_on_news_cleared)

	refresh()

func _on_news_added(_news_item: NewsItem) -> void:
	refresh()

func _on_news_cleared() -> void:
	refresh()

func refresh() -> void:
	var resolved_row_scene := row_scene

	if resolved_row_scene == null:
		resolved_row_scene = DEFAULT_ROW_SCENE

	NewsManager.sync_active_market_event_news()

	for child in news_container.get_children():
		news_container.remove_child(child)
		child.free()

	var news_items := _get_news_items_to_display()

	for news_item in news_items:
		var row := resolved_row_scene.instantiate() as NewsItemRow

		if row == null:
			push_warning("NewsPanel: failed to instantiate NewsItemRow")
			continue

		news_container.add_child(row)
		row.setup(news_item)

func _get_news_items_to_display() -> Array[NewsItem]:
	var news_items := NewsManager.get_latest_news()

	if not news_items.is_empty():
		return news_items

	var active_event_news: Array[NewsItem] = []

	for active_event in EventManager.get_active_market_events():
		if active_event == null or active_event.event_data == null:
			continue

		var event_data := active_event.event_data
		var news := NewsItem.new()
		news.title = event_data.display_name
		news.body = event_data.description
		news.day = TimeManager.current_day
		news.month = TimeManager.current_month
		news.year = TimeManager.current_year
		news.category = "Market"

		active_event_news.append(news)

	return active_event_news
