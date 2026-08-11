extends RefCounted

var runner: TestRunner

const CROP_PRODUCTS: Array[Dictionary] = [
	{
		"id": "beetroot",
		"item_path": "res://Data/Items/Crops/beetroot_item.tres",
		"seed_path": "res://Data/Items/Seeds/beetroot_seed_item.tres",
		"crop_path": "res://Data/Crops/beetroot_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/beetroot_commodity.tres",
		"event_ids": ["beetroot_demand_spike", "beetroot_oversupply", "beetroot_bad_harvest"]
	},
	{
		"id": "cabbage",
		"item_path": "res://Data/Items/Crops/cabbage_item.tres",
		"seed_path": "res://Data/Items/Seeds/cabbage_seed_item.tres",
		"crop_path": "res://Data/Crops/cabbage_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/cabbage_commodity.tres",
		"event_ids": ["cabbage_demand_spike", "cabbage_oversupply", "cabbage_bad_harvest"]
	},
	{
		"id": "carrot",
		"item_path": "res://Data/Items/Crops/carrot_item.tres",
		"seed_path": "res://Data/Items/Seeds/carrot_seed_item.tres",
		"crop_path": "res://Data/Crops/carrot_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/carrot_commodity.tres",
		"event_ids": ["carrot_demand_spike", "carrot_oversupply", "carrot_bad_harvest"]
	},
	{
		"id": "corn",
		"item_path": "res://Data/Items/Crops/corn_item.tres",
		"seed_path": "res://Data/Items/Seeds/corn_seed_item.tres",
		"crop_path": "res://Data/Crops/corn_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/corn_commodity.tres",
		"event_ids": ["corn_demand_spike", "corn_oversupply", "corn_bad_harvest"]
	},
	{
		"id": "lettuce",
		"item_path": "res://Data/Items/Crops/lettuce_item.tres",
		"seed_path": "res://Data/Items/Seeds/lettuce_seed_item.tres",
		"crop_path": "res://Data/Crops/lettuce_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/lettuce_commodity.tres",
		"event_ids": ["lettuce_demand_spike", "lettuce_oversupply", "lettuce_bad_harvest"]
	},
	{
		"id": "potatoe",
		"item_path": "res://Data/Items/Crops/potatoe_item.tres",
		"seed_path": "res://Data/Items/Seeds/potatoe_seed_item.tres",
		"crop_path": "res://Data/Crops/potatoe_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/potatoe_commodity.tres",
		"event_ids": ["potatoe_demand_spike", "potatoe_oversupply", "potatoe_bad_harvest"]
	},
	{
		"id": "pumpkin",
		"item_path": "res://Data/Items/Crops/pumpkin_item.tres",
		"seed_path": "res://Data/Items/Seeds/pumpkin_seed_item.tres",
		"crop_path": "res://Data/Crops/pumpkin_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/pumpkin_commodity.tres",
		"event_ids": ["pumpkin_demand_spike", "pumpkin_oversupply", "pumpkin_bad_harvest"]
	},
	{
		"id": "strawberry",
		"item_path": "res://Data/Items/Crops/strawberry_item.tres",
		"seed_path": "res://Data/Items/Seeds/strawberry_seed_item.tres",
		"crop_path": "res://Data/Crops/strawberry_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/strawberry_commodity.tres",
		"event_ids": ["strawberry_demand_spike", "strawberry_oversupply", "strawberry_bad_harvest"]
	},
	{
		"id": "tomatoe",
		"item_path": "res://Data/Items/Crops/tomatoe_item.tres",
		"seed_path": "res://Data/Items/Seeds/tomatoe_seed_item.tres",
		"crop_path": "res://Data/Crops/tomatoe_crop.tres",
		"commodity_path": "res://Data/Economy/Commodities/tomatoe_commodity.tres",
		"event_ids": ["tomatoe_demand_spike", "tomatoe_oversupply", "tomatoe_bad_harvest"]
	}
]


func run() -> void:
	print("\n--- CropProductIntegrationTest ---")

	_verify_data_links()
	_verify_inventory_save_restore()
	_verify_storage_save_restore()


func _verify_data_links() -> void:
	for crop_product: Dictionary in CROP_PRODUCTS:
		var crop_id: String = String(crop_product["id"])
		var item: CropItemData = load(String(crop_product["item_path"])) as CropItemData
		var seed_item: SeedItemData = load(String(crop_product["seed_path"])) as SeedItemData
		var crop: CropData = load(String(crop_product["crop_path"])) as CropData
		var commodity: CommodityData = load(String(crop_product["commodity_path"])) as CommodityData

		runner.assert_true(item != null, "%s crop item loads" % crop_id)
		runner.assert_true(seed_item != null, "%s seed item loads" % crop_id)
		runner.assert_true(crop != null, "%s crop data loads" % crop_id)
		runner.assert_true(commodity != null, "%s commodity loads" % crop_id)

		if item == null or seed_item == null or crop == null or commodity == null:
			continue

		runner.assert_eq(item.id, crop_id, "%s crop item id matches" % crop_id)
		runner.assert_eq(seed_item.id, "%s_seed" % crop_id, "%s seed item id matches" % crop_id)
		runner.assert_eq(seed_item.crop_id, crop_id, "%s seed crop id matches" % crop_id)
		runner.assert_eq(crop.crop_id, crop_id, "%s crop data id matches" % crop_id)
		runner.assert_eq(crop.harvest_item.id, item.id, "%s crop harvest item linked" % crop_id)
		runner.assert_eq(crop.seed_item.id, seed_item.id, "%s crop seed item linked" % crop_id)
		runner.assert_eq(seed_item.growth_days, crop.days_to_ready, "%s seed growth days match crop ready days" % crop_id)
		runner.assert_eq(commodity.item_data.id, item.id, "%s commodity item linked" % crop_id)

		var save_item: ItemData = SaveManager._get_item_by_id(item.id)
		runner.assert_true(save_item != null, "%s item registered in SaveManager" % crop_id)
		runner.assert_eq(save_item.id, item.id, "%s SaveManager item id matches" % crop_id)

		var save_seed: ItemData = SaveManager._get_item_by_id(seed_item.id)
		runner.assert_true(save_seed != null, "%s seed registered in SaveManager" % crop_id)
		runner.assert_eq(save_seed.id, seed_item.id, "%s SaveManager seed id matches" % crop_id)

		var save_crop: CropData = SaveManager._get_crop_by_id(crop.crop_id)
		runner.assert_true(save_crop != null, "%s crop registered in SaveManager" % crop_id)
		runner.assert_eq(save_crop.crop_id, crop.crop_id, "%s SaveManager crop id matches" % crop_id)

		var tool_crop: CropData = ToolManager._get_crop_data_for_seed(seed_item)
		runner.assert_true(tool_crop != null, "%s seed resolves to crop in ToolManager" % crop_id)
		runner.assert_eq(tool_crop.crop_id, crop.crop_id, "%s ToolManager crop id matches" % crop_id)

		var silo_item: ItemData = SaveManager.silo_storage.get_item_by_id(item.id)
		runner.assert_true(silo_item != null, "%s item registered in silo storage" % crop_id)

		var silo_seed: ItemData = SaveManager.silo_storage.get_item_by_id(seed_item.id)
		runner.assert_true(silo_seed != null, "%s seed registered in silo storage" % crop_id)

		var manager_commodity: CommodityData = CommodityMarketManager.get_commodity_for_item(item)
		runner.assert_true(manager_commodity != null, "%s commodity registered in market manager" % crop_id)
		runner.assert_eq(manager_commodity.item_data.id, item.id, "%s market manager commodity id matches" % crop_id)

		var shop_item_path: String = "res://Data/Shop/%s_seed_shop_item.tres" % crop_id
		var shop_item: ShopItemData = load(shop_item_path) as ShopItemData
		runner.assert_true(shop_item != null, "%s seed shop item loads" % crop_id)

		if shop_item != null:
			runner.assert_eq(shop_item.item_data.id, seed_item.id, "%s shop item seed linked" % crop_id)
			runner.assert_true(_is_seed_in_basic_shop(seed_item.id), "%s seed registered in basic shop" % crop_id)

		var event_ids: Array = crop_product["event_ids"] as Array

		for event_id in event_ids:
			var event_data: MarketEventData = EventManager.get_event_by_id(String(event_id))
			runner.assert_true(event_data != null, "%s event registered" % String(event_id))

			if event_data != null:
				runner.assert_eq(event_data.target_item.id, item.id, "%s event target item matches" % String(event_id))


func _verify_inventory_save_restore() -> void:
	var inventory: InventoryData = HotbarManager.inventory_data

	if inventory == null:
		runner.assert_true(false, "Inventory exists for crop product save test")
		return

	inventory.setup()
	inventory.clear_inventory()

	for crop_product: Dictionary in CROP_PRODUCTS:
		var item: ItemData = load(String(crop_product["item_path"])) as ItemData
		var seed_item: ItemData = load(String(crop_product["seed_path"])) as ItemData

		inventory.add_item(item, 1)
		inventory.add_item(seed_item, 1)

	var save_data: Array = SaveManager._create_inventory_save_data()
	inventory.clear_inventory()
	SaveManager._apply_inventory_save_data(save_data)

	for crop_product: Dictionary in CROP_PRODUCTS:
		var crop_id: String = String(crop_product["id"])
		var item: ItemData = load(String(crop_product["item_path"])) as ItemData
		var seed_item: ItemData = load(String(crop_product["seed_path"])) as ItemData

		runner.assert_eq(inventory.get_item_count(item), 1, "%s inventory crop restored" % crop_id)
		runner.assert_eq(inventory.get_item_count(seed_item), 1, "%s inventory seed restored" % crop_id)

	inventory.clear_inventory()


func _verify_storage_save_restore() -> void:
	var storage: StorageData = SaveManager.silo_storage

	if storage == null:
		runner.assert_true(false, "Silo storage exists for crop product save test")
		return

	var previous_items: Dictionary = storage.stored_items.duplicate(true)
	storage.stored_items.clear()

	for i in range(CROP_PRODUCTS.size()):
		var crop_product: Dictionary = CROP_PRODUCTS[i]
		var item: ItemData = load(String(crop_product["item_path"])) as ItemData
		storage.add_item(item, i + 1)

	var save_data: Dictionary = SaveManager._create_storage_save_data()
	storage.stored_items.clear()
	SaveManager._apply_storage_save_data(save_data)

	for i in range(CROP_PRODUCTS.size()):
		var crop_product: Dictionary = CROP_PRODUCTS[i]
		var crop_id: String = String(crop_product["id"])
		var item: ItemData = load(String(crop_product["item_path"])) as ItemData

		runner.assert_eq(storage.get_item_amount(item), i + 1, "%s storage crop restored" % crop_id)

	storage.stored_items = previous_items
	storage.storage_changed.emit()


func _is_seed_in_basic_shop(seed_id: String) -> bool:
	var basic_shop: ShopData = load("res://Data/Shop/basic_shop.tres") as ShopData

	if basic_shop == null:
		return false

	for shop_item: ShopItemData in basic_shop.items:
		if shop_item != null and shop_item.item_data != null and shop_item.item_data.id == seed_id:
			return true

	return false
