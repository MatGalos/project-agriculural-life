extends HBoxContainer
class_name WeatherForecastRow

@onready var day_label: Label = $DayLabel
@onready var weather_label: Label = $WeatherLabel
@onready var temperature_label: Label = $TemperatureLabel


func setup(day_offset: int, weather: WeatherData, temperature: int) -> void:
	day_label.text = "Day +%d" % day_offset

	if weather == null:
		weather_label.text = "Unknown"
	else:
		weather_label.text = weather.display_name

	temperature_label.text = "%d°C" % temperature
