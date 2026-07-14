extends HBoxContainer
class_name WeatherForecastRow

@onready var day_label: Label = $DayLabel
@onready var weather_label: Label = $WeatherLabel
@onready var temperature_label: Label = $TemperatureLabel
@onready var rain_label: Label = $RainLabel


func setup(
	day_offset: int,
	weather: WeatherData,
	temperature: int,
	pattern: WeatherDayPatternData = null,
	rain_chance: int = 0
) -> void:
	if day_offset == 1:
		day_label.text = "Tomorrow"
	else:
		day_label.text = "Day +%d" % day_offset

	if pattern != null:
		weather_label.text = UIFormatHelper.display_weather_name(pattern)
	elif weather == null:
		weather_label.text = "Unknown"
	else:
		weather_label.text = UIFormatHelper.display_weather_name(weather)

	temperature_label.text = "%d°C" % temperature
	rain_label.text = "Rain: %d%%" % rain_chance
