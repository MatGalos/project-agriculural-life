extends Resource
class_name ItemData

enum ItemCategory {
	CROP,
	SEED,
	TOOL,
	RESOURCE
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var base_price: int = 0
@export var max_stack: int = 99
@export var category: ItemCategory = ItemCategory.RESOURCE
