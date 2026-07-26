class_name HotbarToolBeltSlot

extends PanelContainer

@export var inactive_color: Color = Color(0.24, 0.11, 0.045, 0.96)
@export var active_color: Color = Color(0.54, 0.29, 0.12, 0.98)
@export var border_color: Color = Color(0.10, 0.045, 0.02, 1.0)
@export var stitch_color: Color = Color(0.78, 0.55, 0.30, 0.58)
@export var rivet_color: Color = Color(0.62, 0.54, 0.44, 0.95)

var _is_active: bool = false


func _ready() -> void:
	resized.connect(queue_redraw)


func set_active_state(is_active: bool) -> void:
	if _is_active == is_active:
		return

	_is_active = is_active
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var base_color: Color = active_color if _is_active else inactive_color
	var pocket_rect: Rect2 = Rect2(Vector2(3.0, 4.0), size - Vector2(6.0, 7.0))
	var lip_y: float = 16.0
	var bottom_y: float = size.y - 7.0
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(5.0, 6.0),
		Vector2(size.x - 5.0, 6.0),
		Vector2(size.x - 8.0, bottom_y),
		Vector2(8.0, bottom_y)
	])

	if _is_active:
		draw_rect(Rect2(Vector2(0.0, 1.0), size - Vector2(0.0, 1.0)), Color(0.95, 0.66, 0.32, 0.22), true)

	draw_rect(Rect2(Vector2(3.0, 7.0), size - Vector2(6.0, 5.0)), Color(0.035, 0.018, 0.01, 0.34), true)
	draw_colored_polygon(points, base_color)
	draw_line(Vector2(8.0, lip_y), Vector2(size.x - 8.0, lip_y), Color(0.12, 0.055, 0.025, 0.72), 2.0)
	draw_line(Vector2(9.0, lip_y + 5.0), Vector2(size.x - 9.0, lip_y + 5.0), stitch_color, 1.0)
	draw_line(Vector2(10.0, bottom_y - 7.0), Vector2(size.x - 10.0, bottom_y - 7.0), stitch_color, 1.0)
	draw_circle(Vector2(12.0, 13.0), 2.6, rivet_color)
	draw_circle(Vector2(size.x - 12.0, 13.0), 2.6, rivet_color)
	draw_line(points[0], points[1], border_color, 2.0)
	draw_line(points[1], points[2], border_color, 2.0)
	draw_line(points[2], points[3], border_color, 2.0)
	draw_line(points[3], points[0], border_color, 2.0)

	if _is_active:
		draw_rect(pocket_rect.grow(-1.0), Color(1.0, 0.72, 0.34, 0.22), false, 2.0)
