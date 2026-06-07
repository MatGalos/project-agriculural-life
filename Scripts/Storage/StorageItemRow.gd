extends HBoxContainer
class_name StorageItemRow

const ICON_SIZE := Vector2(40, 40)

@onready var icon_rect: TextureRect = $IconRect
@onready var name_label: Label = $NameLabel
@onready var amount_label: Label = $AmountLabel


func _ready() -> void:
	custom_minimum_size.y = ICON_SIZE.y

	if icon_rect:
		icon_rect.custom_minimum_size = ICON_SIZE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if name_label:
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func setup(item_data: ItemData, amount: int) -> void:
	if item_data == null:
		return

	icon_rect.texture = item_data.icon
	name_label.text = item_data.display_name
	amount_label.text = str(amount)
