class_name OptionsScrollLine

extends Control

@export var scroll_container_path: NodePath
@export var line_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var line_width: float = 3.0
@export var min_line_height: float = 28.0

var _scroll_container: ScrollContainer
var _scroll_bar: VScrollBar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll_container = get_node_or_null(scroll_container_path) as ScrollContainer

	if _scroll_container == null:
		visible = false
		return

	_scroll_bar = _scroll_container.get_v_scroll_bar()
	_scroll_bar.value_changed.connect(_on_scroll_changed)
	_scroll_bar.changed.connect(queue_redraw)
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if _scroll_bar == null:
		return

	var max_value: float = _scroll_bar.max_value
	var page: float = _scroll_bar.page

	if max_value <= page:
		return

	var available_height: float = size.y
	var line_height: float = maxf(min_line_height, available_height * page / max_value)
	var max_scroll: float = maxf(1.0, max_value - page)
	var scroll_ratio: float = clampf(_scroll_bar.value / max_scroll, 0.0, 1.0)
	var y: float = (available_height - line_height) * scroll_ratio
	var x: float = size.x - line_width * 0.5

	draw_line(Vector2(x, y), Vector2(x, y + line_height), line_color, line_width)


func _on_scroll_changed(_value: float) -> void:
	queue_redraw()
