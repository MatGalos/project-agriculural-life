extends Control

const SLIDER_MIN := 0.0
const SLIDER_MAX := 100.0
const SLIDER_STEP := 1.0

const TRACK_HEIGHT := 10
const KNOB_SIZE := 24
const TRACK_COLOR := Color(0.31, 0.16, 0.06, 0.88)
const TRACK_BORDER_COLOR := Color(0.17, 0.08, 0.025, 1.0)
const FILL_COLOR := Color(0.94, 0.66, 0.30, 0.96)
const FILL_HIGHLIGHT_COLOR := Color(1.0, 0.78, 0.40, 1.0)
const KNOB_COLOR := Color(0.99, 0.87, 0.58, 1.0)
const KNOB_OUTLINE_COLOR := Color(0.19, 0.09, 0.025, 1.0)

var _sliders: Dictionary = {}
var _value_labels: Dictionary = {}
var _is_loading_values: bool = false
var _knob_texture: Texture2D
var _knob_highlight_texture: Texture2D


func _ready() -> void:
	_knob_texture = _create_knob_texture(KNOB_COLOR)
	_knob_highlight_texture = _create_knob_texture(FILL_HIGHLIGHT_COLOR)
	_build_audio_options()
	_load_values_from_settings()


func _build_audio_options() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	add_child(margin)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	list.add_theme_constant_override("separation", 18)
	margin.add_child(list)

	_add_volume_row(list, "master_volume", "Master Volume")
	_add_volume_row(list, "sfx_volume", "SFX Volume")
	_add_volume_row(list, "notifications_volume", "Notifications Volume")
	_add_volume_row(list, "music_volume", "Music Volume")


func _add_volume_row(parent: VBoxContainer, setting_key: String, label_text: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var label := Label.new()
	label.custom_minimum_size = Vector2(210, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 20)
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(320, 28)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = SLIDER_MIN
	slider.max_value = SLIDER_MAX
	slider.step = SLIDER_STEP
	slider.tick_count = 0
	_apply_slider_style(slider)
	slider.value_changed.connect(_on_slider_value_changed.bind(setting_key))
	row.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(56, 0)
	value_label.add_theme_color_override("font_color", Color.BLACK)
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)

	_sliders[setting_key] = slider
	_value_labels[setting_key] = value_label


func _load_values_from_settings() -> void:
	_is_loading_values = true
	_set_slider_value("master_volume", AudioSettingsManager.master_volume)
	_set_slider_value("sfx_volume", AudioSettingsManager.sfx_volume)
	_set_slider_value("notifications_volume", AudioSettingsManager.notifications_volume)
	_set_slider_value("music_volume", AudioSettingsManager.music_volume)
	_is_loading_values = false


func _set_slider_value(setting_key: String, volume: float) -> void:
	var slider := _sliders.get(setting_key, null) as HSlider

	if slider == null:
		return

	slider.value = round(clampf(volume, 0.0, 1.0) * 100.0)
	_update_value_label(setting_key, slider.value)


func _on_slider_value_changed(value: float, setting_key: String) -> void:
	_update_value_label(setting_key, value)

	if _is_loading_values:
		return

	var volume := clampf(value / 100.0, 0.0, 1.0)

	match setting_key:
		"master_volume":
			AudioSettingsManager.set_master_volume(volume)
		"sfx_volume":
			AudioSettingsManager.set_sfx_volume(volume)
		"notifications_volume":
			AudioSettingsManager.set_notifications_volume(volume)
		"music_volume":
			AudioSettingsManager.set_music_volume(volume)


func _update_value_label(setting_key: String, value: float) -> void:
	var value_label := _value_labels.get(setting_key, null) as Label

	if value_label == null:
		return

	value_label.text = "%d%%" % int(round(value))


func _apply_slider_style(slider: HSlider) -> void:
	slider.add_theme_stylebox_override("slider", _create_track_style(TRACK_COLOR))
	slider.add_theme_stylebox_override("grabber_area", _create_track_style(FILL_COLOR))
	slider.add_theme_stylebox_override("grabber_area_highlight", _create_track_style(FILL_HIGHLIGHT_COLOR))
	slider.add_theme_icon_override("grabber", _knob_texture)
	slider.add_theme_icon_override("grabber_highlight", _knob_highlight_texture)
	slider.add_theme_icon_override("grabber_disabled", _knob_texture)


func _create_track_style(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = TRACK_BORDER_COLOR
	style.set_border_width_all(2)
	style.corner_radius_top_left = TRACK_HEIGHT / 2
	style.corner_radius_top_right = TRACK_HEIGHT / 2
	style.corner_radius_bottom_left = TRACK_HEIGHT / 2
	style.corner_radius_bottom_right = TRACK_HEIGHT / 2
	style.content_margin_top = TRACK_HEIGHT
	style.content_margin_bottom = TRACK_HEIGHT
	return style


func _create_knob_texture(fill_color: Color) -> Texture2D:
	var image := Image.create_empty(KNOB_SIZE, KNOB_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center := Vector2((KNOB_SIZE - 1) * 0.5, (KNOB_SIZE - 1) * 0.5)
	var outer_radius := float(KNOB_SIZE) * 0.48
	var inner_radius := float(KNOB_SIZE) * 0.34
	var shine_radius := float(KNOB_SIZE) * 0.13
	var shine_center := center + Vector2(-4.0, -4.0)

	for x in range(KNOB_SIZE):
		for y in range(KNOB_SIZE):
			var point := Vector2(x, y)
			var distance := point.distance_to(center)

			if distance <= outer_radius:
				image.set_pixel(x, y, KNOB_OUTLINE_COLOR)

			if distance <= inner_radius:
				image.set_pixel(x, y, fill_color)

			if point.distance_to(shine_center) <= shine_radius:
				image.set_pixel(x, y, Color(1.0, 0.94, 0.74, 0.95))

	return ImageTexture.create_from_image(image)
