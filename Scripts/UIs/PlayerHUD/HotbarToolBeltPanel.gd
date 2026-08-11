class_name HotbarToolBeltPanel

extends PanelContainer

@export var leather_color: Color = Color(0.30, 0.15, 0.065, 0.94)
@export var leather_dark_color: Color = Color(0.13, 0.065, 0.03, 0.95)
@export var stitch_color: Color = Color(0.78, 0.55, 0.30, 0.70)
@export var rivet_color: Color = Color(0.58, 0.50, 0.40, 0.95)


func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var panel_rect: Rect2 = Rect2(Vector2.ZERO, size)
	var shadow_rect: Rect2 = Rect2(Vector2(0.0, 4.0), size)
	var inner_rect: Rect2 = panel_rect.grow(-4.0)
	var stitch_y_top: float = 9.0
	var stitch_y_bottom: float = size.y - 9.0

	draw_rect(shadow_rect, Color(0.04, 0.02, 0.01, 0.36), true)
	draw_rect(panel_rect, leather_dark_color, true)
	draw_rect(inner_rect, leather_color, true)
	draw_line(Vector2(8.0, stitch_y_top), Vector2(size.x - 8.0, stitch_y_top), stitch_color, 1.0)
	draw_line(Vector2(8.0, stitch_y_bottom), Vector2(size.x - 8.0, stitch_y_bottom), stitch_color, 1.0)

	var stitch_step: float = 18.0
	var stitch_x: float = 14.0
	while stitch_x < size.x - 14.0:
		draw_line(Vector2(stitch_x, stitch_y_top - 2.0), Vector2(stitch_x + 5.0, stitch_y_top + 2.0), stitch_color, 1.0)
		draw_line(Vector2(stitch_x, stitch_y_bottom - 2.0), Vector2(stitch_x + 5.0, stitch_y_bottom + 2.0), stitch_color, 1.0)
		stitch_x += stitch_step

	draw_circle(Vector2(14.0, size.y * 0.5), 3.0, rivet_color)
	draw_circle(Vector2(size.x - 14.0, size.y * 0.5), 3.0, rivet_color)
	draw_rect(panel_rect, leather_dark_color, false, 2.0)
