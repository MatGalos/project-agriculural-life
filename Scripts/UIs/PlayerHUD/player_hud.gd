extends CanvasLayer
class_name PlayerHUD

const CROSSHAIR_SIZE := 40.0
const EVENT_MESSAGE_DURATION := 7.0
const LATO_REGULAR_FONT := preload("res://Assets/Fonts/Lato/Lato-Regular.ttf")

enum UIMode {
	GAMEPLAY,
	PAUSE,
	INVENTORY,
	PHONE,
	STORAGE
}

@export var player_inventory: InventoryData
@export var hoe_item: ItemData
@export var wheat_seed_item: ItemData
@export var watering_can_item: ItemData
@export var scythe_item: ItemData
@export var wheat_item: ItemData

@onready var date_time_controller: Control = $Root/DateTimeController
@onready var date_time_bg: ColorRect = $Root/DateTimeController/ColorRect
@onready var date_time_container: VBoxContainer = $Root/DateTimeController/DateTimeContainer
@onready var date_label: Label = $Root/DateTimeController/DateTimeContainer/DateLabel
@onready var time_label: Label = $Root/DateTimeController/DateTimeContainer/TimeLabel
@onready var funds_controller: Control = $Root/FundsController
@onready var funds_bg: ColorRect = $Root/FundsController/ColorRect
@onready var funds_label: Label = $Root/FundsController/FundsLabel
@onready var event_controller: Control = $Root/EventController
@onready var event_label: Label = $Root/EventController/EventLabel
@onready var map_controller: Control = $Root/MapController
@onready var quick_inventory_controller: Control = $Root/QuickInventoryController
@onready var crosshair: Control = $Root/CenterContainer/Crosshair
@onready var inventory_slot_1: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot1
@onready var inventory_slot_2: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot2
@onready var inventory_slot_3: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot3
@onready var inventory_slot_4: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot4
@onready var inventory_slot_5: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot5
@onready var prompt_label: Label = $Root/CenterContainer/PromptLabel
@onready var inventory_panel: InventoryPanel = $Root/InventoryPanel
@onready var phone_panel: Control = $Root/PhonePanel
@onready var storage_panel: StoragePanel = $Root/StoragePanel

var _event_message_version := 0
var _event_messages: Dictionary = {}
var _next_event_message_id := 0
var _ui_mode := UIMode.GAMEPLAY

func _ready() -> void:
	_apply_scoped_typography()
	_setup_starting_inventory()
	TimeManager.time_changed.connect(_on_time_changed)
	_update_time_ui()
	get_viewport().size_changed.connect(_update_layout)
	inventory_panel.close()
	inventory_panel.refresh()
	quick_inventory_controller.refresh()
	phone_panel.visible = false
	storage_panel.close()
	_hide_event_message()
	prompt_label.text = ""
	set_interaction_prompt_visible(false)
	MoneyManager.money_changed.connect(_on_money_changed)
	_update_money_ui()
	gamemanager.pauseChanged.connect(_on_pause_changed)
	_update_layout()
	_refresh_ui_mode()

func _apply_scoped_typography() -> void:
	var text_color: Color = Color(0.06, 0.035, 0.015, 1.0)
	var shadow_color: Color = Color(0.94, 0.77, 0.45, 0.20)

	for label: Label in [date_label, time_label, funds_label, event_label, prompt_label]:
		label.add_theme_color_override("font_color", text_color)
		label.add_theme_color_override("font_shadow_color", shadow_color)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	event_label.add_theme_font_override("font", LATO_REGULAR_FONT)
	prompt_label.add_theme_font_override("font", LATO_REGULAR_FONT)

func _update_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var min_axis: float = minf(viewport_size.x, viewport_size.y)
	var ui_scale: float = clampf(min_axis / 720.0, 0.78, 1.35)
	var margin: float = clampf(min_axis * 0.025, 12.0, 32.0)

	_update_corner_panels(ui_scale, margin)
	_update_bottom_panels(ui_scale, margin)
	_update_center_prompt(viewport_size, min_axis)

func _update_corner_panels(ui_scale: float, margin: float) -> void:
	var date_width: float = 168.0 * ui_scale
	var date_height: float = 56.0 * ui_scale
	var funds_width: float = date_width
	var funds_height: float = 30.0 * ui_scale
	var map_size: Vector2 = Vector2(150.0, 156.0) * ui_scale
	var plaque_padding: float = 10.0 * ui_scale

	_set_top_right_rect(date_time_controller, margin, margin, date_width, date_height)
	_set_rect(date_time_bg, 0.0, 0.0, date_width, date_height)
	_set_rect(date_time_container, plaque_padding, 5.0 * ui_scale, date_width - (plaque_padding * 2.0), date_height - (10.0 * ui_scale))

	_set_top_right_rect(funds_controller, margin, margin + date_height + (8.0 * ui_scale), funds_width, funds_height)
	_set_rect(funds_bg, 0.0, 0.0, funds_width, funds_height)
	_set_rect(funds_label, plaque_padding, 0.0, funds_width - (plaque_padding * 2.0), funds_height)
	funds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	funds_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_set_rect(map_controller, margin, margin, map_size.x, map_size.y)
	date_label.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	time_label.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	funds_label.add_theme_font_size_override("font_size", roundi(15.0 * ui_scale))

func _update_bottom_panels(ui_scale: float, margin: float) -> void:
	var event_size: Vector2 = Vector2(300.0, 86.0) * ui_scale
	var slot_size: Vector2 = Vector2(96.0, 64.0) * ui_scale
	var inventory_width: float = slot_size.x * 5.0
	var inventory_height: float = slot_size.y
	var notification_padding: float = 12.0 * ui_scale

	_set_bottom_left_rect(event_controller, margin, margin, event_size.x, event_size.y)
	_set_rect(event_label, notification_padding, 6.0 * ui_scale, event_size.x - (notification_padding * 2.0), event_size.y - (12.0 * ui_scale))
	_set_bottom_center_rect(quick_inventory_controller, margin, inventory_width, inventory_height)

	_set_inventory_slot_sizes(slot_size)

	event_label.add_theme_font_size_override("font_size", roundi(17.0 * ui_scale))
	_update_inventory_label_fonts(roundi(13.0 * ui_scale))

func _update_center_prompt(viewport_size: Vector2, min_axis: float) -> void:
	var prompt_width: float = clampf(viewport_size.x * 0.28, 220.0, 460.0)
	var prompt_gap: float = clampf(min_axis * 0.045, 28.0, 64.0)
	var prompt_font_size: int = roundi(clampf(min_axis * 0.021, 16.0, 22.0))
	var prompt_height: float = maxf(float(prompt_font_size) * 1.9, 36.0)
	var prompt_top: float = (CROSSHAIR_SIZE * 0.5) + prompt_gap

	prompt_label.offset_left = -prompt_width * 0.5
	prompt_label.offset_top = prompt_top
	prompt_label.offset_right = prompt_width * 0.5
	prompt_label.offset_bottom = prompt_top + prompt_height
	prompt_label.add_theme_font_size_override("font_size", prompt_font_size)

func _set_rect(control: Control, left: float, top: float, width: float, height: float) -> void:
	control.offset_left = left
	control.offset_top = top
	control.offset_right = left + width
	control.offset_bottom = top + height

func _set_top_right_rect(control: Control, right_margin: float, top: float, width: float, height: float) -> void:
	control.offset_left = -right_margin - width
	control.offset_top = top
	control.offset_right = -right_margin
	control.offset_bottom = top + height

func _set_bottom_left_rect(control: Control, left: float, bottom_margin: float, width: float, height: float) -> void:
	control.offset_left = left
	control.offset_top = -bottom_margin - height
	control.offset_right = left + width
	control.offset_bottom = -bottom_margin

func _set_bottom_center_rect(control: Control, bottom_margin: float, width: float, height: float) -> void:
	control.offset_left = -width * 0.5
	control.offset_top = -bottom_margin - height
	control.offset_right = width * 0.5
	control.offset_bottom = -bottom_margin

func _set_inventory_slot_sizes(slot_size: Vector2) -> void:
	inventory_slot_1.custom_minimum_size = slot_size
	inventory_slot_2.custom_minimum_size = slot_size
	inventory_slot_3.custom_minimum_size = slot_size
	inventory_slot_4.custom_minimum_size = slot_size
	inventory_slot_5.custom_minimum_size = slot_size

func _update_inventory_label_fonts(font_size: int) -> void:
	_set_slot_label_font_size(inventory_slot_1, font_size)
	_set_slot_label_font_size(inventory_slot_2, font_size)
	_set_slot_label_font_size(inventory_slot_3, font_size)
	_set_slot_label_font_size(inventory_slot_4, font_size)
	_set_slot_label_font_size(inventory_slot_5, font_size)


func _set_slot_label_font_size(slot: PanelContainer, font_size: int) -> void:
	var label: Label = slot.get_node("AmountLabel") as Label
	if label:
		label.add_theme_font_size_override("font_size", font_size)


func _setup_starting_inventory() -> void:
	if player_inventory == null:
		return

	player_inventory.setup()
	player_inventory.clear_inventory()
	player_inventory.add_item(hoe_item, 1)
	player_inventory.add_item(wheat_seed_item, 20)
	player_inventory.add_item(watering_can_item, 1)
	player_inventory.add_item(scythe_item, 1)
	player_inventory.add_item(wheat_item, 10)

func open_inventory() -> void:
	if is_phone_open() or is_storage_open():
		return

	inventory_panel.open()
	_refresh_ui_mode()


func close_inventory() -> void:
	inventory_panel.close()
	_refresh_ui_mode()


func toggle_inventory() -> void:
	if is_inventory_open():
		close_inventory()
	else:
		open_inventory()


func is_inventory_open() -> bool:
	return inventory_panel.is_open()

func open_phone() -> void:
	if is_inventory_open() or is_storage_open():
		return

	phone_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_ui_mode()

func close_phone() -> void:
	phone_panel.visible = false
	_refresh_ui_mode()

	if gamemanager.isInGame and not gamemanager.isPaused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_phone() -> void:
	if is_phone_open():
		close_phone()
	else:
		open_phone()

func is_phone_open() -> bool:
	return phone_panel.visible

func open_storage() -> void:
	if is_inventory_open() or is_phone_open():
		return

	storage_panel.open()
	_refresh_ui_mode()

func close_storage() -> void:
	storage_panel.close()
	_refresh_ui_mode()

func toggle_storage() -> void:
	if is_storage_open():
		close_storage()
	else:
		open_storage()

func is_storage_open() -> bool:
	return storage_panel != null and storage_panel.is_open()

func is_any_game_menu_open() -> bool:
	return is_inventory_open() or is_phone_open() or is_storage_open()

func is_gameplay_hud_visible() -> bool:
	return _ui_mode == UIMode.GAMEPLAY

func set_ui_mode(mode: int) -> void:
	_ui_mode = mode

	match _ui_mode:
		UIMode.GAMEPLAY:
			set_crosshair_visible(true)
			set_interaction_prompt_visible(prompt_label.text != "")
			set_hotbar_visible(true)
			set_status_hud_visible(true)
			set_notifications_visible(not _event_messages.is_empty())
		UIMode.PAUSE:
			set_crosshair_visible(false)
			set_interaction_prompt_visible(false)
			set_hotbar_visible(false)
			set_status_hud_visible(false)
			set_notifications_visible(false)
		UIMode.INVENTORY:
			set_crosshair_visible(false)
			set_interaction_prompt_visible(false)
			set_hotbar_visible(false)
			set_status_hud_visible(false)
			set_notifications_visible(false)
		UIMode.PHONE:
			set_crosshair_visible(false)
			set_interaction_prompt_visible(false)
			set_hotbar_visible(false)
			set_status_hud_visible(false)
			set_notifications_visible(false)
		UIMode.STORAGE:
			set_crosshair_visible(false)
			set_interaction_prompt_visible(false)
			set_hotbar_visible(false)
			set_status_hud_visible(false)
			set_notifications_visible(false)


func set_crosshair_visible(is_visible: bool) -> void:
	crosshair.visible = is_visible


func set_interaction_prompt_visible(is_visible: bool) -> void:
	prompt_label.visible = is_visible and not prompt_label.text.strip_edges().is_empty()


func set_hotbar_visible(is_visible: bool) -> void:
	quick_inventory_controller.visible = is_visible


func set_status_hud_visible(is_visible: bool) -> void:
	date_time_controller.visible = is_visible
	funds_controller.visible = is_visible


func set_notifications_visible(is_visible: bool) -> void:
	event_controller.visible = is_visible and not _event_messages.is_empty()


func _refresh_ui_mode() -> void:
	if gamemanager.isPaused:
		set_ui_mode(UIMode.PAUSE)
	elif is_storage_open():
		set_ui_mode(UIMode.STORAGE)
	elif is_phone_open():
		set_ui_mode(UIMode.PHONE)
	elif is_inventory_open():
		set_ui_mode(UIMode.INVENTORY)
	else:
		set_ui_mode(UIMode.GAMEPLAY)


func _on_pause_changed(_paused: bool) -> void:
	_refresh_ui_mode()

func show_event_message(message: String, duration: float = EVENT_MESSAGE_DURATION) -> void:
	if message.is_empty():
		_hide_event_message()
		return

	_event_message_version += 1
	_next_event_message_id += 1
	var message_id := _next_event_message_id

	_event_messages[message_id] = message
	_refresh_event_messages()

	await get_tree().create_timer(duration).timeout

	_event_messages.erase(message_id)
	_refresh_event_messages()


func _refresh_event_messages() -> void:
	if _event_messages.is_empty():
		_hide_event_message()
		return

	var messages: Array[String] = []

	for message_id in _event_messages.keys():
		messages.append(String(_event_messages[message_id]))

	event_label.text = "\n".join(messages)
	set_notifications_visible(_ui_mode == UIMode.GAMEPLAY)

func _hide_event_message() -> void:
	_event_messages.clear()
	event_controller.visible = false
	event_label.text = ""

func _on_time_changed() -> void:
	_update_time_ui()

func _update_time_ui() -> void:
	date_label.text = TimeManager.get_date_string()
	time_label.text = TimeManager.get_time_string()

func _on_money_changed(_new_amount: int) -> void:
	_update_money_ui()

func _update_money_ui() -> void:
	funds_label.text = UIFormatHelper.money_int(MoneyManager.get_money())
