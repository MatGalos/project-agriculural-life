extends RefCounted

var runner: TestRunner

const WEATHER_PANEL_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/WeatherApp/weather_panel.tscn")
const FORECAST_ROW_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/WeatherApp/weather_forecast_row.tscn")


func run() -> void:
	print("\n--- WeatherAppLayoutTest ---")

	var panel := WEATHER_PANEL_SCENE.instantiate() as Control
	runner.assert_true(panel != null, "Weather app scene instantiates")

	if panel:
		_assert_weather_panel_layout(panel)
		_assert_weather_safe_insets(panel)
		_assert_no_hourly_forecast_text(panel)
		_assert_forecast_date_labels(panel)
		panel.free()

	var row := FORECAST_ROW_SCENE.instantiate() as PanelContainer
	runner.assert_true(row != null, "Weather forecast row scene instantiates")

	if row:
		_assert_forecast_row_layout(row)
		row.free()


func _assert_weather_panel_layout(panel: Control) -> void:
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll") is ScrollContainer, "Weather app uses scroll container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll/Content/TodayCard") is PanelContainer, "Weather app has Today card")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll/Content/TodayCard/TodayMargin/TodayRow/TodayIconAnchor") is Control, "Today card has weather icon anchor")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll/Content/DayPartsGrid") is GridContainer, "Weather app has Day Parts grid")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll/Content/ForecastContainer") is VBoxContainer, "Weather app has Next Days container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll/Content/StateLabel") is Label, "Weather app has unavailable state label")

	var day_parts_grid := panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll/Content/DayPartsGrid") as GridContainer
	runner.assert_true(day_parts_grid != null and day_parts_grid.columns == 2, "Day Parts grid uses 2 columns for four phase cards")

	var state_label := panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll/Content/StateLabel") as Label
	runner.assert_true(state_label != null and state_label.text == "Weather data unavailable.", "Weather app has user-facing weather unavailable text")


func _assert_weather_safe_insets(panel: Control) -> void:
	var margin := panel.get_node_or_null("PanelContainer/MarginContainer") as MarginContainer
	runner.assert_true(margin != null, "Weather app has outer content margin")

	if margin:
		runner.assert_true(margin.get_theme_constant("margin_left") >= 30, "Weather app keeps safe left inset inside FarmPhone screen")
		runner.assert_true(margin.get_theme_constant("margin_right") <= 6, "Weather app preserves right-side space after left inset correction")

	var today_icon_anchor := panel.get_node_or_null("PanelContainer/MarginContainer/ContentScroll/Content/TodayCard/TodayMargin/TodayRow/TodayIconAnchor") as Control
	runner.assert_true(today_icon_anchor != null and today_icon_anchor.custom_minimum_size.x <= 60.0, "Today icon anchor stays compact enough for phone width")


func _assert_forecast_row_layout(row: PanelContainer) -> void:
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/DayLabel") is Label, "Forecast row has day label")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/WeatherIcon") is WeatherIcon, "Forecast row has drawn weather icon")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/WeatherLabel") is Label, "Forecast row has weather label")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/TemperatureLabel") is Label, "Forecast row has temperature label")
	runner.assert_true(row.get_node_or_null("MarginContainer/Row/RainLabel") is Label, "Forecast row has rain chance label")
	_assert_forecast_row_width_budget(row)


func _assert_forecast_row_width_budget(row: PanelContainer) -> void:
	var day_label := row.get_node_or_null("MarginContainer/Row/DayLabel") as Label
	var weather_icon := row.get_node_or_null("MarginContainer/Row/WeatherIcon") as Control
	var weather_label := row.get_node_or_null("MarginContainer/Row/WeatherLabel") as Label
	var temperature_label := row.get_node_or_null("MarginContainer/Row/TemperatureLabel") as Label
	var rain_label := row.get_node_or_null("MarginContainer/Row/RainLabel") as Label

	runner.assert_true(day_label != null and day_label.custom_minimum_size.x <= 72.0, "Forecast season date label width fits phone screen")
	runner.assert_true(weather_icon != null and weather_icon.custom_minimum_size.x <= 30.0, "Forecast weather icon width fits phone screen")
	runner.assert_true(weather_label != null and weather_label.custom_minimum_size.x <= 42.0, "Forecast weather label width fits phone screen")
	runner.assert_true(temperature_label != null and temperature_label.custom_minimum_size.x <= 38.0, "Forecast temperature label width fits phone screen")
	runner.assert_true(rain_label != null and rain_label.custom_minimum_size.x <= 52.0, "Forecast rain label width fits phone screen")


func _assert_forecast_date_labels(panel: Control) -> void:
	var weather_panel := panel as WeatherPanel
	runner.assert_true(weather_panel != null, "Weather forecast panel script is available")

	if weather_panel == null:
		return

	var previous_day := TimeManager.current_day
	var previous_month := TimeManager.current_month

	TimeManager.current_day = 5
	TimeManager.current_month = 1
	runner.assert_eq(weather_panel._get_forecast_date_label(2), "7th Spring", "Weather forecast uses season date labels")

	TimeManager.current_day = 29
	TimeManager.current_month = 1
	runner.assert_eq(weather_panel._get_forecast_date_label(2), "1st Summer", "Weather forecast season date labels wrap seasons")

	TimeManager.current_day = previous_day
	TimeManager.current_month = previous_month


func _assert_no_hourly_forecast_text(panel: Control) -> void:
	var labels: Array[String] = []
	_collect_label_text(panel, labels)

	for text in labels:
		var normalized := text.to_lower()
		runner.assert_true(not normalized.contains("hourly"), "Weather app static text does not add hourly forecast")
		runner.assert_true(not normalized.contains(" am"), "Weather app static text does not add AM forecast rows")
		runner.assert_true(not normalized.contains(" pm"), "Weather app static text does not add PM forecast rows")


func _collect_label_text(node: Node, labels: Array[String]) -> void:
	if node is Label:
		labels.append((node as Label).text)

	for child in node.get_children():
		_collect_label_text(child, labels)
