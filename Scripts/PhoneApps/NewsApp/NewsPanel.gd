extends Control
class_name NewsPanel

@export var row_scene: PackedScene

@onready var news_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/NewsContainer

func _ready() -> void:
	visible = false

	if not NewsManager.news_added.is_connected(_on_news_added):
		NewsManager.news_added.connect(_on_news_added)

	refresh()

func _on_news_added(_news_item: NewsItem) -> void:
	refresh()

func refresh() -> void:
	if row_scene == null:
		return

	for child in news_container.get_children():
		child.queue_free()

	var news_items := NewsManager.get_latest_news()

	for news_item in news_items:
		var row := row_scene.instantiate() as NewsItemRow

		if row == null:
			continue

		news_container.add_child(row)
		row.setup(news_item)
