extends Resource
class_name SeasonWeatherData

@export var season: SeasonData.Season

@export var temperature_modifier: int = 0

@export_range(-100,100,1)
var rain_chance_modifier: int = 0

@export_range(-100,100,1)
var storm_chance_modifier: int = 0

@export_range(-100,100,1)
var rain_weight_modifier: int = 0

@export_range(-100,100,1)
var storm_weight_modifier: int = 0
