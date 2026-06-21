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

	WeatherManager.today_phase_forecast.clear()

	_test_day_phase_boundaries()
	_test_time_changed_updates_cached_day_phase()

	TimeManager.current_minute_of_day = saved_minute_of_day
	WeatherManager.current_day_phase = saved_current_day_phase
	WeatherManager.today_phase_forecast.clear()
	for phase_data in saved_today_phase_forecast:
		WeatherManager.today_phase_forecast.append(phase_data)
	WeatherManager.current_phase_weather = saved_current_phase_weather
	WeatherManager.current_weather = saved_current_weather
	WeatherManager.current_temperature = saved_current_temperature


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


func _set_hour(hour: int) -> void:
	TimeManager.current_minute_of_day = hour * 60
