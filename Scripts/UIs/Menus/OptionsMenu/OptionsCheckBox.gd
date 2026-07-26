class_name OptionsCheckBox

extends Button

@export var normal_color: Color = Color.BLACK
@export var hover_color: Color = Color.WHITE
@export var checked_fill_color: Color = Color(0.96, 0.78, 0.48, 0.28)
@export var line_width: float = 3.0

var _is_hovered: bool = false


func _ready() -> void:
	toggle_mode = true
	flat = true
	text = ""
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	toggled.connect(_on_toggled)


func _draw() -> void:
	var draw_color: Color = hover_color if _is_hovered else normal_color
	var box_size: float = minf(size.x, size.y)
	var origin: Vector2 = Vector2((size.x - box_size) * 0.5, (size.y - box_size) * 0.5)
	var box_rect: Rect2 = Rect2(origin + Vector2(line_width * 0.5, line_width * 0.5), Vector2(box_size, box_size) - Vector2(line_width, line_width))

	if button_pressed:
		draw_rect(box_rect, checked_fill_color, true)

	draw_rect(box_rect, draw_color, false, line_width)

	if button_pressed:
		var p1: Vector2 = origin + Vector2(box_size * 0.24, box_size * 0.52)
		var p2: Vector2 = origin + Vector2(box_size * 0.43, box_size * 0.70)
		var p3: Vector2 = origin + Vector2(box_size * 0.78, box_size * 0.30)
		draw_line(p1, p2, draw_color, line_width)
		draw_line(p2, p3, draw_color, line_width)


func _on_mouse_entered() -> void:
	_is_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_is_hovered = false
	queue_redraw()


func _on_toggled(_is_pressed: bool) -> void:
	queue_redraw()
