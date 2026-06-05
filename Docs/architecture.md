# Project Architecture Notes

This document describes the current runtime flow for the main gameplay scripts. It is intended as a maintenance guide for future work, not as a full design document.

## Autoloads

The project uses these gameplay autoloads:

- `gamemanager` controls global UI menus, pause state, scene transitions, and mouse capture.
- `InputManager` centralizes gameplay action queries and control rebinding persistence.
- `HotbarManager` owns hotbar selection state and exposes the currently selected item.
- `ToolManager` applies active hotbar tools/seeds to world targets and owns watering-can state.
- `CropGrowthManager` advances registered farm tiles when the day changes.
- `TimeManager` owns in-game time, date, seasons, and day/month/year signals.
- `UI` is the player HUD scene autoload.

Keep cross-system state in autoloads only when multiple unrelated scenes need it. Scene-local display logic should stay in UI controllers.

## Input And Controls

`InputManager` wraps gameplay input reads and persists rebinds to `user://controls.cfg`.

Important behavior:

- Keyboard and mouse-button binds are serialized.
- Empty legacy config entries are ignored so default project binds are not erased.
- `reset_to_defaults()` recreates all known actions before assigning default binds.
- `use_tool` defaults to left mouse button and is routed through `CharacterController` to `ToolManager`.

## Pause And Mouse Capture

`gamemanager` is the source of truth for game pause state.

Rules:

- `setPaused()` must be used instead of changing `get_tree().paused` directly.
- `Esc` is ignored while options are open, so options cannot accidentally unpause the game.
- Inventory and phone are closed before toggling pause.
- Mouse capture is enabled only while the player is in game, not paused, and no blocking UI is visible.

## Inventory Data

`InventoryData` is a `Resource` containing an array of `InventorySlot` resources.

Important behavior:

- Call `setup()` before reading or mutating slots if the caller is not sure the data was initialized.
- `setup()` preserves existing slot contents and only adjusts the array size.
- Mutating methods emit `inventory_changed` after a real data change.
- UI should refresh from `inventory_changed` instead of polling every frame.

Slot move behavior:

- Empty target: move the whole source slot.
- Same item target: merge as much as possible up to `max_stack`.
- Different item target: swap both slots.

## Hotbar Data

`HotbarData` maps visible hotbar slots to inventory slot indexes. By default, hotbar slots 1-5 show inventory slots 0-4.

`HotbarManager` owns selection state and uses `HotbarData` to resolve the selected `ItemData`. Hotbar UI should only render what `HotbarManager.inventory_data` and `HotbarManager.hotbar_data` expose.

## Tools And Crops

`ToolManager` resolves the currently selected hotbar item and applies it to the raycast target.

Supported behavior:

- Hoe: turns grass farm tiles into plowed farm tiles.
- Watering can: waters plowed farm tiles if water is available.
- Seed item: plants the crop matching `SeedItemData.crop_id` on watered empty farm tiles.
- Scythe: harvests ready crops and adds the harvest item to inventory.

Crop lookup uses `all_crops: Array[CropData]`. Add new crop resources to that list instead of hardcoding individual seed checks.

Watering-can state:

- `watering_can_water` stores current water units.
- `watering_can_capacity` stores max water units.
- `watering_can_changed` is emitted after watering or refill.
- `WellInteractable` refills the watering can through `ToolManager.refill_watering_can()`.

## Farm Tiles And Growth

`FarmTile` owns tile state, planted crop data, crop growth days, and the active crop visual instance.

Growth rules:

- Crops can be planted only on watered tiles with no existing crop.
- A watered tile with a crop advances growth when a new day starts.
- Watered tiles revert to plowed after daily processing.
- Harvesting a ready crop clears the crop visual and returns the harvest item.

`CropGrowthManager` registers runtime farm tiles and calls `process_new_day()` from `TimeManager.day_changed`.

## Inventory UI

`InventoryPanel` builds slot UI nodes from `slot_ui_scene` and binds them to `InventoryData.slots` by index.

`InventorySlotUI` handles drag and drop:

- Child nodes ignore mouse input so drag starts on the slot panel.
- Drag payloads use `{ "type": "inventory_slot", "slot_index": index }` to avoid accepting unrelated UI drags.
- Icons are displayed at a fixed UI size and do not resize slots based on source texture size.
- Watering-can slots show a water-fill bar and refresh from `ToolManager.watering_can_changed`.

## Hotbar UI

`QuickInventoryController` renders the mapped inventory slots and refreshes when inventory data changes. It also refreshes after inventory drag and drop to keep hotbar icons synchronized with slot movement.

Watering-can bars are created under each slot icon at runtime. They are intentionally attached to `IconRect`, not the slot `PanelContainer`, so the bar does not resize or darken the whole hotbar slot.

## Player HUD

`PlayerHUD` owns mutually exclusive blocking panels:

- Inventory cannot open while phone is open.
- Phone cannot open while inventory is open.
- Closing either panel restores mouse capture only if the game is active and not paused.

The current starting inventory is initialized in `PlayerHUD._setup_starting_inventory()`. Replace this with save-game loading when persistence is implemented.

## Interaction UI

`InteractionController` raycasts from the player camera and updates prompt/crosshair UI lazily. It intentionally re-fetches UI labels if they were not available during `_ready()`, because HUD creation order can vary when using autoload scenes.

Prompt priority:

- Tool prompts from `ToolManager.get_tool_prompt_for_target()` are shown first.
- Interactable prompts are shown only when no tool prompt is available.

## Maintenance Checklist

Before adding new inventory, crop, tool, or UI behavior:

- Prefer updating data resources first, then let UI refresh from signals.
- Avoid direct mouse mode changes outside `gamemanager`, `PlayerHUD`, or panel open/close methods.
- Use `get_node_or_null()` for optional scene dependencies.
- Keep item icons independent from source texture resolution by configuring `TextureRect.expand_mode` and `stretch_mode`.
- Add new crop resources to `ToolManager.all_crops` before adding special-case code.
- Do not add debug `print()` calls in runtime paths unless they are temporary and removed before commit.
