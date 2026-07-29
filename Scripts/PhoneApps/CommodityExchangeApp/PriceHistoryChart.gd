extends Control
class_name PriceHistoryChart

const COLOR_POSITIVE := Color(0.34, 0.82, 0.48, 1.0)
const COLOR_NEGATIVE := Color(0.92, 0.3, 0.3, 1.0)
const COLOR_NEUTRAL := Color(0.55, 0.6, 0.64, 1.0)
const COLOR_GRID := Color(0.22, 0.25, 0.27, 0.55)
const COLOR_TEXT := Color(0.82, 0.85, 0.86, 1.0)

var commodity_data: CommodityData


func set_commodity(commodity: CommodityData) -> void:
	commodity_data = commodity
	queue_redraw()


func _draw() -> void:
	if commodity_data == null or commodity_data.price_history.is_empty():
		_draw_empty_state()
		return

	var prices := _recent_prices(commodity_data.price_history)

	if prices.is_empty():
		_draw_empty_state()
		return

	var chart_rect := Rect2(Vector2(0.0, 16.0), Vector2(size.x, maxf(size.y - 28.0, 24.0)))
	var min_price := _min_price(prices)
	var max_price := _max_price(prices)
	var price_range := maxf(max_price - min_price, 0.01)

	_draw_grid(chart_rect)
	_draw_bars(chart_rect, prices, min_price, price_range)
	_draw_range_labels(chart_rect, min_price, max_price)


func _recent_prices(history: Array[float]) -> Array[float]:
	var prices: Array[float] = []
	var start_index := maxi(0, history.size() - 24)

	for i in range(start_index, history.size()):
		prices.append(float(history[i]))

	return prices


func _draw_grid(chart_rect: Rect2) -> void:
	for step in range(0, 4):
		var y := chart_rect.position.y + chart_rect.size.y * (float(step) / 3.0)
		draw_line(Vector2(chart_rect.position.x, y), Vector2(chart_rect.end.x, y), COLOR_GRID, 1.0)


func _draw_bars(chart_rect: Rect2, prices: Array[float], min_price: float, price_range: float) -> void:
	var count := prices.size()
	var gap := 2.0
	var bar_width := maxf(3.0, (chart_rect.size.x - gap * float(count - 1)) / float(count))

	for i in range(count):
		var price := prices[i]
		var normalized := (price - min_price) / price_range
		var bar_height := maxf(6.0, chart_rect.size.y * normalized)
		var x := chart_rect.position.x + float(i) * (bar_width + gap)
		var y := chart_rect.end.y - bar_height
		var color := _bar_color(prices, i)
		var bar_rect := Rect2(Vector2(x, y), Vector2(bar_width, bar_height))

		draw_rect(bar_rect, color)


func _draw_range_labels(chart_rect: Rect2, min_price: float, max_price: float) -> void:
	var font := get_theme_default_font()
	var font_size := 10

	if font == null:
		return

	draw_string(font, Vector2(0.0, 10.0), UIFormatHelper.money_float(max_price), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, COLOR_TEXT)
	draw_string(font, Vector2(0.0, size.y - 2.0), UIFormatHelper.money_float(min_price), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, COLOR_TEXT)


func _draw_empty_state() -> void:
	var font := get_theme_default_font()

	if font == null:
		return

	draw_string(font, Vector2(0.0, size.y * 0.5), "No price history", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, COLOR_TEXT)


func _bar_color(prices: Array[float], index: int) -> Color:
	if index == 0:
		return COLOR_NEUTRAL

	var delta := prices[index] - prices[index - 1]

	if delta > 0.005:
		return COLOR_POSITIVE

	if delta < -0.005:
		return COLOR_NEGATIVE

	return COLOR_NEUTRAL


func _min_price(prices: Array[float]) -> float:
	var value := INF

	for price in prices:
		value = minf(value, price)

	return value


func _max_price(prices: Array[float]) -> float:
	var value := -INF

	for price in prices:
		value = maxf(value, price)

	return value
