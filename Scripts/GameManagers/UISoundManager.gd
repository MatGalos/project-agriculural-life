extends Node

const SFX_BUS := "SFX"
const NOTIFICATIONS_BUS_FALLBACK := "Notifications"
const NOTIFICATION_BUS_FALLBACK := "Notification"
const PLAYER_POOL_SIZE := 6
const NOTIFICATION_COOLDOWN_SECONDS := 0.18

const UI_CLICK_PATH := "res://Assets/Audio/UI/ui_click.wav"
const UI_PHONE_OPEN_PATH := "res://Assets/Audio/UI/ui_phone_open.wav"
const UI_PHONE_CLOSE_PATH := "res://Assets/Audio/UI/ui_phone_close.wav"
const UI_APP_SWITCH_PATH := "res://Assets/Audio/UI/ui_app_switch.wav"
const NOTIFICATION_NEW_PATH := "res://Assets/Audio/Notifications/notification_new.wav"

@export var ui_click_stream: AudioStream
@export var ui_phone_open_stream: AudioStream
@export var ui_phone_close_stream: AudioStream
@export var ui_app_switch_stream: AudioStream
@export var notification_new_stream: AudioStream

var _players: Array[AudioStreamPlayer] = []
var _last_notification_msec := -1000000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_audio_streams()
	_create_player_pool()


func play_ui_click() -> void:
	_play_stream(ui_click_stream, SFX_BUS)


func play_phone_open() -> void:
	_play_stream(ui_phone_open_stream, SFX_BUS)


func play_phone_close() -> void:
	_play_stream(ui_phone_close_stream, SFX_BUS)


func play_phone_app_switch() -> void:
	_play_stream(ui_app_switch_stream, SFX_BUS)


func play_notification() -> void:
	play_notification_new()


func play_notification_new() -> void:
	var now_msec := Time.get_ticks_msec()

	if now_msec - _last_notification_msec < int(NOTIFICATION_COOLDOWN_SECONDS * 1000.0):
		return

	_last_notification_msec = now_msec
	_play_stream(notification_new_stream, _get_notification_bus_name())


func _load_audio_streams() -> void:
	if ui_click_stream == null:
		ui_click_stream = _load_stream(UI_CLICK_PATH, "ui_click")

	if ui_phone_open_stream == null:
		ui_phone_open_stream = _load_stream(UI_PHONE_OPEN_PATH, "ui_phone_open")

	if ui_phone_close_stream == null:
		ui_phone_close_stream = _load_stream(UI_PHONE_CLOSE_PATH, "ui_phone_close")

	if ui_app_switch_stream == null:
		ui_app_switch_stream = _load_stream(UI_APP_SWITCH_PATH, "ui_app_switch")

	if notification_new_stream == null:
		notification_new_stream = _load_stream(NOTIFICATION_NEW_PATH, "notification_new")


func _load_stream(path: String, label: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("UISoundManager: Missing %s audio file at %s. TODO: add the prepared placeholder WAV." % [label, path])
		return null

	var stream := load(path) as AudioStream

	if stream == null:
		push_warning("UISoundManager: Failed to load %s audio file at %s." % [label, path])

	return stream


func _create_player_pool() -> void:
	for _i in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)


func _play_stream(stream: AudioStream, bus_name: String) -> void:
	if stream == null:
		return

	var player := _get_available_player()
	player.stop()
	player.stream = stream
	player.bus = bus_name
	player.play()


func _get_available_player() -> AudioStreamPlayer:
	if _players.is_empty():
		_create_player_pool()

	for player in _players:
		if not player.playing:
			return player

	return _players[0]


func _get_notification_bus_name() -> String:
	if AudioServer.get_bus_index(NOTIFICATIONS_BUS_FALLBACK) != -1:
		return NOTIFICATIONS_BUS_FALLBACK

	if AudioServer.get_bus_index(NOTIFICATION_BUS_FALLBACK) != -1:
		return NOTIFICATION_BUS_FALLBACK

	return NOTIFICATIONS_BUS_FALLBACK
