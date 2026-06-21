extends Node

signal weather_changed(current_weather: WeatherData, temperature: int)

var weather_options: Array[WeatherData] = [
	preload("res://Data/Weather/sunny_weather.tres"),
	preload("res://Data/Weather/cloudy_weather.tres"),
	preload("res://Data/Weather/rain_weather.tres"),
	preload("res://Data/Weather/storm_weather.tres")
]

var weather_day_patterns: Array[WeatherDayPatternData] = [
	preload("res://Data/Weather/Patterns/sunny_day_pattern.tres"),
	preload("res://Data/Weather/Patterns/cloudy_day_pattern.tres"),
	preload("res://Data/Weather/Patterns/rainy_day_pattern.tres"),
	preload("res://Data/Weather/Patterns/mixed_day_pattern.tres"),
	preload("res://Data/Weather/Patterns/stormy_day_pattern.tres")
]
var current_day_pattern: WeatherDayPatternData = null

var current_weather: WeatherData
var tomorrow_weather: WeatherData
var today_phase_forecast: Array[WeatherPhaseData] = []
var current_phase_weather: WeatherPhaseData

var current_temperature: int = 20
var tomorrow_temperature: int = 20
var current_day_phase: WeatherPhaseData.DayPhase = WeatherPhaseData.DayPhase.DAWN
const FORECAST_DAYS := 7

var forecast: Array[Dictionary] = []

func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)
	if not TimeManager.time_changed.is_connected(_on_time_changed):
		TimeManager.time_changed.connect(_on_time_changed)

	_generate_initial_forecast()
	_apply_new_day_weather()
	_generate_today_phase_forecast()
	current_day_phase = get_current_day_phase()
	_apply_current_phase_weather()

	current_day_phase = get_current_day_phase()
	print("Current weather phase: ", get_day_phase_name(current_day_phase))

func _on_day_changed() -> void:
	_apply_new_day_weather()

func _on_time_changed() -> void:
	_update_day_phase()

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

func get_weather_by_name(weather_name: String) -> WeatherData:
	for weather in weather_options:
		if weather != null and weather.display_name == weather_name:
			return weather

	return null

func is_current_weather_watering_fields() -> bool:
	if current_weather == null:
		return false

	return current_weather.waters_fields

func get_day_phase_name(phase: WeatherPhaseData.DayPhase) -> String:
	match phase:
		WeatherPhaseData.DayPhase.DAWN:
			return "Dawn"
		WeatherPhaseData.DayPhase.MORNING:
			return "Morning"
		WeatherPhaseData.DayPhase.AFTERNOON:
			return "Afternoon"
		WeatherPhaseData.DayPhase.NIGHT:
			return "Night"
		_:
			return "Unknown"

func _update_day_phase() -> void:
	var new_phase := get_current_day_phase()

	if new_phase == current_day_phase:
		return

	current_day_phase = new_phase

	print(
		"Weather phase changed to: ",
		get_day_phase_name(current_day_phase)
	)

	_apply_current_phase_weather()

func get_current_day_phase() -> WeatherPhaseData.DayPhase:
	var hour := TimeManager.get_hour()

	if hour >= 5 and hour < 9:
		return WeatherPhaseData.DayPhase.DAWN

	if hour >= 9 and hour < 14:
		return WeatherPhaseData.DayPhase.MORNING

	if hour >= 14 and hour < 20:
		return WeatherPhaseData.DayPhase.AFTERNOON

	return WeatherPhaseData.DayPhase.NIGHT

func _generate_phase_forecast(phase: WeatherPhaseData.DayPhase) -> WeatherPhaseData:
	var phase_data := WeatherPhaseData.new()

	phase_data.phase = phase

	var options := _get_weather_options_for_phase(current_day_pattern, phase)

	if options.is_empty():
		options = weather_options

	phase_data.weather = options.pick_random()

	var base_temperature := 20

	if current_day_pattern != null:
		base_temperature = randi_range(
			current_day_pattern.base_temperature_min,
			current_day_pattern.base_temperature_max
		)

	phase_data.temperature = base_temperature + _get_temperature_offset_for_phase(
		current_day_pattern,
		phase
	)

	phase_data.rain_chance = _roll_rain_chance(phase_data.weather)

	return phase_data

func _roll_rain_chance(weather: WeatherData) -> int:
	if weather == null:
		return 0

	if weather.waters_fields:
		return randi_range(70, 100)

	if weather.display_name == "Cloudy":
		return randi_range(25, 55)

	return randi_range(0, 20)

func _generate_today_phase_forecast() -> void:
	today_phase_forecast.clear()

	current_day_pattern = _roll_day_pattern()

	if current_day_pattern:
		print("Weather day pattern: ", current_day_pattern.display_name)

	today_phase_forecast.append(_generate_phase_forecast(WeatherPhaseData.DayPhase.DAWN))
	today_phase_forecast.append(_generate_phase_forecast(WeatherPhaseData.DayPhase.MORNING))
	today_phase_forecast.append(_generate_phase_forecast(WeatherPhaseData.DayPhase.AFTERNOON))
	today_phase_forecast.append(_generate_phase_forecast(WeatherPhaseData.DayPhase.NIGHT))

func _get_phase_forecast(phase: WeatherPhaseData.DayPhase) -> WeatherPhaseData:
	for phase_data in today_phase_forecast:
		if phase_data != null and phase_data.phase == phase:
			return phase_data

	return null

func _apply_current_phase_weather() -> void:
	var phase_data := _get_phase_forecast(current_day_phase)

	if phase_data == null:
		return

	current_phase_weather = phase_data
	current_weather = phase_data.weather
	current_temperature = phase_data.temperature

	weather_changed.emit(current_weather, current_temperature)

	print(
		"Weather phase applied: ",
		get_day_phase_name(current_day_phase),
		" | ",
		current_weather.display_name,
		" ",
		current_temperature,
		"°C | Rain chance: ",
		phase_data.rain_chance,
		"%"
	)

func _get_pattern_weight_for_current_season(pattern: WeatherDayPatternData) -> int:
	if pattern == null:
		return 0

	match TimeManager.get_current_season():
		SeasonData.Season.SPRING:
			return pattern.spring_weight
		SeasonData.Season.SUMMER:
			return pattern.summer_weight
		SeasonData.Season.AUTUMN:
			return pattern.autumn_weight
		SeasonData.Season.WINTER:
			return pattern.winter_weight
		_:
			return 0

func _roll_day_pattern() -> WeatherDayPatternData:
	var total_weight := 0

	for pattern in weather_day_patterns:
		total_weight += _get_pattern_weight_for_current_season(pattern)

	if total_weight <= 0:
		return null

	var roll := randi_range(1, total_weight)
	var current := 0

	for pattern in weather_day_patterns:
		current += _get_pattern_weight_for_current_season(pattern)

		if roll <= current:
			return pattern

	return weather_day_patterns[0]

func _get_weather_options_for_phase(
	pattern: WeatherDayPatternData,
	phase: WeatherPhaseData.DayPhase
) -> Array[WeatherData]:
	if pattern == null:
		return weather_options

	match phase:
		WeatherPhaseData.DayPhase.DAWN:
			return pattern.dawn_weather_options
		WeatherPhaseData.DayPhase.MORNING:
			return pattern.morning_weather_options
		WeatherPhaseData.DayPhase.AFTERNOON:
			return pattern.afternoon_weather_options
		WeatherPhaseData.DayPhase.NIGHT:
			return pattern.night_weather_options
		_:
			return weather_options

func _get_temperature_offset_for_phase(
	pattern: WeatherDayPatternData,
	phase: WeatherPhaseData.DayPhase
) -> int:
	if pattern == null:
		return 0

	match phase:
		WeatherPhaseData.DayPhase.DAWN:
			return pattern.dawn_temperature_offset
		WeatherPhaseData.DayPhase.MORNING:
			return pattern.morning_temperature_offset
		WeatherPhaseData.DayPhase.AFTERNOON:
			return pattern.afternoon_temperature_offset
		WeatherPhaseData.DayPhase.NIGHT:
			return pattern.night_temperature_offset
		_:
			return 0
