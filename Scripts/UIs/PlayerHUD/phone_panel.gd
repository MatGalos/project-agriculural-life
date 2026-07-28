extends Control

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
	news_button.pressed.connect(_on_news_pressed)
	exchange_button.pressed.connect(_on_exchange_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	weather_button.pressed.connect(_on_weather_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	home_button.pressed.connect(_on_home_pressed)
	visibility_changed.connect(_on_visibility_changed)
	add_to_group("phone_panel")
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
		_show_home_screen()
