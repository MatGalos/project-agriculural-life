extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- WeatherManagerTest ---")

	var saved_minute_of_day := TimeManager.current_minute_of_day
	var saved_current_month := TimeManager.current_month
	var saved_current_day_phase := WeatherManager.current_day_phase
	var saved_today_phase_forecast := WeatherManager.today_phase_forecast.duplicate()
	var saved_current_phase_weather := WeatherManager.current_phase_weather
	var saved_current_weather := WeatherManager.current_weather
	var saved_current_temperature := WeatherManager.current_temperature
	var saved_current_day_pattern := WeatherManager.current_day_pattern
	var saved_current_day_base_temperature := WeatherManager.current_day_base_temperature
	var saved_season_weather_profiles := WeatherManager.season_weather_profiles.duplicate()

	WeatherManager.today_phase_forecast.clear()

	_test_day_phase_boundaries()
	_test_time_changed_updates_cached_day_phase()
	_test_phase_temperatures_use_one_day_base_temperature()
	_test_phase_forecast_text_format()
	_test_forecast_entry_contains_pattern_and_rain_chance()
	_set_test_season_weather_profiles()
	_test_season_temperature_modifier_changes_day_base_temperature()
	_test_season_weather_profile_modifies_pattern_weights()

	TimeManager.current_minute_of_day = saved_minute_of_day
	TimeManager.current_month = saved_current_month
	WeatherManager.current_day_phase = saved_current_day_phase
	WeatherManager.today_phase_forecast.clear()
	for phase_data in saved_today_phase_forecast:
		WeatherManager.today_phase_forecast.append(phase_data)
	WeatherManager.current_phase_weather = saved_current_phase_weather
	WeatherManager.current_weather = saved_current_weather
	WeatherManager.current_temperature = saved_current_temperature
	WeatherManager.current_day_pattern = saved_current_day_pattern
	WeatherManager.current_day_base_temperature = saved_current_day_base_temperature
	WeatherManager.season_weather_profiles = saved_season_weather_profiles


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


func _test_season_temperature_modifier_changes_day_base_temperature() -> void:
	var pattern := WeatherDayPatternData.new()
	pattern.base_temperature_min = 20
	pattern.base_temperature_max = 20

	TimeManager.current_month = 2
	runner.assert_eq(
		WeatherManager._roll_day_base_temperature(pattern),
		28,
		"Summer weather profile adds temperature modifier to day base temperature"
	)

	TimeManager.current_month = 4
	runner.assert_eq(
		WeatherManager._roll_day_base_temperature(pattern),
		10,
		"Winter weather profile subtracts temperature modifier from day base temperature"
	)


func _test_season_weather_profile_modifies_pattern_weights() -> void:
	var rainy_pattern := WeatherDayPatternData.new()
	rainy_pattern.pattern_id = "rainy_day"
	rainy_pattern.summer_weight = 10

	var stormy_pattern := WeatherDayPatternData.new()
	stormy_pattern.pattern_id = "stormy_day"
	stormy_pattern.summer_weight = 10
	stormy_pattern.winter_weight = 10

	TimeManager.current_month = 2
	runner.assert_eq(
		WeatherManager._get_pattern_weight_for_current_season(rainy_pattern),
		5,
		"Summer weather profile lowers rainy day pattern weight"
	)
	runner.assert_eq(
		WeatherManager._get_pattern_weight_for_current_season(stormy_pattern),
		25,
		"Summer weather profile raises stormy day pattern weight"
	)

	TimeManager.current_month = 4
	runner.assert_eq(
		WeatherManager._get_pattern_weight_for_current_season(stormy_pattern),
		0,
		"Season weather profile clamps negative pattern weight to zero"
	)


func _set_test_season_weather_profiles() -> void:
	var summer_profile := SeasonWeatherData.new()
	summer_profile.temperature_modifier = 8
	summer_profile.rain_weight_modifier = -5
	summer_profile.storm_weight_modifier = 15

	var winter_profile := SeasonWeatherData.new()
	winter_profile.temperature_modifier = -10
	winter_profile.storm_weight_modifier = -20

	WeatherManager.season_weather_profiles = {
		SeasonData.Season.SUMMER: summer_profile,
		SeasonData.Season.WINTER: winter_profile
	}


func _set_hour(hour: int) -> void:
	TimeManager.current_minute_of_day = hour * 60
