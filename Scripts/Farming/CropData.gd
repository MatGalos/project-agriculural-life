extends Resource
class_name CropData

@export var crop_id: String = ""
@export var display_name: String = ""

@export var seed_item: SeedItemData
@export var harvest_item: CropItemData

@export var seeded_scene: PackedScene
@export var stage_1_scene: PackedScene
@export var stage_2_scene: PackedScene
@export var stage_3_scene: PackedScene
@export var ready_scene: PackedScene

@export var days_to_stage_1: int = 1
@export var days_to_stage_2: int = 2
@export var days_to_stage_3: int = 3
@export var days_to_ready: int = 4

@export var harvest_amount: int = 1
