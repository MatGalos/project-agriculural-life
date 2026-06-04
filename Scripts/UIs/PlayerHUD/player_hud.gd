extends CanvasLayer
class_name PlayerHUD

const CROSSHAIR_SIZE := 40.0

@export var player_inventory: InventoryData
@export var test_item: ItemData

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
@onready var inventory_slot_1: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot1
@onready var inventory_slot_2: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot2
@onready var inventory_slot_3: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot3
@onready var inventory_slot_4: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot4
@onready var inventory_slot_5: PanelContainer = $Root/QuickInventoryController/PanelContainer/HBoxContainer/Slot5
@onready var prompt_label: Label = $Root/CenterContainer/PromptLabel
@onready var inventory_panel: InventoryPanel = $Root/InventoryPanel
@onready var phone_panel: Control = $Root/PhonePanel


func _ready() -> void:
	player_inventory.setup()
	print("Inventory slots: ", player_inventory.slots.size())
	var leftover := player_inventory.add_item(test_item, 120)
	print("Leftover: ", leftover)

	for i in range(player_inventory.slots.size()):
		var slot = player_inventory.slots[i]
		if not slot.is_empty():
			print(i, ": ", slot.item_data.display_name, " x", slot.amount)
	get_viewport().size_changed.connect(_update_layout)
	inventory_panel.close()
	phone_panel.visible = false
	_update_layout()


func _update_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var min_axis: float = minf(viewport_size.x, viewport_size.y)
	var ui_scale: float = clampf(min_axis / 720.0, 0.78, 1.35)
	var margin: float = clampf(min_axis * 0.025, 12.0, 32.0)

	_update_corner_panels(ui_scale, margin)
	_update_bottom_panels(ui_scale, margin)
	_update_center_prompt(viewport_size, min_axis)


func _update_corner_panels(ui_scale: float, margin: float) -> void:
	var date_width: float = 140.0 * ui_scale
	var date_height: float = 54.0 * ui_scale
	var funds_width: float = date_width
	var funds_height: float = 28.0 * ui_scale
	var map_size: Vector2 = Vector2(150.0, 156.0) * ui_scale

	_set_top_right_rect(date_time_controller, margin, margin, date_width, date_height)
	_set_rect(date_time_bg, 0.0, 0.0, date_width, date_height)
	_set_rect(date_time_container, 0.0, 4.0 * ui_scale, date_width, date_height - (8.0 * ui_scale))

	_set_top_right_rect(funds_controller, margin, margin + date_height + (8.0 * ui_scale), funds_width, funds_height)
	_set_rect(funds_bg, 0.0, 0.0, funds_width, funds_height)
	_set_rect(funds_label, 0.0, 0.0, funds_width - (8.0 * ui_scale), funds_height)

	_set_rect(map_controller, margin, margin, map_size.x, map_size.y)
	date_label.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	time_label.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	funds_label.add_theme_font_size_override("font_size", roundi(15.0 * ui_scale))


func _update_bottom_panels(ui_scale: float, margin: float) -> void:
	var event_size: Vector2 = Vector2(190.0, 96.0) * ui_scale
	var slot_size: Vector2 = Vector2(96.0, 64.0) * ui_scale
	var inventory_width: float = slot_size.x * 5.0
	var inventory_height: float = slot_size.y

	_set_bottom_left_rect(event_controller, margin, margin, event_size.x, event_size.y)
	_set_bottom_center_rect(quick_inventory_controller, margin, inventory_width, inventory_height)

	_set_inventory_slot_sizes(slot_size)

	event_label.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	_update_inventory_label_fonts(roundi(13.0 * ui_scale))


func _update_center_prompt(viewport_size: Vector2, min_axis: float) -> void:
	var prompt_width: float = clampf(viewport_size.x * 0.42, 280.0, 640.0)
	var prompt_gap: float = clampf(min_axis * 0.045, 28.0, 64.0)
	var prompt_font_size: int = roundi(clampf(min_axis * 0.026, 18.0, 28.0))
	var prompt_height: float = maxf(float(prompt_font_size) * 1.7, 40.0)
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
	var label: Label = slot.get_node("Label") as Label
	label.add_theme_font_size_override("font_size", font_size)

func open_inventory() -> void:
	if is_phone_open():
		return

	inventory_panel.open()


func close_inventory() -> void:
	inventory_panel.close()


func toggle_inventory() -> void:
	if is_inventory_open():
		close_inventory()
	else:
		open_inventory()


func is_inventory_open() -> bool:
	return inventory_panel.is_open()

func open_phone() -> void:
	if is_inventory_open():
		return

	phone_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_phone() -> void:
	phone_panel.visible = false

	if gamemanager.isInGame and not gamemanager.isPaused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_phone() -> void:
	if is_phone_open():
		close_phone()
	else:
		open_phone()

func is_phone_open() -> bool:
	return phone_panel.visible
