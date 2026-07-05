extends VBoxContainer
class_name NewsItemRow

const TITLE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DATE_COLOR := Color(0.78, 0.82, 0.86, 1.0)
const BODY_COLOR := Color(0.92, 0.94, 0.96, 1.0)

@onready var title_label: Label = $TitleLabel
@onready var date_label: Label = $DateLabel
@onready var body_label: Label = $BodyLabel

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 78.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_setup_label(title_label, TITLE_COLOR, 16)
	_setup_label(date_label, DATE_COLOR, 11)
	_setup_label(body_label, BODY_COLOR, 13)

func setup(news_item: NewsItem) -> void:
	if news_item == null:
		return

	if not is_node_ready():
		await ready

	title_label.text = news_item.title
	date_label.text = "Day %d, Month %d, Year %d | %s" % [
		news_item.day,
		news_item.month,
		news_item.year,
		news_item.category
	]
	body_label.text = news_item.body

func _setup_label(label: Label, color: Color, font_size: int) -> void:
	label.visible = true
	label.modulate = Color.WHITE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
