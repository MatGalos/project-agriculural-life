extends Resource
class_name WeatherPhaseData

enum DayPhase {
	DAWN,
	MORNING,
	AFTERNOON,
	NIGHT
}

@export var phase: DayPhase = DayPhase.MORNING
@export var weather: WeatherData
@export var temperature: int = 20
@export_range(0, 100, 1) var rain_chance: int = 0
