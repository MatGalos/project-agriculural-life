extends RefCounted
class_name UIFormatHelper

static func money_int(amount: int) -> String:
	return "$%d" % amount


static func money_float(amount: float) -> String:
	return "$%.2f" % amount


static func money_each(amount: int) -> String:
	return "%s each" % money_int(amount)


static func percent(value: float) -> String:
	if absf(value) < 0.005:
		return "0.00%"

	if value > 0.0:
		return "+%.2f%%" % value

	return "%.2f%%" % value


static func season_date(season: Variant, day: int, year: int) -> String:
	return "%s %d, Year %d" % [
		display_season_name(season),
		day,
		year
	]


static func ordinal_day(day: int) -> String:
	var suffix := "th"
	var normalized_day := absi(day)

	if normalized_day % 100 < 11 or normalized_day % 100 > 13:
		match normalized_day % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"

	return "%d%s" % [day, suffix]


static func season_day(season: Variant, day: int) -> String:
	return "%s %s" % [
		ordinal_day(day),
		display_season_name(season)
	]


static func display_season_name(season: Variant) -> String:
	if season is int:
		match int(season):
			1:
				return "Spring"
			2:
				return "Summer"
			3:
				return "Autumn"
			4:
				return "Winter"

	var key := String(season).strip_edges().to_lower()

	match key:
		"1", "spring":
			return "Spring"
		"2", "summer":
			return "Summer"
		"3", "autumn", "fall":
			return "Autumn"
		"4", "winter":
			return "Winter"
		_:
			return _title_from_identifier(key)


static func display_product_name(value: Variant) -> String:
	var raw := _extract_display_source(value)
	var key := raw.strip_edges().to_lower()

	if key.ends_with("_seed"):
		return display_seed_name(key)

	match key:
		"potatoe":
			return "Potato"
		"tomatoe":
			return "Tomato"
		_:
			return _title_from_identifier(key)


static func display_seed_name(value: Variant) -> String:
	var raw := _extract_display_source(value)
	var key := raw.strip_edges().to_lower().trim_suffix("_seed")

	if key.ends_with(" seeds"):
		return _title_from_identifier(key)

	return "%s Seeds" % display_product_name(key)


static func display_market_trend(trend: Variant) -> String:
	if trend is int:
		match int(trend):
			0:
				return "Bearish"
			2:
				return "Bullish"
			_:
				return "Neutral"

	match String(trend).strip_edges().to_lower():
		"bullish":
			return "Bullish"
		"bearish":
			return "Bearish"
		_:
			return "Neutral"


static func display_weather_name(value: Variant) -> String:
	var raw := _extract_display_source(value)
	var key := raw.strip_edges().to_lower()

	match key:
		"rain", "rainy", "rainy_day":
			return "Rainy"
		"storm", "stormy", "stormy_day":
			return "Stormy"
		"sunny_day", "sunny day":
			return "Sunny"
		"cloudy_day", "cloudy day":
			return "Cloudy"
		"mixed_day", "mixed day":
			return "Mixed"
		"snow", "snowy", "snowy_day", "snowy day":
			return "Snowy"
		"fog", "foggy", "foggy_day", "foggy day":
			return "Foggy"
		_:
			return _title_from_identifier(key.trim_suffix("_day"))


static func display_news_category(category: String) -> String:
	match category.strip_edges().to_lower():
		"market":
			return "Market"
		"weather":
			return "Weather"
		"seasonal":
			return "Seasonal"
		"system":
			return "System"
		_:
			return _title_from_identifier(category)


static func input_event_text(event: InputEvent) -> String:
	if event == null:
		return "Unassigned"

	return event.as_text().replace(" - Physical", "")


static func _extract_display_source(value: Variant) -> String:
	if value == null:
		return "Unknown"

	if value is Resource:
		var resource := value as Resource

		if not String(resource.get("display_name")).is_empty():
			return String(resource.get("display_name"))

		if not String(resource.get("id")).is_empty():
			return String(resource.get("id"))

		if not String(resource.get("pattern_id")).is_empty():
			return String(resource.get("pattern_id"))

	return String(value)


static func _title_from_identifier(value: String) -> String:
	var words := value.replace("_", " ").replace("-", " ").strip_edges().split(" ", false)
	var titled_words: Array[String] = []

	for word in words:
		var lower := word.to_lower()

		if lower.is_empty():
			continue

		titled_words.append(lower.substr(0, 1).to_upper() + lower.substr(1))

	if titled_words.is_empty():
		return "Unknown"

	return " ".join(titled_words)
