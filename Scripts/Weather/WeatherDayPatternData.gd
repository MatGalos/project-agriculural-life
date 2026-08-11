extends Resource
class_name WeatherDayPatternData

@export var pattern_id: String = ""
@export var display_name: String = ""

@export_range(0, 100, 1) var spring_weight: int = 25
@export_range(0, 100, 1) var summer_weight: int = 25
@export_range(0, 100, 1) var autumn_weight: int = 25
@export_range(0, 100, 1) var winter_weight: int = 25

@export var dawn_weather_options: Array[WeatherData] = []
@export var morning_weather_options: Array[WeatherData] = []
@export var afternoon_weather_options: Array[WeatherData] = []
@export var night_weather_options: Array[WeatherData] = []

@export var base_temperature_min: int = 10
@export var base_temperature_max: int = 24

@export var dawn_temperature_offset: int = -2
@export var morning_temperature_offset: int = 0
@export var afternoon_temperature_offset: int = 2
@export var night_temperature_offset: int = -4
