extends Control
class_name WeatherPanel

@export var row_scene: PackedScene

@onready var today_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TodayLabel
@onready var forecast_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ForecastScroll/ForecastContainer

func _ready() -> void:
	visible = false

	if not WeatherManager.weather_changed.is_connected(_on_weather_changed):
		WeatherManager.weather_changed.connect(_on_weather_changed)

	refresh()

func _on_weather_changed(_current_weather: WeatherData, _temperature: int) -> void:
	refresh()

func refresh() -> void:
	_update_today()
	_update_forecast()

func _update_today() -> void:
	today_label.text = "Today - %s\nCurrent: %s, %s\n" % [
		WeatherManager.get_current_day_pattern_name(),
		WeatherManager.get_current_weather_name(),
		WeatherManager.get_current_temperature_string()
	]

func _update_forecast() -> void:
	for child in forecast_container.get_children():
		child.queue_free()

	for phase_data in WeatherManager.get_today_phase_forecast():
		var label := Label.new()
		label.text = WeatherManager.get_phase_forecast_text(phase_data)
		forecast_container.add_child(label)

	var weekly_title := Label.new()
	weekly_title.text = "\nNext Days"
	forecast_container.add_child(weekly_title)

	if row_scene == null:
		return

	var forecast := WeatherManager.get_forecast()

	for i in range(forecast.size()):
		var entry := forecast[i]

		var row := row_scene.instantiate() as WeatherForecastRow
		if row == null:
			continue

		forecast_container.add_child(row)

		var weather := entry["weather"] as WeatherData
		var temperature := int(entry["temperature"])
		var pattern := entry.get("pattern", null) as WeatherDayPatternData
		var rain_chance := int(entry.get("rain_chance", 0))

		row.setup(i + 1, weather, temperature, pattern, rain_chance)
