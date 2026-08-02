extends Node3D

@export var sun_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var sun_visual: MeshInstance3D
@export var moon_visual: MeshInstance3D

@export var night_energy := 0.22
@export var dawn_energy := 0.6
@export var day_energy := 1.05
@export var evening_energy := 0.7

@export var night_sky_color := Color(0.08, 0.11, 0.20)
@export var dawn_sky_color := Color(0.58, 0.50, 0.62)
@export var day_sky_color := Color(0.58, 0.72, 0.88)
@export var evening_sky_color := Color(0.60, 0.42, 0.34)

@export var night_ambient := Color(0.16, 0.19, 0.28)
@export var dawn_ambient := Color(0.44, 0.40, 0.46)
@export var day_ambient := Color(0.58, 0.64, 0.70)
@export var evening_ambient := Color(0.42, 0.34, 0.34)

@export var night_light_color := Color(0.42, 0.52, 0.78)
@export var dawn_light_color := Color(1.0, 0.78, 0.55)
@export var day_light_color := Color(1.0, 0.96, 0.84)
@export var evening_light_color := Color(1.0, 0.68, 0.40)

@export_range(0.0, 2.0, 0.01) var night_ambient_energy := 0.48
@export_range(0.0, 2.0, 0.01) var dawn_ambient_energy := 0.62
@export_range(0.0, 2.0, 0.01) var day_ambient_energy := 0.58
@export_range(0.0, 2.0, 0.01) var evening_ambient_energy := 0.6

const MINUTES_PER_DAY := 24 * 60
const CELESTIAL_RADIUS := 55.0
const SUN_VISUAL_SCALE := 3.5
const MOON_VISUAL_SCALE := 2.4
const SUNRISE_MINUTE := 5 * 60
const SUNSET_MINUTE := 20 * 60
const SUN_PATH_Z_OFFSET := -0.35

var _lighting_points: Array[Dictionary] = []


func _ready() -> void:
	_setup_lighting_points()
	TimeManager.time_changed.connect(update_lighting)
	update_lighting()


func update_lighting() -> void:
	if sun_light == null:
		return

	if _lighting_points.is_empty():
		_setup_lighting_points()

	var progress := TimeManager.get_day_progress()

	var sun_source_direction := _get_sun_source_direction(TimeManager.current_minute_of_day)
	_align_sun_light_to_source(sun_source_direction)
	_update_celestial_visuals(progress, sun_source_direction)

	var lighting_state := _get_lighting_state(TimeManager.current_minute_of_day)

	sun_light.light_energy = float(lighting_state["light_energy"])
	sun_light.light_color = lighting_state["light_color"] as Color
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_blend_splits = true

	_update_environment(
		lighting_state["sky_color"] as Color,
		lighting_state["ambient_color"] as Color,
		float(lighting_state["ambient_energy"])
	)


func _setup_lighting_points() -> void:
	_lighting_points = [
		_create_lighting_point(0, night_energy, night_light_color, night_sky_color, night_ambient, night_ambient_energy),
		_create_lighting_point(5 * 60, night_energy, night_light_color, night_sky_color, night_ambient, night_ambient_energy),
		_create_lighting_point(7 * 60, dawn_energy, dawn_light_color, dawn_sky_color, dawn_ambient, dawn_ambient_energy),
		_create_lighting_point(10 * 60, day_energy, day_light_color, day_sky_color, day_ambient, day_ambient_energy),
		_create_lighting_point(16 * 60, day_energy, day_light_color, day_sky_color, day_ambient, day_ambient_energy),
		_create_lighting_point(18 * 60 + 30, evening_energy, evening_light_color, evening_sky_color, evening_ambient, evening_ambient_energy),
		_create_lighting_point(21 * 60, night_energy, night_light_color, night_sky_color, night_ambient, night_ambient_energy),
		_create_lighting_point(MINUTES_PER_DAY, night_energy, night_light_color, night_sky_color, night_ambient, night_ambient_energy)
	]


func _create_lighting_point(
	minute: int,
	light_energy: float,
	light_color: Color,
	sky_color: Color,
	ambient_color: Color,
	ambient_energy: float
) -> Dictionary:
	return {
		"minute": minute,
		"light_energy": light_energy,
		"light_color": light_color,
		"sky_color": sky_color,
		"ambient_color": ambient_color,
		"ambient_energy": ambient_energy
	}


func _get_lighting_state(current_minute: int) -> Dictionary:
	var previous: Dictionary = _lighting_points[0]
	var next: Dictionary = _lighting_points[_lighting_points.size() - 1]

	for i in range(_lighting_points.size() - 1):
		var point := _lighting_points[i]
		var following_point := _lighting_points[i + 1]

		if current_minute >= int(point["minute"]) and current_minute <= int(following_point["minute"]):
			previous = point
			next = following_point
			break

	var start_minute := int(previous["minute"])
	var end_minute := int(next["minute"])
	var blend := 0.0

	if end_minute > start_minute:
		blend = float(current_minute - start_minute) / float(end_minute - start_minute)

	blend = smoothstep(0.0, 1.0, clampf(blend, 0.0, 1.0))

	return {
		"light_energy": lerpf(float(previous["light_energy"]), float(next["light_energy"]), blend),
		"light_color": (previous["light_color"] as Color).lerp(next["light_color"] as Color, blend),
		"sky_color": (previous["sky_color"] as Color).lerp(next["sky_color"] as Color, blend),
		"ambient_color": (previous["ambient_color"] as Color).lerp(next["ambient_color"] as Color, blend),
		"ambient_energy": lerpf(float(previous["ambient_energy"]), float(next["ambient_energy"]), blend)
	}


func _update_environment(sky_color: Color, ambient_color: Color, ambient_energy: float) -> void:
	if world_environment == null:
		return

	var env := world_environment.environment

	if env == null:
		return

	env.background_mode = Environment.BG_COLOR
	env.background_color = sky_color

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = ambient_energy


func _update_celestial_visuals(day_progress: float, sun_source_direction: Vector3) -> void:
	_update_celestial_body(
		sun_visual,
		sun_source_direction,
		_get_sun_visibility(day_progress),
		SUN_VISUAL_SCALE
	)
	_update_celestial_body(
		moon_visual,
		-sun_source_direction,
		_get_moon_visibility(day_progress),
		MOON_VISUAL_SCALE
	)


func _update_celestial_body(
	body: MeshInstance3D,
	source_direction: Vector3,
	visibility_alpha: float,
	base_scale: float
) -> void:
	if body == null:
		return

	body.position = source_direction.normalized() * CELESTIAL_RADIUS
	body.visible = visibility_alpha > 0.02
	body.scale = Vector3.ONE * base_scale

	_set_visual_alpha(body, visibility_alpha)


func _get_sun_source_direction(current_minute: int) -> Vector3:
	var daylight_duration := float(SUNSET_MINUTE - SUNRISE_MINUTE)
	var daylight_progress := (float(current_minute) - float(SUNRISE_MINUTE)) / daylight_duration
	var sun_arc_angle := daylight_progress * PI

	return Vector3(
		-cos(sun_arc_angle),
		sin(sun_arc_angle),
		SUN_PATH_Z_OFFSET
	).normalized()


func _align_sun_light_to_source(source_direction: Vector3) -> void:
	if sun_light == null:
		return

	var light_direction := -source_direction.normalized()
	sun_light.global_transform.basis = Basis.looking_at(light_direction, Vector3.UP)


func _set_visual_alpha(body: MeshInstance3D, alpha: float) -> void:
	var material := body.get_active_material(0) as StandardMaterial3D

	if material == null:
		return

	var albedo := material.albedo_color
	albedo.a = clampf(alpha, 0.0, 1.0)
	material.albedo_color = albedo

	var emission := material.emission
	emission.a = clampf(alpha, 0.0, 1.0)
	material.emission = emission


func _get_sun_visibility(day_progress: float) -> float:
	var sunrise_start := 5.0 / 24.0
	var sunrise_end := 7.0 / 24.0
	var sunset_start := 18.0 / 24.0
	var sunset_end := 20.0 / 24.0

	var fade_in := smoothstep(sunrise_start, sunrise_end, day_progress)
	var fade_out := 1.0 - smoothstep(sunset_start, sunset_end, day_progress)

	return clampf(minf(fade_in, fade_out), 0.0, 1.0)


func _get_moon_visibility(day_progress: float) -> float:
	var dusk_start := 18.0 / 24.0
	var dusk_end := 20.0 / 24.0
	var dawn_start := 5.0 / 24.0
	var dawn_end := 7.0 / 24.0

	if day_progress >= dusk_start:
		return smoothstep(dusk_start, dusk_end, day_progress)

	if day_progress <= dawn_end:
		return 1.0 - smoothstep(dawn_start, dawn_end, day_progress)

	return 0.0
