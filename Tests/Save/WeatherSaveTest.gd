extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- WeatherSaveTest ---")

	WeatherManager._generate_initial_forecast()
	WeatherManager._apply_new_day_weather()

	var saved_weather_name := WeatherManager.get_current_weather_name()
	var saved_temperature := WeatherManager.current_temperature
	var saved_forecast_size := WeatherManager.get_forecast().size()

	var save_data := SaveManager._create_weather_save_data()

	WeatherManager.forecast.clear()
	WeatherManager.current_temperature = -999

	SaveManager._apply_weather_save_data(save_data)

	runner.assert_eq(WeatherManager.get_current_weather_name(), saved_weather_name, "Weather current restored")
	runner.assert_eq(WeatherManager.current_temperature, saved_temperature, "Weather temperature restored")
	runner.assert_eq(WeatherManager.get_forecast().size(), saved_forecast_size, "Weather forecast restored")
