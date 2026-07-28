extends Control
class_name WeatherPanel

@export var row_scene: PackedScene

const CARD_BG := Color(0.045, 0.052, 0.064, 0.96)
const CARD_BORDER := Color(0.13, 0.16, 0.20, 1.0)
const PHASE_COLORS := {
	"Dawn": Color(0.12, 0.14, 0.20, 0.96),
	"Morning": Color(0.10, 0.15, 0.17, 0.96),
	"Afternoon": Color(0.13, 0.12, 0.17, 0.96),
	"Night": Color(0.06, 0.07, 0.12, 0.98)
}

@onready var state_label: Label = $PanelContainer/MarginContainer/ContentScroll/Content/StateLabel
@onready var today_card: PanelContainer = $PanelContainer/MarginContainer/ContentScroll/Content/TodayCard
@onready var today_icon_anchor: Control = $PanelContainer/MarginContainer/ContentScroll/Content/TodayCard/TodayMargin/TodayRow/TodayIconAnchor
@onready var today_weather_label: Label = $PanelContainer/MarginContainer/ContentScroll/Content/TodayCard/TodayMargin/TodayRow/TodayInfo/TodayWeatherLabel
@onready var today_current_label: Label = $PanelContainer/MarginContainer/ContentScroll/Content/TodayCard/TodayMargin/TodayRow/TodayInfo/TodayCurrentLabel
@onready var today_rain_label: Label = $PanelContainer/MarginContainer/ContentScroll/Content/TodayCard/TodayMargin/TodayRow/TodayInfo/TodayRainLabel
@onready var day_parts_title: Label = $PanelContainer/MarginContainer/ContentScroll/Content/DayPartsTitle
@onready var day_parts_grid: GridContainer = $PanelContainer/MarginContainer/ContentScroll/Content/DayPartsGrid
@onready var next_days_title: Label = $PanelContainer/MarginContainer/ContentScroll/Content/NextDaysTitle
@onready var forecast_container: VBoxContainer = $PanelContainer/MarginContainer/ContentScroll/Content/ForecastContainer

var _today_icon: WeatherIcon


func _ready() -> void:
	visible = false
	_apply_typography()
	_setup_today_icon()

	if not WeatherManager.weather_changed.is_connected(_on_weather_changed):
		WeatherManager.weather_changed.connect(_on_weather_changed)

	refresh()


func _on_weather_changed(_current_weather: WeatherData, _temperature: int) -> void:
	refresh()


func refresh() -> void:
	if not _update_today():
		return

	_update_day_parts()
	_update_forecast()


func _apply_typography() -> void:
	_set_label_style(state_label, 13, Color(0.82, 0.85, 0.90, 1.0))
	_set_label_style(today_weather_label, 20, Color(0.97, 0.98, 1.0, 1.0))
	_set_label_style(today_current_label, 13, Color(0.86, 0.89, 0.94, 1.0))
	_set_label_style(today_rain_label, 12, Color(0.74, 0.80, 0.88, 1.0))


func _setup_today_icon() -> void:
	_today_icon = WeatherIcon.new()
	_today_icon.custom_minimum_size = Vector2(60.0, 60.0)
	_today_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_today_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	today_icon_anchor.add_child(_today_icon)


func _update_today() -> bool:
	var current_weather := WeatherManager.current_weather
	var current_phase := WeatherManager.get_current_phase_weather()

	if current_weather == null:
		_show_weather_unavailable()
		return false

	state_label.visible = false
	today_card.visible = true

	var day_name := UIFormatHelper.display_weather_name(WeatherManager.get_current_day_pattern_name())
	var current_name := UIFormatHelper.display_weather_name(current_weather)
	var rain_chance := _get_current_rain_chance(current_phase)

	today_weather_label.text = day_name
	today_current_label.text = "Current: %s, %s" % [
		current_name,
		WeatherManager.get_current_temperature_string()
	]
	today_rain_label.text = "Rain: %d%%" % rain_chance
	_today_icon.setup(current_name)
	return true


func _show_weather_unavailable() -> void:
	state_label.text = "Weather data unavailable."
	state_label.visible = true
	today_card.visible = false
	day_parts_title.visible = false
	day_parts_grid.visible = false
	next_days_title.visible = false
	forecast_container.visible = false


func _update_day_parts() -> void:
	_clear_container(day_parts_grid)

	var phases := WeatherManager.get_today_phase_forecast()
	day_parts_title.visible = true
	day_parts_grid.visible = true

	if phases.is_empty():
		var unavailable := Label.new()
		unavailable.text = "Weather data unavailable."
		_set_label_style(unavailable, 13, Color(0.82, 0.85, 0.90, 1.0))
		day_parts_grid.add_child(unavailable)
		return

	for phase_data in phases:
		day_parts_grid.add_child(_create_phase_card(phase_data))


func _create_phase_card(phase_data: WeatherPhaseData) -> PanelContainer:
	var phase_name := _get_phase_name(phase_data)
	var weather_name := _get_phase_weather_name(phase_data)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(112.0, 110.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg_color: Color = PHASE_COLORS.get(phase_name, CARD_BG)
	card.add_theme_stylebox_override("panel", _make_card_style(bg_color))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)

	var title := Label.new()
	title.text = phase_name
	_set_label_style(title, 13, Color(0.95, 0.96, 0.98, 1.0), true)
	content.add_child(title)

	var icon := WeatherIcon.new()
	icon.custom_minimum_size = Vector2(34.0, 34.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.setup(weather_name)
	content.add_child(icon)

	var temperature := Label.new()
	temperature.text = "%d°C" % _get_phase_temperature(phase_data)
	temperature.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_label_style(temperature, 17, Color(0.98, 0.99, 1.0, 1.0), true)
	content.add_child(temperature)

	var rain := Label.new()
	rain.text = "Rain: %d%%" % _get_phase_rain_chance(phase_data)
	rain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_label_style(rain, 11, Color(0.76, 0.82, 0.90, 1.0))
	content.add_child(rain)

	return card


func _update_forecast() -> void:
	_clear_container(forecast_container)

	var forecast := WeatherManager.get_forecast()
	next_days_title.visible = true
	forecast_container.visible = true

	if forecast.is_empty():
		var unavailable := Label.new()
		unavailable.text = "Forecast unavailable."
		_set_label_style(unavailable, 13, Color(0.82, 0.85, 0.90, 1.0))
		forecast_container.add_child(unavailable)
		return

	if row_scene == null:
		var unavailable := Label.new()
		unavailable.text = "Forecast unavailable."
		_set_label_style(unavailable, 13, Color(0.82, 0.85, 0.90, 1.0))
		forecast_container.add_child(unavailable)
		return

	for i in range(forecast.size()):
		var entry := forecast[i]
		var row := row_scene.instantiate() as WeatherForecastRow

		if row == null:
			continue

		forecast_container.add_child(row)

		var weather := entry.get("weather", null) as WeatherData
		var temperature := int(entry.get("temperature", 0))
		var pattern := entry.get("pattern", null) as WeatherDayPatternData
		var rain_chance := int(entry.get("rain_chance", 0))

		row.setup(i + 1, weather, temperature, pattern, rain_chance)


func _get_current_rain_chance(current_phase: WeatherPhaseData) -> int:
	if current_phase != null:
		return current_phase.rain_chance

	for phase_data in WeatherManager.get_today_phase_forecast():
		if phase_data != null and phase_data.phase == WeatherManager.current_day_phase:
			return phase_data.rain_chance

	return 0


func _get_phase_name(phase_data: WeatherPhaseData) -> String:
	if phase_data == null:
		return "Unknown"

	return WeatherManager.get_day_phase_name(phase_data.phase)


func _get_phase_weather_name(phase_data: WeatherPhaseData) -> String:
	if phase_data == null or phase_data.weather == null:
		return "Unknown"

	return UIFormatHelper.display_weather_name(phase_data.weather)


func _get_phase_temperature(phase_data: WeatherPhaseData) -> int:
	if phase_data == null:
		return 0

	return phase_data.temperature


func _get_phase_rain_chance(phase_data: WeatherPhaseData) -> int:
	if phase_data == null:
		return 0

	return phase_data.rain_chance


func _make_card_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = CARD_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style


func _set_label_style(label: Label, font_size: int, font_color: Color, bold := false) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	if bold:
		label.theme_type_variation = &"HeaderLabel"


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
