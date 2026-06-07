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
const FORECAST_DAYS := 7

var forecast: Array[Dictionary] = []

func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)

	_generate_initial_forecast()
	_apply_new_day_weather()

func _on_day_changed() -> void:
	_apply_new_day_weather()

func _apply_new_day_weather() -> void:
	if forecast.is_empty():
		_generate_initial_forecast()

	var today: Dictionary = forecast.pop_front()

	current_weather = today["weather"] as WeatherData
	current_temperature = int(today["temperature"])

	_water_fields_if_needed()

	forecast.append(_generate_forecast_entry())

	var tomorrow: Dictionary = forecast[0]
	tomorrow_weather = tomorrow["weather"] as WeatherData
	tomorrow_temperature = int(tomorrow["temperature"])

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

func _water_fields_if_needed() -> void:
	if current_weather == null:
		return

	if not current_weather.waters_fields:
		return

	var farm_tiles := get_tree().get_nodes_in_group("farm_tile")

	for tile in farm_tiles:
		if tile == null:
			continue

		if tile is FarmTile and tile.current_state == FarmTile.TileState.PLOWED:
			tile.water()

	print("Weather watered fields: ", current_weather.display_name)

func _generate_initial_forecast() -> void:
	forecast.clear()

	for i in range(FORECAST_DAYS):
		forecast.append(_generate_forecast_entry())

func _generate_forecast_entry() -> Dictionary:
	var weather: WeatherData = _roll_weather()
	var temperature: int = _roll_temperature(weather)

	return {
		"weather": weather,
		"temperature": temperature
	}

func get_forecast() -> Array[Dictionary]:
	return forecast
