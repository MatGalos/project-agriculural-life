extends Control

@onready var sell_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BottomNav/HBoxContainer/Sell
@onready var shop_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BottomNav/HBoxContainer/Shop
@onready var exchange_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BottomNav/HBoxContainer/StockMarket
@onready var weather_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BottomNav/HBoxContainer/Weather
@onready var sell_app: Control = $PanelContainer/MarginContainer/VBoxContainer/ContentArea/PanelContainer/AppContainer/SellApp
@onready var shop_app: Control = $PanelContainer/MarginContainer/VBoxContainer/ContentArea/PanelContainer/AppContainer/ShopApp
@onready var exchange_app: Control = $PanelContainer/MarginContainer/VBoxContainer/ContentArea/PanelContainer/AppContainer/StockMarketApp
@onready var weather_app: Control = $PanelContainer/MarginContainer/VBoxContainer/ContentArea/PanelContainer/AppContainer/WeatherApp

func _ready() -> void:
	visible = false
	sell_button.pressed.connect(_on_sell_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	exchange_button.pressed.connect(_on_exchange_pressed)
	weather_button.pressed.connect(_on_weather_pressed)

func open() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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

func _on_sell_pressed() -> void:
	_hide_all_apps()
	sell_app.visible = true
	sell_app.refresh()

func _on_shop_pressed() -> void:
	_hide_all_apps()
	shop_app.visible = true
	shop_app.refresh()

func _hide_all_apps() -> void:
	for child in $PanelContainer/MarginContainer/VBoxContainer/ContentArea/PanelContainer/AppContainer.get_children():
		if child is Control:
			child.visible = false

func _on_exchange_pressed() -> void:
	_hide_all_apps()
	exchange_app.visible = true
	exchange_app.refresh()

func _on_weather_pressed() -> void:
	_hide_all_apps()
	weather_app.visible = true
	weather_app.refresh()
