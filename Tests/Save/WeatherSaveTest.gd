extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- WeatherSaveTest ---")

	WeatherManager._generate_initial_forecast()
	WeatherManager._apply_new_day_weather()

	var saved_weather_name := WeatherManager.get_current_weather_name()
	var saved_temperature := WeatherManager.current_temperature
	var saved_forecast_size := WeatherManager.get_forecast().size()
	var saved_forecast_entry := WeatherManager.get_forecast()[0] as Dictionary
	var saved_pattern := saved_forecast_entry.get("pattern", null) as WeatherDayPatternData
	var saved_pattern_id := saved_pattern.pattern_id if saved_pattern != null else ""
	var saved_rain_chance := int(saved_forecast_entry.get("rain_chance", 0))

	var save_data := SaveManager._create_weather_save_data()

	WeatherManager.forecast.clear()
	WeatherManager.current_temperature = -999

	SaveManager._apply_weather_save_data(save_data)

	var restored_forecast_entry := WeatherManager.get_forecast()[0] as Dictionary
	var restored_pattern := restored_forecast_entry.get("pattern", null) as WeatherDayPatternData
	var restored_pattern_id := restored_pattern.pattern_id if restored_pattern != null else ""

	runner.assert_eq(WeatherManager.get_current_weather_name(), saved_weather_name, "Weather current restored")
	runner.assert_eq(WeatherManager.current_temperature, saved_temperature, "Weather temperature restored")
	runner.assert_eq(WeatherManager.get_forecast().size(), saved_forecast_size, "Weather forecast restored")
	runner.assert_eq(restored_pattern_id, saved_pattern_id, "Weather forecast pattern restored")
	runner.assert_eq(
		int(restored_forecast_entry.get("rain_chance", 0)),
		saved_rain_chance,
		"Weather forecast rain chance restored"
	)
