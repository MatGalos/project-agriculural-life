extends Node

signal weather_changed(current_weather: WeatherData, temperature: int)

var weather_options: Array[WeatherData] = [
	preload("res://Data/Weather/sunny_weather.tres"),
	preload("res://Data/Weather/cloudy_weather.tres"),
	preload("res://Data/Weather/rain_weather.tres"),
	preload("res://Data/Weather/storm_weather.tres")
]

var current_weather: WeatherData
var tomorrow_weather: WeatherData

var current_temperature: int = 20
var tomorrow_temperature: int = 20

func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)

	tomorrow_weather = _roll_weather()
	tomorrow_temperature = _roll_temperature(tomorrow_weather)

	_apply_new_day_weather()

func _on_day_changed() -> void:
	_apply_new_day_weather()

func _apply_new_day_weather() -> void:
	current_weather = tomorrow_weather
	current_temperature = tomorrow_temperature

	tomorrow_weather = _roll_weather()
	tomorrow_temperature = _roll_temperature(tomorrow_weather)

	weather_changed.emit(current_weather, current_temperature)

	print(
		"Weather today: ",
		current_weather.display_name,
		" ",
		current_temperature,
		"°C | Tomorrow: ",
		tomorrow_weather.display_name,
		" ",
		tomorrow_temperature,
		"°C"
	)

func _roll_weather() -> WeatherData:
	return weather_options.pick_random()

func _roll_temperature(weather: WeatherData) -> int:
	if weather == null:
		return 20

	return randi_range(weather.min_temperature, weather.max_temperature)

func get_current_weather_name() -> String:
	if current_weather == null:
		return "Unknown"

	return current_weather.display_name

func get_tomorrow_weather_name() -> String:
	if tomorrow_weather == null:
		return "Unknown"

	return tomorrow_weather.display_name

func get_current_temperature_string() -> String:
	return "%d°C" % current_temperature

func get_tomorrow_temperature_string() -> String:
	return "%d°C" % tomorrow_temperature
