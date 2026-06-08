extends VBoxContainer
class_name NewsItemRow

@onready var title_label: Label = $TitleLabel
@onready var date_label: Label = $DateLabel
@onready var body_label: Label = $BodyLabel

func setup(news_item: NewsItem) -> void:
	if news_item == null:
		return

	title_label.text = news_item.title
	date_label.text = "Day %d, Month %d, Year %d | %s" % [
		news_item.day,
		news_item.month,
		news_item.year,
		news_item.category
	]
	body_label.text = news_item.body
