extends Node3D

@export var sun_light: DirectionalLight3D
@export var world_environment: WorldEnvironment

@export var night_energy := 0.05
@export var dawn_energy := 0.45
@export var day_energy := 1.15
@export var evening_energy := 0.5

@export var night_sky_color := Color(0.03, 0.05, 0.11)
@export var dawn_sky_color := Color(0.55, 0.43, 0.55)
@export var day_sky_color := Color(0.55, 0.68, 0.82)
@export var evening_sky_color := Color(0.48, 0.36, 0.42)

@export var night_ambient := Color(0.04, 0.06, 0.12)
@export var dawn_ambient := Color(0.35, 0.32, 0.40)
@export var day_ambient := Color(0.55, 0.62, 0.70)
@export var evening_ambient := Color(0.32, 0.26, 0.32)


func _ready() -> void:
	TimeManager.time_changed.connect(update_lighting)
	update_lighting()


func update_lighting() -> void:
	if sun_light == null:
		return

	var hour := TimeManager.get_hour()
	var progress := TimeManager.get_day_progress()

	var sun_angle := lerpf(-180.0, 180.0, progress)
	sun_light.rotation_degrees.x = sun_angle

	var light_energy := day_energy
	var light_color := Color(1.0, 0.95, 0.82)
	var sky_color := day_sky_color
	var ambient_color := day_ambient

	if hour >= 0 and hour < 5:
		light_energy = night_energy
		light_color = Color(0.25, 0.35, 0.65)
		sky_color = night_sky_color
		ambient_color = night_ambient
	elif hour >= 5 and hour < 8:
		light_energy = dawn_energy
		light_color = Color(0.95, 0.62, 0.35)
		sky_color = dawn_sky_color
		ambient_color = dawn_ambient
	elif hour >= 8 and hour < 17:
		light_energy = day_energy
		light_color = Color(1.0, 0.95, 0.82)
		sky_color = day_sky_color
		ambient_color = day_ambient
	elif hour >= 17 and hour < 20:
		light_energy = evening_energy
		light_color = Color(1.0, 0.55, 0.28)
		sky_color = evening_sky_color
		ambient_color = evening_ambient
	else:
		light_energy = night_energy
		light_color = Color(0.25, 0.35, 0.65)
		sky_color = night_sky_color
		ambient_color = night_ambient

	sun_light.light_energy = light_energy
	sun_light.light_color = light_color

	_update_environment(sky_color, ambient_color)


func _update_environment(sky_color: Color, ambient_color: Color) -> void:
	if world_environment == null:
		return

	var env := world_environment.environment

	if env == null:
		return

	env.background_mode = Environment.BG_COLOR
	env.background_color = sky_color

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = 0.65
