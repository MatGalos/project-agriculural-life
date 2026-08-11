class_name WoodenMenuPanel

extends Control

@export var plank_count := 6
@export var base_color := Color(0.64, 0.38, 0.17, 1.0)
@export var grain_color := Color(0.30, 0.16, 0.07, 0.30)
@export var border_color := Color(0.24, 0.12, 0.045, 1.0)
@export var highlight_color := Color(0.90, 0.62, 0.28, 0.22)
@export var border_width := 8.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var panel_rect: Rect2 = Rect2(Vector2.ZERO, size)
	var safe_plank_count: int = maxi(1, plank_count)
	var plank_height: float = size.y / float(safe_plank_count)

	draw_rect(panel_rect, Color(0.10, 0.055, 0.025, 0.35), true)

	for i in range(safe_plank_count):
		var y: float = float(i) * plank_height
		var plank_rect: Rect2 = Rect2(0.0, y, size.x, plank_height + 1.0)
		draw_rect(plank_rect, base_color, true)

		var grain_y: float = y + plank_height * 0.34
		draw_line(Vector2(border_width, grain_y), Vector2(size.x - border_width, grain_y + sin(float(i)) * 3.0), grain_color, 2.0)
		draw_line(Vector2(border_width, y + plank_height * 0.68), Vector2(size.x - border_width, y + plank_height * 0.68 + cos(float(i)) * 2.0), grain_color, 1.0)

	draw_rect(Rect2(Vector2(border_width, border_width), size - Vector2(border_width * 2.0, border_width * 2.0)), highlight_color, false, 2.0)
	draw_rect(panel_rect, border_color, false, border_width)
