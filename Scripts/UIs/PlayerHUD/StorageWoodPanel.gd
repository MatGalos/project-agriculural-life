class_name StorageWoodPanel

extends PanelContainer

@export var plank_count: int = 5
@export var base_color: Color = Color(0.60, 0.35, 0.15, 0.97)
@export var grain_color: Color = Color(0.27, 0.13, 0.055, 0.28)
@export var border_color: Color = Color(0.16, 0.075, 0.03, 1.0)
@export var highlight_color: Color = Color(0.90, 0.62, 0.30, 0.16)


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var safe_plank_count: int = maxi(1, plank_count)
	var plank_height: float = size.y / float(safe_plank_count)

	draw_rect(Rect2(Vector2(0.0, 5.0), size), Color(0.05, 0.025, 0.01, 0.32), true)
	draw_rect(rect, border_color, true)

	for i in range(safe_plank_count):
		var y: float = 5.0 + float(i) * plank_height
		var plank_rect: Rect2 = Rect2(5.0, y, maxf(size.x - 10.0, 0.0), maxf(plank_height - 1.0, 0.0))
		draw_rect(plank_rect, base_color, true)
		draw_line(Vector2(14.0, y + plank_height * 0.38), Vector2(size.x - 14.0, y + plank_height * 0.38 + sin(float(i)) * 2.0), grain_color, 1.0)
		draw_line(Vector2(14.0, y + plank_height * 0.70), Vector2(size.x - 14.0, y + plank_height * 0.70 + cos(float(i)) * 2.0), grain_color, 1.0)

	draw_rect(rect.grow(-8.0), highlight_color, false, 2.0)
	draw_rect(rect, border_color, false, 5.0)
