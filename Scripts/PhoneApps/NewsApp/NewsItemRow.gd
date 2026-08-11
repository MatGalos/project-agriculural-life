extends PanelContainer
class_name NewsItemRow

const TITLE_COLOR := Color(0.97, 0.98, 1.0, 1.0)
const META_COLOR := Color(0.68, 0.74, 0.82, 1.0)
const BODY_COLOR := Color(0.86, 0.89, 0.94, 1.0)
const CARD_BG := Color(0.045, 0.052, 0.064, 0.96)

@onready var category_icon: Label = $CardMargin/CardRow/CategoryIcon
@onready var title_label: Label = $CardMargin/CardRow/TextStack/TitleLabel
@onready var date_label: Label = $CardMargin/CardRow/TextStack/MetaRow/DateLabel
@onready var category_label: Label = $CardMargin/CardRow/TextStack/MetaRow/CategoryLabel
@onready var body_label: Label = $CardMargin/CardRow/TextStack/BodyLabel


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 150.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_setup_label(category_icon, Color(0.96, 0.98, 1.0, 1.0), 18, true)
	_setup_label(title_label, TITLE_COLOR, 15, true)
	_setup_label(date_label, META_COLOR, 11)
	_setup_label(category_label, META_COLOR, 11, true)
	_setup_label(body_label, BODY_COLOR, 12)
	title_label.max_lines_visible = 2
	date_label.max_lines_visible = 2
	body_label.max_lines_visible = 4


func setup(news_item: NewsItem) -> void:
	if news_item == null:
		return

	if not is_node_ready():
		await ready

	var category := _get_display_category(news_item.category)
	title_label.text = _clean_text(news_item.title, "Untitled")
	date_label.text = UIFormatHelper.season_date(
		SaveManager.get_season_name_from_month(news_item.month),
		news_item.day,
		news_item.year
	)
	category_label.text = category
	category_icon.text = _get_category_icon(category)
	body_label.text = _clean_text(news_item.body, "No details available.")
	add_theme_stylebox_override("panel", _make_card_style(_get_category_color(category)))


func _get_display_category(category: String) -> String:
	var display := UIFormatHelper.display_news_category(category)

	if display == "Unknown" or display.is_empty():
		return "General"

	return display


func _get_category_icon(category: String) -> String:
	match category:
		"Market":
			return "$"
		"Weather":
			return "~"
		"Seasonal":
			return "#"
		"System":
			return "i"
		_:
			return "!"


func _get_category_color(category: String) -> Color:
	match category:
		"Market":
			return Color(0.18, 0.32, 0.40, 1.0)
		"Weather":
			return Color(0.16, 0.28, 0.44, 1.0)
		"Seasonal":
			return Color(0.24, 0.34, 0.22, 1.0)
		"System":
			return Color(0.26, 0.27, 0.31, 1.0)
		_:
			return Color(0.22, 0.24, 0.28, 1.0)


func _make_card_style(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.border_color = accent_color
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(7)
	return style


func _clean_text(value: String, fallback: String) -> String:
	var text := value.strip_edges()

	if text.is_empty():
		return fallback

	return text


func _setup_label(label: Label, color: Color, font_size: int, bold := false) -> void:
	label.visible = true
	label.modulate = Color.WHITE
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if bold:
		label.theme_type_variation = &"HeaderLabel"
