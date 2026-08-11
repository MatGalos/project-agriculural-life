extends PanelContainer
class_name WeatherForecastRow

@onready var day_label: Label = $MarginContainer/Row/DayLabel
@onready var weather_icon: WeatherIcon = $MarginContainer/Row/WeatherIcon
@onready var weather_label: Label = $MarginContainer/Row/WeatherLabel
@onready var temperature_label: Label = $MarginContainer/Row/TemperatureLabel
@onready var rain_label: Label = $MarginContainer/Row/RainLabel


func setup(
	forecast_date: String,
	weather: WeatherData,
	temperature: int,
	pattern: WeatherDayPatternData = null,
	rain_chance: int = 0
) -> void:
	day_label.text = forecast_date

	var display_weather := _get_display_weather(weather, pattern)
	weather_label.text = display_weather
	weather_icon.setup(display_weather)
	temperature_label.text = "%d°C" % temperature
	rain_label.text = "Rain: %d%%" % rain_chance


func _get_display_weather(weather: WeatherData, pattern: WeatherDayPatternData) -> String:
	if pattern != null:
		return UIFormatHelper.display_weather_name(pattern)

	if weather != null:
		return UIFormatHelper.display_weather_name(weather)

	return "Unknown"
