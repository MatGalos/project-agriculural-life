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

var season_weather_profiles := {
	SeasonData.Season.SPRING: preload("res://Data/Seasons/spring_weather.tres"),
	SeasonData.Season.SUMMER: preload("res://Data/Seasons/summer_weather.tres"),
	SeasonData.Season.AUTUMN: preload("res://Data/Seasons/autumn_weather.tres"),
	SeasonData.Season.WINTER: preload("res://Data/Seasons/winter_weather.tres")
}

var current_day_pattern: WeatherDayPatternData = null
var current_day_base_temperature: int = 20

var current_weather: WeatherData
var tomorrow_weather: WeatherData
var today_phase_forecast: Array[WeatherPhaseData] = []
var current_phase_weather: WeatherPhaseData

var current_temperature: int = 20
var tomorrow_temperature: int = 20
var current_day_phase: WeatherPhaseData.DayPhase = WeatherPhaseData.DayPhase.DAWN
const FORECAST_DAYS := 7

var forecast: Array[Dictionary] = []
const WEATHER_HISTORY_DAYS := 30
var daily_weather_history: Array[Dictionary] = []
var suppress_logs := false

func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)
	if not TimeManager.time_changed.is_connected(_on_time_changed):
		TimeManager.time_changed.connect(_on_time_changed)

	_generate_initial_forecast()
	_apply_new_day_weather()
	_generate_today_phase_forecast()
	if not suppress_logs:
		print_today_forecast()
	current_day_phase = get_current_day_phase()
	_apply_current_phase_weather()

	if not suppress_logs:
		print("Current weather phase: ", get_day_phase_name(current_day_phase))

func _on_day_changed() -> void:
	_record_completed_day_weather()
	_apply_new_day_weather()
	_generate_today_phase_forecast()
	if not suppress_logs:
		print_today_forecast()
	_apply_current_phase_weather()


func _record_completed_day_weather() -> void:
	var completed_date := _get_completed_day_date()
	var pattern_id := ""
	var pattern_name := ""

	if current_day_pattern != null:
		pattern_id = current_day_pattern.pattern_id
		pattern_name = current_day_pattern.display_name

	daily_weather_history.append({
		"year": completed_date["year"],
		"season": int(completed_date["season"]),
		"day": completed_date["day"],
		"is_rainy": _is_representative_day_rainy(current_day_pattern),
		"base_temperature": current_day_base_temperature,
		"pattern_id": pattern_id,
		"pattern_name": pattern_name
	})

	while daily_weather_history.size() > WEATHER_HISTORY_DAYS:
		daily_weather_history.pop_front()


func _get_completed_day_date() -> Dictionary:
	var day := TimeManager.current_day - 1
	var month := TimeManager.current_month
	var year := TimeManager.current_year

	if day < 1:
		day = TimeManager.DAYS_PER_MONTH
		month -= 1

		if month < 1:
			month = TimeManager.MONTHS_PER_YEAR
			year -= 1

	return {
		"year": maxi(year, 1),
		"season": _get_season_for_month(month),
		"day": day
	}


func _get_season_for_month(month: int) -> SeasonData.Season:
	match month:
		1:
			return SeasonData.Season.SPRING
		2:
			return SeasonData.Season.SUMMER
		3:
			return SeasonData.Season.AUTUMN
		4:
			return SeasonData.Season.WINTER
		_:
			return SeasonData.Season.SPRING


func _is_representative_day_rainy(pattern: WeatherDayPatternData) -> bool:
	# Market events use the whole-day pattern as the representative completed-day weather,
	# so phase changes during the current day cannot change event requirements retroactively.
	if pattern == null:
		return is_current_weather_watering_fields()

	if pattern.pattern_id == "rainy_day" or pattern.pattern_id == "stormy_day":
		return true

	var phase_options: Array[Array] = [
		pattern.dawn_weather_options,
		pattern.morning_weather_options,
		pattern.afternoon_weather_options,
		pattern.night_weather_options
	]

	for options in phase_options:
		for weather in options:
			if weather != null and weather.waters_fields:
				return true

	return false

func _on_time_changed() -> void:
	_update_day_phase()

func _apply_new_day_weather() -> void:
	if forecast.is_empty():
		_generate_initial_forecast()

	var today: Dictionary = forecast.pop_front()

	current_weather = today["weather"] as WeatherData
	current_temperature = int(today["temperature"])
	current_day_pattern = today.get("pattern", null) as WeatherDayPatternData
	current_day_base_temperature = int(today.get("base_temperature", current_temperature))

	_water_fields_if_needed()

	forecast.append(_generate_forecast_entry())

	var tomorrow: Dictionary = forecast[0]
	tomorrow_weather = tomorrow["weather"] as WeatherData
	tomorrow_temperature = int(tomorrow["temperature"])

	weather_changed.emit(current_weather, current_temperature)

	_log(
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

	_log("Weather watered fields: ", current_weather.display_name)

func _generate_initial_forecast() -> void:
	forecast.clear()

	for i in range(FORECAST_DAYS):
		forecast.append(_generate_forecast_entry())

func _generate_forecast_entry() -> Dictionary:
	var pattern := _roll_day_pattern()
	var base_temperature := _roll_day_base_temperature(pattern)
	var phase_data := _generate_phase_forecast_for_pattern(
		pattern,
		WeatherPhaseData.DayPhase.AFTERNOON,
		base_temperature
	)

	return {
		"weather": phase_data.weather,
		"temperature": phase_data.temperature,
		"pattern": pattern,
		"base_temperature": base_temperature,
		"rain_chance": phase_data.rain_chance
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

	_log(
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

func _generate_phase_forecast(
	phase: WeatherPhaseData.DayPhase,
	day_base_temperature: int
) -> WeatherPhaseData:
	return _generate_phase_forecast_for_pattern(
		current_day_pattern,
		phase,
		day_base_temperature
	)

func _generate_phase_forecast_for_pattern(
	pattern: WeatherDayPatternData,
	phase: WeatherPhaseData.DayPhase,
	day_base_temperature: int
) -> WeatherPhaseData:
	var phase_data := WeatherPhaseData.new()

	phase_data.phase = phase

	var options := _get_weather_options_for_phase(pattern, phase)

	if options.is_empty():
		options = weather_options

	phase_data.weather = options.pick_random()

	phase_data.temperature = day_base_temperature + _get_temperature_offset_for_phase(
		pattern,
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

	if current_day_pattern == null:
		current_day_pattern = _roll_day_pattern()
		current_day_base_temperature = _roll_day_base_temperature(current_day_pattern)

	if current_day_pattern:
		_log(
			"Weather day pattern: ",
			current_day_pattern.display_name,
			" | Base temp: ",
			current_day_base_temperature,
			"Â°C"
		)

	today_phase_forecast.append(_generate_phase_forecast(
		WeatherPhaseData.DayPhase.DAWN,
		current_day_base_temperature
	))
	today_phase_forecast.append(_generate_phase_forecast(
		WeatherPhaseData.DayPhase.MORNING,
		current_day_base_temperature
	))
	today_phase_forecast.append(_generate_phase_forecast(
		WeatherPhaseData.DayPhase.AFTERNOON,
		current_day_base_temperature
	))
	today_phase_forecast.append(_generate_phase_forecast(
		WeatherPhaseData.DayPhase.NIGHT,
		current_day_base_temperature
	))

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

	_log(
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

	var weight := 0

	match TimeManager.get_current_season():
		SeasonData.Season.SPRING:
			weight = pattern.spring_weight
		SeasonData.Season.SUMMER:
			weight = pattern.summer_weight
		SeasonData.Season.AUTUMN:
			weight = pattern.autumn_weight
		SeasonData.Season.WINTER:
			weight = pattern.winter_weight
		_:
			weight = 0

	var season_profile := get_current_season_weather_profile()

	if season_profile != null:
		if pattern.pattern_id == "rainy_day":
			weight += season_profile.rain_weight_modifier

		if pattern.pattern_id == "stormy_day":
			weight += season_profile.storm_weight_modifier

	return maxi(weight, 0)

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

func _roll_day_base_temperature(pattern: WeatherDayPatternData) -> int:
	if pattern == null:
		return 20

	var base_temperature := randi_range(
		pattern.base_temperature_min,
		pattern.base_temperature_max
	)
	var season_profile := get_current_season_weather_profile()

	if season_profile == null:
		return base_temperature

	return base_temperature + season_profile.temperature_modifier

func get_day_pattern_by_id(pattern_id: String) -> WeatherDayPatternData:
	for pattern in weather_day_patterns:
		if pattern != null and pattern.pattern_id == pattern_id:
			return pattern

	return null

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

func get_today_phase_forecast() -> Array[WeatherPhaseData]:
	return today_phase_forecast


func get_current_phase_weather() -> WeatherPhaseData:
	return current_phase_weather


func get_current_day_pattern_name() -> String:
	if current_day_pattern == null:
		return "Unknown"

	return current_day_pattern.display_name

func get_phase_forecast_text(phase_data: WeatherPhaseData) -> String:
	if phase_data == null or phase_data.weather == null:
		return "Unknown"

	return "%s: %s, %d°C, Rain: %d%%" % [
		get_day_phase_name(phase_data.phase),
		phase_data.weather.display_name,
		phase_data.temperature,
		phase_data.rain_chance
	]

func print_today_forecast() -> void:
	_log("Today pattern: ", get_current_day_pattern_name())

	for phase_data in today_phase_forecast:
		_log(get_phase_forecast_text(phase_data))

func get_current_season_weather_profile() -> SeasonWeatherData:
	return season_weather_profiles.get(
		TimeManager.get_current_season(),
		null
	) as SeasonWeatherData


func get_consecutive_recent_dry_days() -> int:
	var count := 0

	for i in range(daily_weather_history.size() - 1, -1, -1):
		var entry := daily_weather_history[i]

		if bool(entry.get("is_rainy", false)):
			break

		count += 1

	return count


func get_rainy_days_in_recent_days(days: int) -> int:
	var count := 0
	var checked_days := mini(maxi(days, 0), daily_weather_history.size())

	for i in range(checked_days):
		var index := daily_weather_history.size() - 1 - i
		var entry := daily_weather_history[index]

		if bool(entry.get("is_rainy", false)):
			count += 1

	return count


func get_current_day_base_temperature() -> float:
	return float(current_day_base_temperature)


func create_weather_history_save_data() -> Array:
	return daily_weather_history.duplicate(true)


func apply_weather_history_save_data(history_data: Array) -> void:
	daily_weather_history.clear()

	for entry in history_data:
		if not (entry is Dictionary):
			continue

		var saved_entry := entry as Dictionary
		daily_weather_history.append({
			"year": int(saved_entry.get("year", 1)),
			"season": int(saved_entry.get("season", SeasonData.Season.SPRING)),
			"day": clampi(int(saved_entry.get("day", 1)), 1, TimeManager.DAYS_PER_MONTH),
			"is_rainy": bool(saved_entry.get("is_rainy", false)),
			"base_temperature": float(saved_entry.get("base_temperature", 20.0)),
			"pattern_id": String(saved_entry.get("pattern_id", "")),
			"pattern_name": String(saved_entry.get("pattern_name", ""))
		})

	while daily_weather_history.size() > WEATHER_HISTORY_DAYS:
		daily_weather_history.pop_front()


func _log(arg1 = "", arg2 = "", arg3 = "", arg4 = "", arg5 = "", arg6 = "", arg7 = "", arg8 = "", arg9 = "") -> void:
	if suppress_logs:
		return

	print(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
