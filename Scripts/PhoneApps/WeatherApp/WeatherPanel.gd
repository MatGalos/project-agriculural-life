extends Control
class_name WeatherPanel

@export var row_scene: PackedScene

@onready var today_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TodayLabel
@onready var forecast_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ForecastContainer

func _ready() -> void:
	visible = false

	if not WeatherManager.weather_changed.is_connected(refresh):
		WeatherManager.weather_changed.connect(_on_weather_changed)

	refresh()

func _on_weather_changed(_current_weather: WeatherData, _temperature: int) -> void:
	refresh()

func refresh() -> void:
	_update_today()
	_update_forecast()

func _update_today() -> void:
	today_label.text = "Today: %s, %s" % [
		WeatherManager.get_current_weather_name(),
		WeatherManager.get_current_temperature_string()
	]

func _update_forecast() -> void:
	if row_scene == null:
		return

	for child in forecast_container.get_children():
		child.queue_free()

	var forecast := WeatherManager.get_forecast()

	for i in range(forecast.size()):
		var entry := forecast[i]

		var row := row_scene.instantiate() as WeatherForecastRow
		if row == null:
			continue

		forecast_container.add_child(row)

		var weather := entry["weather"] as WeatherData
		var temperature := int(entry["temperature"])

		row.setup(i + 1, weather, temperature)
