extends Node3D

const SFX_BUS := "SFX"
const RAIN_LOOP_PATH := "res://Assets/Audio/Weather/rain_loop.wav"
const STORM_RAIN_LOOP_PATH := "res://Assets/Audio/Weather/storm_rain_loop.wav"
const THUNDER_PATH := "res://Assets/Audio/Weather/thunder.wav"

@export var follow_target: Node3D
@export var follow_offset := Vector3(0.0, 6.0, 0.0)
@export var rain_amount := 420
@export var storm_amount := 960
@export var cloud_layer_height := 18.0
@export var cloud_drift_speed := 0.025
@export var cloudy_cloud_alpha := 0.42
@export var rain_cloud_alpha := 0.58
@export var storm_cloud_alpha := 0.78
@export var thunder_min_delay := 8.0
@export var thunder_max_delay := 20.0
@export var rain_loop_volume_db := 0.0
@export var storm_loop_volume_db := 0.0
@export var thunder_volume_db := 0.0
@export var rain_loop_fallback_to_storm_stream := true
@export var rain_loop_manual_restart := true
@export var storm_loop_manual_restart := true
@export var lightning_flash_enabled := true
@export var lightning_flash_energy := 5.0
@export var lightning_flash_duration := 0.22
@export var lightning_screen_flash_alpha := 0.28
@export var debug_weather_effects := false

@onready var rain_particles: GPUParticles3D = $RainParticles
@onready var storm_particles: GPUParticles3D = $StormParticles
@onready var rain_audio: AudioStreamPlayer = $RainAudio
@onready var storm_audio: AudioStreamPlayer = $StormRainAudio
@onready var thunder_audio: AudioStreamPlayer = $ThunderAudio
@onready var thunder_timer: Timer = $ThunderTimer

var _rng := RandomNumberGenerator.new()
var _current_weather_key := "sunny"
var _unknown_weather_warning_printed := false
var _rebuilt_rain_player: AudioStreamPlayer
var _rebuilt_storm_player: AudioStreamPlayer
var _thunder_runtime_player: AudioStreamPlayer
var _lightning_flash: OmniLight3D
var _lightning_flash_timer: Timer
var _lightning_flash_canvas: CanvasLayer
var _lightning_flash_overlay: ColorRect
var _cloud_layer: Node3D
var _cloud_material: StandardMaterial3D
var _rain_watchdog_elapsed := 0.0
var _storm_watchdog_elapsed := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_debug_print("WeatherEffectsController ready")
	_rng.randomize()
	_configure_particles()
	_create_cloud_layer()
	_configure_audio()
	_create_lightning_flash()
	_connect_weather_manager()
	apply_current_weather()


func _exit_tree() -> void:
	_free_runtime_audio_player(_rebuilt_rain_player)
	_free_runtime_audio_player(_rebuilt_storm_player)
	_free_runtime_audio_player(_thunder_runtime_player)


func _process(delta: float) -> void:
	if follow_target == null:
		_update_rain_audio_watchdog(delta)
		_update_storm_audio_watchdog(delta)
		_update_cloud_drift(delta)
		return

	global_position = follow_target.global_position + follow_offset
	_update_rain_audio_watchdog(delta)
	_update_storm_audio_watchdog(delta)
	_update_cloud_drift(delta)


func apply_current_weather() -> void:
	var current_weather := _get_current_weather()
	_debug_print("WeatherEffects current weather raw: %s" % _describe_weather_value(current_weather))
	apply_weather(current_weather)


func set_weather(weather_value: Variant) -> void:
	apply_weather(weather_value)


func apply_weather(weather_value: Variant) -> void:
	var weather_key := _get_weather_key(weather_value)
	_debug_print("WeatherEffects normalized weather: %s" % weather_key)
	_apply_weather_effects(weather_key)


func _connect_weather_manager() -> void:
	if not WeatherManager.weather_changed.is_connected(_on_weather_changed):
		WeatherManager.weather_changed.connect(_on_weather_changed)


func _on_weather_changed(current_weather: WeatherData, _temperature: int) -> void:
	_debug_print("WeatherEffects current weather raw: %s" % _describe_weather_value(current_weather))
	apply_weather(current_weather)


func _get_current_weather() -> WeatherData:
	return WeatherManager.current_weather


func _apply_weather_effects(weather_key: String) -> void:
	var previous_weather_key := _current_weather_key
	_current_weather_key = weather_key

	match weather_key:
		"rain":
			_set_rain_weather(previous_weather_key)
		"storm":
			_set_storm_weather()
		"cloudy":
			_set_cloudy_weather()
		_:
			_set_clear_weather()


func _set_clear_weather() -> void:
	_debug_print("WeatherEffects apply %s" % _current_weather_key)
	_set_cloud_layer("sunny", Color(1.0, 1.0, 1.0, 0.0), 0.0)
	_set_particles_active(rain_particles, false)
	_set_particles_active(storm_particles, false)
	_stop_rain_loop()
	_stop_storm_loop()
	_stop_thunder_timer()


func _set_cloudy_weather() -> void:
	_debug_print("WeatherEffects apply cloudy")
	_set_cloud_layer("cloudy", Color(0.86, 0.88, 0.88, cloudy_cloud_alpha), cloudy_cloud_alpha)
	_set_particles_active(rain_particles, false)
	_set_particles_active(storm_particles, false)
	_stop_rain_loop()
	_stop_storm_loop()
	_stop_thunder_timer()


func _set_rain_weather(previous_weather_key: String) -> void:
	_debug_print("WeatherEffects apply rain")
	_set_cloud_layer("rain", Color(0.58, 0.62, 0.64, rain_cloud_alpha), rain_cloud_alpha)
	_set_particles_active(rain_particles, true)
	_set_particles_active(storm_particles, false)
	_stop_storm_loop()
	_play_rain_loop(previous_weather_key != "rain")
	_stop_thunder_timer()


func _set_storm_weather() -> void:
	_debug_print("WeatherEffects apply storm")
	_set_cloud_layer("storm", Color(0.31, 0.33, 0.36, storm_cloud_alpha), storm_cloud_alpha)
	_set_particles_active(rain_particles, false)
	_set_particles_active(storm_particles, true)
	_stop_rain_loop()
	_play_storm_loop()
	_schedule_next_thunder()


func _set_particles_active(particles: GPUParticles3D, is_active: bool) -> void:
	if particles == null:
		return

	particles.emitting = is_active
	particles.visible = is_active

	if particles == rain_particles:
		_debug_print("Rain VFX %s" % ("ON" if is_active else "OFF"))

	if particles == storm_particles:
		_debug_print("Storm VFX %s" % ("ON" if is_active else "OFF"))


func _create_cloud_layer() -> void:
	_cloud_layer = Node3D.new()
	_cloud_layer.name = "WeatherCloudLayer"
	_cloud_layer.position = Vector3(0.0, cloud_layer_height, 0.0)
	_cloud_layer.visible = false
	add_child(_cloud_layer)

	_cloud_material = StandardMaterial3D.new()
	_cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cloud_material.albedo_color = Color(0.86, 0.88, 0.88, 0.0)

	var cloud_offsets := [
		Vector3(-18.0, 0.0, -14.0),
		Vector3(-8.0, 1.5, 12.0),
		Vector3(12.0, 0.8, -10.0),
		Vector3(22.0, 1.2, 8.0),
		Vector3(2.0, 2.0, 22.0),
		Vector3(-24.0, 0.6, 8.0)
	]

	for cloud_index in range(cloud_offsets.size()):
		_create_cloud_cluster(cloud_index, cloud_offsets[cloud_index])

	_debug_print("CloudLayer ready")


func _create_cloud_cluster(cloud_index: int, cluster_position: Vector3) -> void:
	var cluster := Node3D.new()
	cluster.name = "Cloud_%02d" % cloud_index
	cluster.position = cluster_position
	_cloud_layer.add_child(cluster)

	var puff_offsets := [
		Vector3(-1.9, 0.0, 0.0),
		Vector3(0.0, 0.25, -0.25),
		Vector3(2.0, 0.0, 0.15),
		Vector3(0.85, -0.1, 0.85)
	]

	var puff_scales := [
		Vector3(3.2, 0.45, 1.65),
		Vector3(3.8, 0.58, 1.95),
		Vector3(3.1, 0.43, 1.55),
		Vector3(2.3, 0.36, 1.25)
	]

	for puff_index in range(puff_offsets.size()):
		var puff := MeshInstance3D.new()
		puff.name = "Puff_%02d" % puff_index
		puff.mesh = _create_cloud_puff_mesh()
		puff.material_override = _cloud_material
		puff.position = puff_offsets[puff_index]
		puff.scale = puff_scales[puff_index]
		cluster.add_child(puff)


func _create_cloud_puff_mesh() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.radius = 1.0
	mesh.height = 1.0
	return mesh


func _set_cloud_layer(weather_key: String, color: Color, intensity: float) -> void:
	if _cloud_layer == null or _cloud_material == null:
		return

	var clamped_intensity := clampf(intensity, 0.0, 1.0)
	_cloud_layer.visible = clamped_intensity > 0.01
	_cloud_material.albedo_color = Color(color.r, color.g, color.b, clamped_intensity)

	if weather_key == "sunny":
		_debug_print("CloudLayer sunny OFF")
	else:
		_debug_print("CloudLayer %s ON" % weather_key)

	_debug_print("Cloud intensity: %.2f" % clamped_intensity)


func _update_cloud_drift(delta: float) -> void:
	if _cloud_layer == null or not _cloud_layer.visible:
		return

	_cloud_layer.rotate_y(cloud_drift_speed * delta)


func _play_loop(
	player: AudioStreamPlayer,
	force_restart: bool = false,
	debug_label: String = ""
) -> void:
	if player == null:
		_debug_print("Weather SFX PLAY skipped: player is null")
		return

	if player.stream == null:
		_debug_print("Weather SFX PLAY skipped: stream is null for %s" % player.name)
		return

	if force_restart and player.playing:
		player.stop()
		_debug_print("Weather SFX RESTART: %s" % player.name)

	if player.playing:
		_debug_print("Weather SFX PLAY skipped: %s already playing" % player.name)
		return

	_debug_audio_state(player)
	player.play(0.0)
	_verify_loop_playing.call_deferred(player)

	if debug_label != "":
		_debug_print("%s SFX PLAY" % debug_label)
	elif player == rain_audio:
		_debug_print("Rain SFX PLAY")
	elif player == storm_audio or player == _rebuilt_storm_player:
		_debug_print("Storm SFX PLAY")


func _play_rain_loop(force_restart: bool = false) -> void:
	if _rebuilt_rain_player == null:
		_debug_print("Rain SFX PLAY skipped: rebuilt rain player is null")
		return

	_rebuilt_rain_player.volume_db = rain_loop_volume_db
	_play_loop(_rebuilt_rain_player, force_restart, "Rain")


func _stop_rain_loop() -> void:
	_rain_watchdog_elapsed = 0.0
	_stop_audio(_rebuilt_rain_player, "Rain")


func _update_rain_audio_watchdog(delta: float) -> void:
	if _current_weather_key != "rain":
		_rain_watchdog_elapsed = 0.0
		return

	_rain_watchdog_elapsed += delta

	if _rain_watchdog_elapsed < 1.0:
		return

	_rain_watchdog_elapsed = 0.0

	if _rebuilt_rain_player == null or _rebuilt_rain_player.stream == null:
		return

	if _rebuilt_rain_player.playing:
		return

	_debug_print("Rain SFX watchdog restart")
	_play_rain_loop(true)


func _play_storm_loop() -> void:
	if _rebuilt_storm_player == null:
		_debug_print("Storm SFX PLAY skipped: rebuilt storm player is null")
		return

	_rebuilt_storm_player.volume_db = storm_loop_volume_db
	_play_loop(_rebuilt_storm_player, false, "Storm")


func _stop_storm_loop() -> void:
	_storm_watchdog_elapsed = 0.0
	_stop_audio(_rebuilt_storm_player, "Storm")


func _update_storm_audio_watchdog(delta: float) -> void:
	if _current_weather_key != "storm":
		_storm_watchdog_elapsed = 0.0
		return

	_storm_watchdog_elapsed += delta

	if _storm_watchdog_elapsed < 1.0:
		return

	_storm_watchdog_elapsed = 0.0

	if _rebuilt_storm_player == null or _rebuilt_storm_player.stream == null:
		return

	if _rebuilt_storm_player.playing:
		return

	_debug_print("Storm SFX watchdog restart")
	_play_storm_loop()


func _stop_audio(player: AudioStreamPlayer, debug_label: String = "") -> void:
	if player == null:
		return

	if player.playing:
		player.stop()

		if debug_label != "":
			_debug_print("%s SFX STOP" % debug_label)
		elif player == rain_audio:
			_debug_print("Rain SFX STOP")
		elif player == storm_audio or player == _rebuilt_storm_player:
			_debug_print("Storm SFX STOP")


func _verify_loop_playing(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	await get_tree().process_frame

	if player == null:
		return

	_debug_print("Weather SFX playing after frame: %s playing=%s" % [
		player.name,
		str(player.playing)
	])

	if player.playing:
		return

	if player == _rebuilt_rain_player and _current_weather_key == "rain":
		player.play(0.0)
		_debug_print("Rain SFX RETRY PLAY on WeatherRainLoopRebuiltPlayer")

	if player == _rebuilt_storm_player and _current_weather_key == "storm":
		player.play(0.0)
		_debug_print("Storm SFX RETRY PLAY on WeatherStormRainLoopRebuiltPlayer")


func _schedule_next_thunder() -> void:
	if thunder_timer == null:
		return

	if _current_weather_key != "storm":
		_stop_thunder_timer()
		return

	thunder_timer.wait_time = _rng.randf_range(thunder_min_delay, thunder_max_delay)
	thunder_timer.start()
	_debug_print("Thunder timer START")


func _stop_thunder_timer() -> void:
	if thunder_timer == null:
		return

	if thunder_timer.is_stopped():
		return

	thunder_timer.stop()
	_debug_print("Thunder timer STOP")


func _on_thunder_timer_timeout() -> void:
	if _current_weather_key != "storm":
		return

	if _thunder_runtime_player != null and _thunder_runtime_player.stream != null:
		_thunder_runtime_player.play(0.0)
		_debug_print("Thunder PLAY")

	_trigger_lightning_flash()
	_schedule_next_thunder()


func _configure_audio() -> void:
	rain_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	storm_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	thunder_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	thunder_timer.process_mode = Node.PROCESS_MODE_ALWAYS

	rain_audio.bus = SFX_BUS
	storm_audio.bus = SFX_BUS
	thunder_audio.bus = SFX_BUS
	rain_audio.volume_db = rain_loop_volume_db
	storm_audio.volume_db = storm_loop_volume_db
	thunder_audio.volume_db = thunder_volume_db

	if rain_audio.stream == null:
		rain_audio.stream = _load_stream(RAIN_LOOP_PATH, "rain_loop")

	if storm_audio.stream == null:
		storm_audio.stream = _load_stream(STORM_RAIN_LOOP_PATH, "storm_rain_loop")

	if thunder_audio.stream == null:
		thunder_audio.stream = _load_stream(THUNDER_PATH, "thunder")

	rain_audio.stream = _duplicate_stream(rain_audio.stream)
	storm_audio.stream = _duplicate_stream(storm_audio.stream)
	thunder_audio.stream = _duplicate_stream(thunder_audio.stream)
	_enable_looping(rain_audio.stream)
	_enable_looping(storm_audio.stream)
	_create_rebuilt_rain_audio_player()
	_create_rebuilt_storm_audio_player()
	_create_runtime_audio_players()
	_debug_loaded_stream(rain_audio, RAIN_LOOP_PATH)
	_debug_loaded_stream(storm_audio, STORM_RAIN_LOOP_PATH)
	_debug_loaded_stream(thunder_audio, THUNDER_PATH)

	if _rebuilt_rain_player != null and not _rebuilt_rain_player.finished.is_connected(_on_rebuilt_rain_audio_finished):
		_rebuilt_rain_player.finished.connect(_on_rebuilt_rain_audio_finished)

	if _rebuilt_storm_player != null and not _rebuilt_storm_player.finished.is_connected(_on_rebuilt_storm_audio_finished):
		_rebuilt_storm_player.finished.connect(_on_rebuilt_storm_audio_finished)

	if not thunder_timer.timeout.is_connected(_on_thunder_timer_timeout):
		thunder_timer.timeout.connect(_on_thunder_timer_timeout)


func _load_stream(path: String, label: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("WeatherEffectsController: Missing %s audio file at %s." % [label, path])
		return null

	var stream := load(path) as AudioStream

	if stream == null:
		push_warning("WeatherEffectsController: Failed to load %s audio file at %s." % [label, path])

	return stream


func _enable_looping(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav_stream := stream as AudioStreamWAV
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD


func _disable_looping(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav_stream := stream as AudioStreamWAV
		wav_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED


func _duplicate_stream(stream: AudioStream) -> AudioStream:
	if stream == null:
		return null

	return stream.duplicate(true) as AudioStream


func _create_runtime_audio_players() -> void:
	_thunder_runtime_player = _create_runtime_audio_player(
		"WeatherThunderRuntimePlayer",
		thunder_audio.stream,
		thunder_volume_db
	)


func _create_rebuilt_rain_audio_player() -> void:
	var rain_stream := _load_stream(RAIN_LOOP_PATH, "rebuilt_rain_loop")

	if rain_stream == null and rain_loop_fallback_to_storm_stream:
		rain_stream = _load_stream(STORM_RAIN_LOOP_PATH, "rebuilt_rain_loop_fallback")
		_debug_print("Rain SFX rebuilt fallback uses storm_rain_loop stream")

	rain_stream = _duplicate_stream(rain_stream)

	if rain_loop_manual_restart:
		_disable_looping(rain_stream)
		_debug_print("Rain SFX rebuilt player uses manual restart loop")
	else:
		_enable_looping(rain_stream)

	_rebuilt_rain_player = AudioStreamPlayer.new()
	_rebuilt_rain_player.name = "WeatherRainLoopRebuiltPlayer"
	_rebuilt_rain_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_rebuilt_rain_player.bus = SFX_BUS
	_rebuilt_rain_player.volume_db = rain_loop_volume_db
	_rebuilt_rain_player.stream = rain_stream
	get_tree().root.add_child(_rebuilt_rain_player)

	_debug_print("Rain SFX rebuilt player created: %s bus=%s volume_db=%.2f stream=%s" % [
		_rebuilt_rain_player.name,
		_rebuilt_rain_player.bus,
		_rebuilt_rain_player.volume_db,
		str(_rebuilt_rain_player.stream)
	])


func _create_rebuilt_storm_audio_player() -> void:
	var storm_stream := _load_stream(STORM_RAIN_LOOP_PATH, "rebuilt_storm_rain_loop")
	storm_stream = _duplicate_stream(storm_stream)

	if storm_loop_manual_restart:
		_disable_looping(storm_stream)
		_debug_print("Storm SFX rebuilt player uses manual restart loop")
	else:
		_enable_looping(storm_stream)

	_rebuilt_storm_player = AudioStreamPlayer.new()
	_rebuilt_storm_player.name = "WeatherStormRainLoopRebuiltPlayer"
	_rebuilt_storm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_rebuilt_storm_player.bus = SFX_BUS
	_rebuilt_storm_player.volume_db = storm_loop_volume_db
	_rebuilt_storm_player.stream = storm_stream
	get_tree().root.add_child(_rebuilt_storm_player)

	_debug_print("Storm SFX rebuilt player created: %s bus=%s volume_db=%.2f stream=%s" % [
		_rebuilt_storm_player.name,
		_rebuilt_storm_player.bus,
		_rebuilt_storm_player.volume_db,
		str(_rebuilt_storm_player.stream)
	])


func _create_runtime_audio_player(
	player_name: String,
	stream: AudioStream,
	volume_db: float
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = SFX_BUS
	player.volume_db = volume_db
	player.stream = stream
	get_tree().root.add_child(player)
	_debug_print("Weather runtime audio player created: %s bus=%s volume_db=%.2f stream=%s" % [
		player.name,
		player.bus,
		player.volume_db,
		str(player.stream)
	])
	return player


func _create_lightning_flash() -> void:
	_lightning_flash = OmniLight3D.new()
	_lightning_flash.name = "WeatherLightningFlash"
	_lightning_flash.visible = false
	_lightning_flash.light_energy = lightning_flash_energy
	_lightning_flash.light_color = Color(0.72, 0.83, 1.0, 1.0)
	_lightning_flash.omni_range = 95.0
	_lightning_flash.shadow_enabled = false
	add_child(_lightning_flash)

	_lightning_flash_canvas = CanvasLayer.new()
	_lightning_flash_canvas.name = "WeatherLightningFlashCanvas"
	_lightning_flash_canvas.layer = 80
	_lightning_flash_canvas.visible = false
	_lightning_flash_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_lightning_flash_canvas)

	_lightning_flash_overlay = ColorRect.new()
	_lightning_flash_overlay.name = "WeatherLightningFlashOverlay"
	_lightning_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lightning_flash_overlay.anchor_right = 1.0
	_lightning_flash_overlay.anchor_bottom = 1.0
	_lightning_flash_overlay.offset_left = 0.0
	_lightning_flash_overlay.offset_top = 0.0
	_lightning_flash_overlay.offset_right = 0.0
	_lightning_flash_overlay.offset_bottom = 0.0
	_lightning_flash_overlay.color = Color(0.72, 0.83, 1.0, 0.0)
	_lightning_flash_canvas.add_child(_lightning_flash_overlay)

	_lightning_flash_timer = Timer.new()
	_lightning_flash_timer.name = "WeatherLightningFlashTimer"
	_lightning_flash_timer.one_shot = true
	_lightning_flash_timer.wait_time = lightning_flash_duration
	_lightning_flash_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_lightning_flash_timer)

	if not _lightning_flash_timer.timeout.is_connected(_on_lightning_flash_timeout):
		_lightning_flash_timer.timeout.connect(_on_lightning_flash_timeout)


func _trigger_lightning_flash() -> void:
	if not lightning_flash_enabled:
		return

	if _current_weather_key != "storm":
		return

	if _lightning_flash == null or _lightning_flash_timer == null:
		return

	_lightning_flash.global_position = global_position + Vector3(0.0, 10.0, 0.0)
	_lightning_flash.light_energy = lightning_flash_energy
	_lightning_flash.visible = true

	if _lightning_flash_canvas != null:
		_lightning_flash_canvas.visible = true

	if _lightning_flash_overlay != null:
		_lightning_flash_overlay.color = Color(0.72, 0.83, 1.0, lightning_screen_flash_alpha)

	_lightning_flash_timer.start(lightning_flash_duration)
	_debug_print("Lightning flash ON")


func _on_lightning_flash_timeout() -> void:
	if _lightning_flash != null:
		_lightning_flash.visible = false

	if _lightning_flash_overlay != null:
		_lightning_flash_overlay.color = Color(0.72, 0.83, 1.0, 0.0)

	if _lightning_flash_canvas != null:
		_lightning_flash_canvas.visible = false

	_debug_print("Lightning flash OFF")


func _free_runtime_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.queue_free()


func _on_rebuilt_rain_audio_finished() -> void:
	if _current_weather_key == "rain" and _rebuilt_rain_player != null:
		_rebuilt_rain_player.volume_db = rain_loop_volume_db
		_rebuilt_rain_player.play(0.0)


func _on_rebuilt_storm_audio_finished() -> void:
	if _current_weather_key == "storm" and _rebuilt_storm_player != null:
		_rebuilt_storm_player.volume_db = storm_loop_volume_db
		_rebuilt_storm_player.play(0.0)


func _get_weather_key(weather_value: Variant) -> String:
	if weather_value == null:
		return "sunny"

	if weather_value is WeatherData:
		var weather_data := weather_value as WeatherData

		match weather_data.weather_type:
			WeatherData.WeatherType.SUNNY:
				return "sunny"
			WeatherData.WeatherType.CLOUDY:
				return "cloudy"
			WeatherData.WeatherType.RAIN:
				return "rain"
			WeatherData.WeatherType.STORM:
				return "storm"

		var data_key := _normalize_weather_text(weather_data.display_name)
		if data_key != "":
			return data_key

		data_key = _normalize_weather_text(weather_data.resource_path)
		if data_key != "":
			return data_key

	if weather_value is String:
		var string_key := _normalize_weather_text(weather_value)
		if string_key != "":
			return string_key

	if weather_value is StringName:
		var string_name_key := _normalize_weather_text(String(weather_value))
		if string_name_key != "":
			return string_name_key

	if weather_value is Resource:
		var resource_key := _normalize_weather_text((weather_value as Resource).resource_path)
		if resource_key != "":
			return resource_key

	var fallback_key := _normalize_weather_text(str(weather_value))
	if fallback_key != "":
		return fallback_key

	if not _unknown_weather_warning_printed:
		_unknown_weather_warning_printed = true
		push_warning("WeatherEffectsController: Unknown weather value %s. Disabling precipitation." % str(weather_value))

	return "sunny"


func _normalize_weather_text(raw_value: String) -> String:
	var text := raw_value.strip_edges().to_lower()

	if text == "":
		return ""

	if text.find("storm") != -1:
		return "storm"

	if text.find("rain") != -1:
		return "rain"

	if text.find("cloud") != -1:
		return "cloudy"

	if text.find("sun") != -1:
		return "sunny"

	return ""


func _describe_weather_value(weather_value: Variant) -> String:
	if weather_value == null:
		return "<null>"

	if weather_value is WeatherData:
		var weather_data := weather_value as WeatherData
		return "%s type=%s path=%s" % [
			weather_data.display_name,
			str(weather_data.weather_type),
			weather_data.resource_path
		]

	return str(weather_value)


func _debug_print(message: String) -> void:
	if not debug_weather_effects:
		return

	print(message)


func _debug_loaded_stream(player: AudioStreamPlayer, path: String) -> void:
	if not debug_weather_effects:
		return

	if player == null:
		print("Weather SFX stream missing player for %s" % path)
		return

	if player.stream == null:
		print("Weather SFX stream missing: %s" % path)
		return

	print("Weather SFX stream loaded: %s length=%.2f bus=%s" % [
		path,
		player.stream.get_length(),
		player.bus
	])


func _debug_audio_state(player: AudioStreamPlayer) -> void:
	if not debug_weather_effects:
		return

	var bus_index := AudioServer.get_bus_index(player.bus)
	var bus_state := "missing"

	if bus_index != -1:
		bus_state = "mute=%s db=%.2f" % [
			str(AudioServer.is_bus_mute(bus_index)),
			AudioServer.get_bus_volume_db(bus_index)
		]

	print("Weather SFX play request: %s stream=%s bus=%s %s volume_db=%.2f" % [
		player.name,
		str(player.stream),
		player.bus,
		bus_state,
		player.volume_db
	])


func _configure_particles() -> void:
	_configure_rain_particles(rain_particles, rain_amount, 18.0, 34.0, 0.78)
	_configure_rain_particles(storm_particles, storm_amount, 24.0, 46.0, 0.9)
	_set_particles_active(rain_particles, false)
	_set_particles_active(storm_particles, false)


func _configure_rain_particles(
	particles: GPUParticles3D,
	amount: int,
	min_speed: float,
	max_speed: float,
	alpha: float
) -> void:
	if particles == null:
		return

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(18.0, 0.5, 18.0)
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 8.0
	material.gravity = Vector3(0.0, -34.0, 0.0)
	material.initial_velocity_min = min_speed
	material.initial_velocity_max = max_speed
	material.scale_min = 0.55
	material.scale_max = 1.0

	var drop_material := StandardMaterial3D.new()
	drop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_material.albedo_color = Color(0.65, 0.82, 1.0, alpha)

	var drop_mesh := BoxMesh.new()
	drop_mesh.size = Vector3(0.018, 0.42, 0.018)
	drop_mesh.material = drop_material

	particles.amount = amount
	particles.lifetime = 0.72
	particles.preprocess = 0.72
	particles.visibility_aabb = AABB(Vector3(-22.0, -18.0, -22.0), Vector3(44.0, 26.0, 44.0))
	particles.process_material = material
	particles.draw_pass_1 = drop_mesh
