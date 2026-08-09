extends Node

signal audio_settings_changed

const CONFIG_PATH := "user://settings.cfg"
const CONFIG_SECTION := "audio"
const MIN_VOLUME_DB := -80.0

const MASTER_BUS := "Master"
const SFX_BUS := "SFX"
const NOTIFICATIONS_BUS := "Notifications"
const MUSIC_BUS := "Music"

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var notifications_volume: float = 1.0
var music_volume: float = 0.8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_audio_buses()
	load_settings()
	apply_settings()


func set_master_volume(value: float) -> void:
	master_volume = _clamp_volume(value)
	save_settings()
	apply_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = _clamp_volume(value)
	save_settings()
	apply_settings()


func set_notifications_volume(value: float) -> void:
	notifications_volume = _clamp_volume(value)
	save_settings()
	apply_settings()


func set_music_volume(value: float) -> void:
	music_volume = _clamp_volume(value)
	save_settings()
	apply_settings()


func apply_settings() -> void:
	ensure_audio_buses()
	_apply_bus_volume(MASTER_BUS, master_volume)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	_apply_bus_volume(NOTIFICATIONS_BUS, notifications_volume)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	audio_settings_changed.emit()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value(CONFIG_SECTION, "master_volume", master_volume)
	config.set_value(CONFIG_SECTION, "sfx_volume", sfx_volume)
	config.set_value(CONFIG_SECTION, "notifications_volume", notifications_volume)
	config.set_value(CONFIG_SECTION, "music_volume", music_volume)
	config.save(CONFIG_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)

	if error != OK:
		return

	master_volume = _read_volume(config, "master_volume", master_volume)
	sfx_volume = _read_volume(config, "sfx_volume", sfx_volume)
	notifications_volume = _read_volume(config, "notifications_volume", notifications_volume)
	music_volume = _read_volume(config, "music_volume", music_volume)


func ensure_audio_buses() -> void:
	_ensure_bus(SFX_BUS)
	_ensure_bus(NOTIFICATIONS_BUS)
	_ensure_bus(MUSIC_BUS)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus(AudioServer.get_bus_count())
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, MASTER_BUS)


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	var clamped_value := _clamp_volume(value)
	var should_mute := clamped_value <= 0.0

	AudioServer.set_bus_mute(bus_index, should_mute)
	AudioServer.set_bus_volume_db(bus_index, MIN_VOLUME_DB if should_mute else linear_to_db(clamped_value))


func _read_volume(config: ConfigFile, key: String, default_value: float) -> float:
	var value: Variant = config.get_value(CONFIG_SECTION, key, default_value)

	if value is float or value is int:
		return _clamp_volume(float(value))

	if value is String and String(value).is_valid_float():
		return _clamp_volume(float(String(value)))

	return _clamp_volume(default_value)


func _clamp_volume(value: float) -> float:
	return clampf(value, 0.0, 1.0)
