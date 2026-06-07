extends Resource
class_name WeatherData

enum WeatherType {
	SUNNY,
	CLOUDY,
	RAIN,
	STORM
}

@export var weather_type: WeatherType = WeatherType.SUNNY
@export var display_name: String = "Sunny"

@export var waters_fields: bool = false

@export var light_energy_multiplier: float = 1.0
@export var sky_darkness_multiplier: float = 1.0

@export var min_temperature: int = 12
@export var max_temperature: int = 24
