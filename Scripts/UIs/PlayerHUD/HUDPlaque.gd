class_name HUDPlaque

extends ColorRect

enum PlaqueStyle {
	WOOD,
	PAPER
}

@export var plaque_style: PlaqueStyle = PlaqueStyle.WOOD
@export var border_width: float = 2.0


func _ready() -> void:
	color = Color(0.0, 0.0, 0.0, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	match plaque_style:
		PlaqueStyle.PAPER:
			_draw_paper_plaque()
		_:
			_draw_wood_plaque()


func _draw_wood_plaque() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var base_color: Color = Color(0.64, 0.38, 0.17, 0.92)
	var border_color: Color = Color(0.24, 0.12, 0.045, 0.95)
	var grain_color: Color = Color(0.30, 0.16, 0.07, 0.30)
	var highlight_color: Color = Color(0.90, 0.62, 0.28, 0.18)

	draw_rect(rect, base_color, true)
	draw_line(Vector2(border_width * 2.0, size.y * 0.34), Vector2(size.x - border_width * 2.0, size.y * 0.34 + 2.0), grain_color, 1.0)
	draw_line(Vector2(border_width * 2.0, size.y * 0.68), Vector2(size.x - border_width * 2.0, size.y * 0.68 - 1.0), grain_color, 1.0)
	draw_rect(Rect2(Vector2(border_width, border_width), size - Vector2(border_width * 2.0, border_width * 2.0)), highlight_color, false, 1.0)
	draw_rect(rect, border_color, false, border_width)


func _draw_paper_plaque() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var paper_color: Color = Color(0.92, 0.82, 0.62, 0.94)
	var border_color: Color = Color(0.45, 0.30, 0.14, 0.90)
	var line_color: Color = Color(0.58, 0.40, 0.20, 0.18)

	draw_rect(rect, Color(0.10, 0.055, 0.025, 0.25), true)
	draw_rect(Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0)), paper_color, true)
	draw_line(Vector2(8.0, size.y * 0.52), Vector2(size.x - 8.0, size.y * 0.52), line_color, 1.0)
	draw_rect(Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0)), border_color, false, border_width)
