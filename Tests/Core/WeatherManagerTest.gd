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
	var saved_suppress_logs := WeatherManager.suppress_logs

	WeatherManager.suppress_logs = true
	WeatherManager.today_phase_forecast.clear()

	_test_day_phase_boundaries()
	_test_time_changed_updates_cached_day_phase()
	_test_phase_weather_waters_fields_when_active()
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
	WeatherManager.suppress_logs = saved_suppress_logs


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


func _test_phase_weather_waters_fields_when_active() -> void:
	var sunny := WeatherManager.get_weather_by_name("Sunny")
	var cloudy := WeatherManager.get_weather_by_name("Cloudy")
	var rain := WeatherManager.get_weather_by_name("Rain")
	var storm := WeatherManager.get_weather_by_name("Storm")

	_assert_single_phase_tile_state(
		rain,
		FarmTile.TileState.PLOWED,
		FarmTile.TileState.WATERED,
		"Rain phase waters plowed tile"
	)
	_assert_single_phase_tile_state(
		storm,
		FarmTile.TileState.PLOWED,
		FarmTile.TileState.WATERED,
		"Storm phase waters plowed tile"
	)
	_assert_single_phase_tile_state(
		sunny,
		FarmTile.TileState.PLOWED,
		FarmTile.TileState.PLOWED,
		"Sunny phase does not water plowed tile"
	)
	_assert_single_phase_tile_state(
		cloudy,
		FarmTile.TileState.PLOWED,
		FarmTile.TileState.PLOWED,
		"Cloudy phase does not water plowed tile"
	)

	_assert_rain_keeps_non_plowed_states(rain)
	_assert_dry_to_rain_transition_waters_on_rain_phase(sunny, rain)


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


func _assert_single_phase_tile_state(
	weather: WeatherData,
	start_state: FarmTile.TileState,
	expected_state: FarmTile.TileState,
	message: String
) -> void:
	var tile := _create_test_farm_tile(start_state)
	_set_single_phase_forecast(WeatherPhaseData.DayPhase.MORNING, weather)

	WeatherManager.current_day_phase = WeatherPhaseData.DayPhase.MORNING
	WeatherManager._apply_current_phase_weather()

	runner.assert_eq(int(tile.current_state), int(expected_state), message)
	_destroy_test_farm_tile(tile)


func _assert_rain_keeps_non_plowed_states(rain: WeatherData) -> void:
	var grass_tile := _create_test_farm_tile(FarmTile.TileState.GRASS)
	var watered_tile := _create_test_farm_tile(FarmTile.TileState.WATERED)
	_set_single_phase_forecast(WeatherPhaseData.DayPhase.AFTERNOON, rain)

	WeatherManager.current_day_phase = WeatherPhaseData.DayPhase.AFTERNOON
	WeatherManager._apply_current_phase_weather()

	runner.assert_eq(
		int(grass_tile.current_state),
		int(FarmTile.TileState.GRASS),
		"Rain phase leaves grass tile unchanged"
	)
	runner.assert_eq(
		int(watered_tile.current_state),
		int(FarmTile.TileState.WATERED),
		"Rain phase leaves watered tile watered"
	)

	_destroy_test_farm_tile(grass_tile)
	_destroy_test_farm_tile(watered_tile)


func _assert_dry_to_rain_transition_waters_on_rain_phase(
	sunny: WeatherData,
	rain: WeatherData
) -> void:
	var tile := _create_test_farm_tile(FarmTile.TileState.PLOWED)
	WeatherManager.today_phase_forecast.clear()
	WeatherManager.today_phase_forecast.append(_make_phase_forecast(
		WeatherPhaseData.DayPhase.DAWN,
		sunny,
		18
	))
	WeatherManager.today_phase_forecast.append(_make_phase_forecast(
		WeatherPhaseData.DayPhase.MORNING,
		rain,
		20
	))

	WeatherManager.current_day_phase = WeatherPhaseData.DayPhase.DAWN
	WeatherManager._apply_current_phase_weather()
	runner.assert_eq(
		int(tile.current_state),
		int(FarmTile.TileState.PLOWED),
		"Dry phase before rain does not water plowed tile"
	)

	WeatherManager.current_day_phase = WeatherPhaseData.DayPhase.MORNING
	WeatherManager._apply_current_phase_weather()
	runner.assert_eq(
		int(tile.current_state),
		int(FarmTile.TileState.WATERED),
		"Dry to rain phase transition waters when rain phase is applied"
	)

	_destroy_test_farm_tile(tile)


func _set_single_phase_forecast(
	phase: WeatherPhaseData.DayPhase,
	weather: WeatherData
) -> void:
	WeatherManager.today_phase_forecast.clear()
	WeatherManager.today_phase_forecast.append(_make_phase_forecast(phase, weather, 20))


func _make_phase_forecast(
	phase: WeatherPhaseData.DayPhase,
	weather: WeatherData,
	temperature: int
) -> WeatherPhaseData:
	var phase_data := WeatherPhaseData.new()
	phase_data.phase = phase
	phase_data.weather = weather
	phase_data.temperature = temperature
	phase_data.rain_chance = 100 if weather != null and weather.waters_fields else 0
	return phase_data


func _create_test_farm_tile(state: FarmTile.TileState) -> FarmTile:
	var tile := FarmTile.new()
	runner.add_child(tile)
	tile.set_state(state)
	return tile


func _destroy_test_farm_tile(tile: FarmTile) -> void:
	if tile == null:
		return

	if tile.get_parent() != null:
		tile.get_parent().remove_child(tile)

	tile.free()
