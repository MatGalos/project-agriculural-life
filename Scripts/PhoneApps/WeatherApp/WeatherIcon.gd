extends Control
class_name WeatherIcon

@export var weather_name := "Unknown":
	set(value):
		weather_name = UIFormatHelper.display_weather_name(value)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(42.0, 42.0)


func setup(value: Variant) -> void:
	weather_name = UIFormatHelper.display_weather_name(value)
	queue_redraw()


func _draw() -> void:
	var icon_size := minf(size.x, size.y)
	var center := size * 0.5
	var key := weather_name.to_lower()

	match key:
		"sunny":
			_draw_sun(center, icon_size)
		"cloudy":
			_draw_cloud(center, icon_size, Color(0.76, 0.80, 0.86, 1.0))
		"rainy":
			_draw_cloud(center + Vector2(0.0, -3.0), icon_size, Color(0.62, 0.70, 0.80, 1.0))
			_draw_rain(center, icon_size)
		"stormy":
			_draw_cloud(center + Vector2(0.0, -4.0), icon_size, Color(0.50, 0.55, 0.65, 1.0))
			_draw_lightning(center, icon_size)
		"mixed":
			_draw_sun(center + Vector2(-8.0, -8.0), icon_size * 0.72)
			_draw_cloud(center + Vector2(4.0, 4.0), icon_size, Color(0.72, 0.78, 0.84, 1.0))
		"snowy":
			_draw_cloud(center + Vector2(0.0, -3.0), icon_size, Color(0.76, 0.82, 0.90, 1.0))
			_draw_snow(center, icon_size)
		"foggy":
			_draw_cloud(center + Vector2(0.0, -7.0), icon_size, Color(0.70, 0.75, 0.78, 1.0))
			_draw_fog(center, icon_size)
		_:
			_draw_cloud(center, icon_size, Color(0.62, 0.66, 0.72, 1.0))


func _draw_sun(center: Vector2, icon_size: float) -> void:
	var radius := icon_size * 0.22
	var ray_radius := icon_size * 0.36
	var color := Color(1.0, 0.78, 0.28, 1.0)

	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var from := center + Vector2(cos(angle), sin(angle)) * (radius + 3.0)
		var to := center + Vector2(cos(angle), sin(angle)) * ray_radius
		draw_line(from, to, color, 2.0, true)

	draw_circle(center, radius, color)


func _draw_cloud(center: Vector2, icon_size: float, color: Color) -> void:
	var base_y := center.y + icon_size * 0.12
	draw_circle(Vector2(center.x - icon_size * 0.16, base_y), icon_size * 0.18, color)
	draw_circle(Vector2(center.x + icon_size * 0.02, base_y - icon_size * 0.10), icon_size * 0.24, color)
	draw_circle(Vector2(center.x + icon_size * 0.22, base_y), icon_size * 0.18, color)
	draw_rect(
		Rect2(
			Vector2(center.x - icon_size * 0.32, base_y - icon_size * 0.02),
			Vector2(icon_size * 0.64, icon_size * 0.20)
		),
		color,
		true
	)


func _draw_rain(center: Vector2, icon_size: float) -> void:
	var color := Color(0.33, 0.62, 1.0, 1.0)
	var start_y := center.y + icon_size * 0.22

	for x_offset in [-10.0, 0.0, 10.0]:
		draw_line(
			Vector2(center.x + x_offset, start_y),
			Vector2(center.x + x_offset - 4.0, start_y + icon_size * 0.18),
			color,
			2.0,
			true
		)


func _draw_lightning(center: Vector2, icon_size: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-3.0, icon_size * 0.08),
		center + Vector2(-11.0, icon_size * 0.34),
		center + Vector2(1.0, icon_size * 0.27),
		center + Vector2(-5.0, icon_size * 0.52),
		center + Vector2(13.0, icon_size * 0.18),
		center + Vector2(2.0, icon_size * 0.24)
	])
	draw_colored_polygon(points, Color(1.0, 0.82, 0.28, 1.0))


func _draw_snow(center: Vector2, icon_size: float) -> void:
	var color := Color(0.86, 0.94, 1.0, 1.0)
	var start_y := center.y + icon_size * 0.25

	for x_offset in [-10.0, 2.0, 14.0]:
		var dot := Vector2(center.x + x_offset, start_y + absf(x_offset) * 0.35)
		draw_circle(dot, 2.3, color)


func _draw_fog(center: Vector2, icon_size: float) -> void:
	var color := Color(0.70, 0.76, 0.80, 0.9)
	var start_y := center.y + icon_size * 0.16

	for i in range(3):
		var y := start_y + float(i) * 8.0
		draw_line(
			Vector2(center.x - icon_size * 0.32, y),
			Vector2(center.x + icon_size * 0.32, y),
			color,
			2.0,
			true
		)
