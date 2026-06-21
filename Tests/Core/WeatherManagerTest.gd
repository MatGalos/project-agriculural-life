extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- WeatherManagerTest ---")

	var saved_minute_of_day := TimeManager.current_minute_of_day
	var saved_current_day_phase := WeatherManager.current_day_phase
	var saved_today_phase_forecast := WeatherManager.today_phase_forecast.duplicate()
	var saved_current_phase_weather := WeatherManager.current_phase_weather
	var saved_current_weather := WeatherManager.current_weather
	var saved_current_temperature := WeatherManager.current_temperature
	var saved_current_day_pattern := WeatherManager.current_day_pattern
	var saved_current_day_base_temperature := WeatherManager.current_day_base_temperature

	WeatherManager.today_phase_forecast.clear()

	_test_day_phase_boundaries()
	_test_time_changed_updates_cached_day_phase()
	_test_phase_temperatures_use_one_day_base_temperature()
	_test_phase_forecast_text_format()
	_test_forecast_entry_contains_pattern_and_rain_chance()

	TimeManager.current_minute_of_day = saved_minute_of_day
	WeatherManager.current_day_phase = saved_current_day_phase
	WeatherManager.today_phase_forecast.clear()
	for phase_data in saved_today_phase_forecast:
		WeatherManager.today_phase_forecast.append(phase_data)
	WeatherManager.current_phase_weather = saved_current_phase_weather
	WeatherManager.current_weather = saved_current_weather
	WeatherManager.current_temperature = saved_current_temperature
	WeatherManager.current_day_pattern = saved_current_day_pattern
	WeatherManager.current_day_base_temperature = saved_current_day_base_temperature


func _test_day_phase_boundaries() -> void:
	_set_hour(4)
	runner.assert_eq(
		WeatherManager.get_current_day_phase(),
		WeatherPhaseData.DayPhase.NIGHT,
		"Weather phase is Night before dawn"
	)

	_set_hour(5)
	runner.assert_eq(
		WeatherManager.get_current_day_phase(),
		WeatherPhaseData.DayPhase.DAWN,
		"Weather phase is Dawn at 05:00"
	)

	_set_hour(9)
	runner.assert_eq(
		WeatherManager.get_current_day_phase(),
		WeatherPhaseData.DayPhase.MORNING,
		"Weather phase is Morning at 09:00"
	)

	_set_hour(14)
	runner.assert_eq(
		WeatherManager.get_current_day_phase(),
		WeatherPhaseData.DayPhase.AFTERNOON,
		"Weather phase is Afternoon at 14:00"
	)

	_set_hour(20)
	runner.assert_eq(
		WeatherManager.get_current_day_phase(),
		WeatherPhaseData.DayPhase.NIGHT,
		"Weather phase is Night at 20:00"
	)


func _test_time_changed_updates_cached_day_phase() -> void:
	_set_hour(6)
	WeatherManager.current_day_phase = WeatherPhaseData.DayPhase.DAWN
	WeatherManager._on_time_changed()
	runner.assert_eq(
		WeatherManager.current_day_phase,
		WeatherPhaseData.DayPhase.DAWN,
		"Weather cached phase stays unchanged within the same phase"
	)

	_set_hour(9)
	WeatherManager._on_time_changed()
	runner.assert_eq(
		WeatherManager.current_day_phase,
		WeatherPhaseData.DayPhase.MORNING,
		"Weather cached phase updates to Morning on time change"
	)

	_set_hour(14)
	WeatherManager._on_time_changed()
	runner.assert_eq(
		WeatherManager.current_day_phase,
		WeatherPhaseData.DayPhase.AFTERNOON,
		"Weather cached phase updates to Afternoon on time change"
	)

	_set_hour(20)
	WeatherManager._on_time_changed()
	runner.assert_eq(
		WeatherManager.current_day_phase,
		WeatherPhaseData.DayPhase.NIGHT,
		"Weather cached phase updates to Night on time change"
	)


func _test_phase_temperatures_use_one_day_base_temperature() -> void:
	var pattern := WeatherDayPatternData.new()
	pattern.dawn_temperature_offset = -2
	pattern.morning_temperature_offset = 0
	pattern.afternoon_temperature_offset = 1
	pattern.night_temperature_offset = -4

	WeatherManager.current_day_pattern = pattern

	var day_base_temperature := 20
	var dawn := WeatherManager._generate_phase_forecast(
		WeatherPhaseData.DayPhase.DAWN,
		day_base_temperature
	)
	var morning := WeatherManager._generate_phase_forecast(
		WeatherPhaseData.DayPhase.MORNING,
		day_base_temperature
	)
	var afternoon := WeatherManager._generate_phase_forecast(
		WeatherPhaseData.DayPhase.AFTERNOON,
		day_base_temperature
	)
	var night := WeatherManager._generate_phase_forecast(
		WeatherPhaseData.DayPhase.NIGHT,
		day_base_temperature
	)

	runner.assert_eq(dawn.temperature, 18, "Dawn temperature uses day base plus dawn offset")
	runner.assert_eq(morning.temperature, 20, "Morning temperature uses the same day base")
	runner.assert_eq(afternoon.temperature, 21, "Afternoon temperature uses day base plus afternoon offset")
	runner.assert_eq(night.temperature, 16, "Night temperature uses day base plus night offset")


func _test_phase_forecast_text_format() -> void:
	var weather := WeatherData.new()
	weather.display_name = "Cloudy"

	var phase_data := WeatherPhaseData.new()
	phase_data.phase = WeatherPhaseData.DayPhase.MORNING
	phase_data.weather = weather
	phase_data.temperature = 20
	phase_data.rain_chance = 38

	runner.assert_eq(
		WeatherManager.get_phase_forecast_text(phase_data),
		"Morning: Cloudy, 20°C, Rain: 38%",
		"Weather phase forecast text uses compact rain label"
	)


func _test_forecast_entry_contains_pattern_and_rain_chance() -> void:
	var entry := WeatherManager._generate_forecast_entry()

	runner.assert_true(entry.has("weather"), "Weather forecast entry stores weather")
	runner.assert_true(entry.has("temperature"), "Weather forecast entry stores temperature")
	runner.assert_true(entry.has("pattern"), "Weather forecast entry stores day pattern")
	runner.assert_true(entry.has("base_temperature"), "Weather forecast entry stores base temperature")
	runner.assert_true(entry.has("rain_chance"), "Weather forecast entry stores rain chance")
	runner.assert_true(
		entry["pattern"] is WeatherDayPatternData,
		"Weather forecast entry pattern is weather day pattern data"
	)

	var rain_chance := int(entry["rain_chance"])
	runner.assert_true(
		rain_chance >= 0 and rain_chance <= 100,
		"Weather forecast entry rain chance is in percent range"
	)


func _set_hour(hour: int) -> void:
	TimeManager.current_minute_of_day = hour * 60
