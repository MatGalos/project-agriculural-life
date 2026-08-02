extends Control

const BASE_PHONE_SIZE := Vector2(380.0, 640.0)
const VIEWPORT_SAFE_MARGIN := Vector2(24.0, 24.0)
const MIN_RESPONSIVE_SCALE := 0.5

@onready var news_button: Button = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/HomeScreen/HomeGrid/NewsIcon/IconButton
@onready var exchange_button: Button = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/HomeScreen/HomeGrid/MarketIcon/IconButton
@onready var shop_button: Button = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/HomeScreen/HomeGrid/ShopIcon/IconButton
@onready var weather_button: Button = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/HomeScreen/HomeGrid/WeatherIcon/IconButton
@onready var sell_button: Button = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/HomeScreen/HomeGrid/SellIcon/IconButton
@onready var home_button: Button = $PhoneShell/ShellMargin/DeviceStack/HomeBezel/HomeButton
@onready var home_screen: Control = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/HomeScreen
@onready var app_container: Control = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/AppContainer
@onready var sell_app: Control = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/AppContainer/SellApp
@onready var shop_app: Control = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/AppContainer/ShopApp
@onready var exchange_app: Control = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/AppContainer/StockMarketApp
@onready var weather_app: Control = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/AppContainer/WeatherApp
@onready var news_app: Control = $PhoneShell/ShellMargin/DeviceStack/ScreenFrame/ScreenMargin/ScreenArea/AppContainer/NewsApp

func _ready() -> void:
	visible = false
	get_viewport().size_changed.connect(_apply_responsive_layout)

	if not GraphicsSettingsManager.interface_scale_changed.is_connected(_on_interface_scale_changed):
		GraphicsSettingsManager.interface_scale_changed.connect(_on_interface_scale_changed)

	news_button.pressed.connect(_on_news_pressed)
	exchange_button.pressed.connect(_on_exchange_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	weather_button.pressed.connect(_on_weather_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	home_button.pressed.connect(_on_home_pressed)
	visibility_changed.connect(_on_visibility_changed)
	add_to_group("phone_panel")
	_apply_responsive_layout()
	_show_home_screen()

func open() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_home_screen()

func close() -> void:
	visible = false

	if gamemanager.isInGame and not gamemanager.isPaused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func is_open() -> bool:
	return visible

func _show_home_screen() -> void:
	_hide_all_apps()
	app_container.visible = false
	home_screen.visible = true

func _on_sell_pressed() -> void:
	_show_app(sell_app)
	sell_app.refresh()

func _on_shop_pressed() -> void:
	_show_app(shop_app)
	shop_app.refresh()

func _hide_all_apps() -> void:
	for child in app_container.get_children():
		if child is Control:
			child.visible = false

func _show_app(app: Control) -> void:
	home_screen.visible = false
	app_container.visible = true
	_hide_all_apps()
	app.visible = true

func _on_exchange_pressed() -> void:
	_show_app(exchange_app)
	exchange_app.refresh()

func _on_weather_pressed() -> void:
	_show_app(weather_app)
	weather_app.refresh()

func _on_news_pressed() -> void:
	_show_app(news_app)
	news_app.refresh()

func _on_home_pressed() -> void:
	_show_home_screen()

func _on_visibility_changed() -> void:
	if visible:
		_apply_responsive_layout()
		_show_home_screen()


func _on_interface_scale_changed(_scale_multiplier: float) -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var interface_scale := maxf(GraphicsSettingsManager.get_interface_scale_multiplier(), 0.1)
	var available_size := (viewport_size / interface_scale) - (VIEWPORT_SAFE_MARGIN * 2.0)
	var fit_scale := minf(available_size.x / BASE_PHONE_SIZE.x, available_size.y / BASE_PHONE_SIZE.y)
	fit_scale = clampf(fit_scale, MIN_RESPONSIVE_SCALE, 1.0)

	offset_left = -BASE_PHONE_SIZE.x * 0.5
	offset_top = -BASE_PHONE_SIZE.y * 0.5
	offset_right = BASE_PHONE_SIZE.x * 0.5
	offset_bottom = BASE_PHONE_SIZE.y * 0.5
	pivot_offset = BASE_PHONE_SIZE * 0.5
	scale = Vector2.ONE * fit_scale
