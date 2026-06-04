extends ItemData
class_name ToolItemData

enum ToolType {
	HOE,
	WATERING_CAN,
	SEED_BAG,
	SCYTHE
}

@export var tool_type: ToolType = ToolType.HOE
@export var model_scene: PackedScene
