# Testing Documentation

This document describes the current in-project test setup for Project Agricultural Life.

## Test System Overview

The project uses a lightweight custom test runner instead of an external Godot test framework.

Main files:

- `Tests/TestRunner.gd` owns test execution and assertion counting.
- `Scripts/GameManagers/DebugManager.gd` listens for the debug input action and the `--run-tests` command-line flag that run all tests.
- `Tests/Core/` contains focused tests for data resources and manager logic.
- `Tests/Save/` contains tests for save data structure and save/load restoration helpers.

`TestRunner` creates each test object, assigns itself to `test_script.runner`, and calls `run()`.
Test scripts are `RefCounted` objects with a `runner: TestRunner` field and a `run() -> void` method.

## Running Tests

Tests are run in-game through the debug input action:

- Action name: `run_tests_debug`
- Current default key: `F6`
- Runtime path: `DebugManager._input()` creates `TestRunner`, adds it to the scene tree, runs all tests, then frees it.

Tests can also be run headless by launching the project with the `--run-tests` argument:

```powershell
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . -- --run-tests
```

Use the full path to the Godot executable if `godot` is not available in `PATH`:

```powershell
cd D:\project-agriculural-life
Measure-Command {
	& 'C:\Path\To\Godot_v4.6-stable_win64.exe' --headless --path . -- --run-tests
}
```

`DebugManager` exits with code `1` when any test fails and `0` when all tests pass.

When the action is pressed, results are printed to the Godot output console:

- `========== RUNNING TESTS ==========` starts the run.
- Each test prints its section name.
- Passing assertions increment `passed`.
- Failing assertions increment `failed` and call `push_error()`.
- Final totals are printed under `========== TEST RESULTS ==========`.

## Current Test Coverage

Core tests:

- `MoneyManagerTest.gd`: money setting, adding, spending, and failed spending.
- `StorageDataTest.gd`: storage item add/remove/count behavior.
- `HotbarDataTest.gd`: hotbar setup, slot mapping, and selected slot behavior.
- `SalesStatsManagerTest.gd`: sales recording, recent sales totals, and day rollover.
- `InventoryDataTest.gd`: inventory setup, stacking, removal, and slot movement behavior.
- `WeatherManagerTest.gd`: day phase hour boundaries, cached phase updates from time changes, phase temperatures derived from one daily base temperature, expanded daily forecast entry fields, and season weather profile modifiers for temperature and rainy/stormy pattern weights.
- `EventSystemTest.gd`: event data compatibility, multi-product modifiers, deterministic trend stacking, volatility reset behavior, season/day/weather/temperature requirements, calendar-event locks, daily event start limits, seed buy-price modifiers, save/load event state, duplicate-news protection, bad-harvest crop-season restrictions, and configured trigger chances for Demand Spike, Export Contract, and Market Panic.

Save tests:

- `SaveStructureTest.gd`: top-level save sections and player save fields.
- `SaveSlotTest.gd`: save slot pathing, slot selection, existence checks, and deletion.
- `SalesStatsSaveTest.gd`: sales stats serialization and restoration.
- `InventorySaveTest.gd`: inventory serialization and restoration.
- `StorageSaveTest.gd`: silo storage serialization and restoration.
- `WeatherSaveTest.gd`: current weather, temperature, forecast save data, forecast pattern, and forecast rain chance.
- `NewsSaveTest.gd`: news history serialization and restoration.
- `MarketSaveTest.gd`: commodity market prices, trends, volatility, and history.
- `EventSaveTest.gd`: active market event persistence.
- `CropProductIntegrationTest.gd`: integration coverage for added crop products, seeds, crop data, commodity data, market events, shop items, storage registration, and save-manager lookup.
- `FarmTileLogicTest.gd`: farm tile state transitions, planting, growth, and crop clearing.
- `TileCropSaveTest.gd`: farm tile crop data in world save/load flow.

Simulation tests:

- `FullYearSimulationTest.gd`: deterministic 120-day market/event/weather simulation using seed `123456`. The test advances calendar days directly through `TimeManager.advance_day_for_test()` and must not wait for the normal in-game clock, timers, process frames, physics frames, or per-minute/per-hour playback.

Full-year simulation reports:

- CSV output is written after the 120-day loop completes, not once per simulated day.
- Daily report: `user://simulation_reports/full_year_daily.csv`.
- Event report: `user://simulation_reports/full_year_events.csv`.
- On Windows, `user://` usually resolves to `C:\Users\<user>\AppData\Roaming\Godot\app_userdata\Project_Agricultural_life\`.
- The test prints progress every 10 simulated days: `Simulation progress: 10/120`, `20/120`, and so on.
- The summary prints the number of collected rows, executed day advances, total simulation time in milliseconds, and slowest simulated day in milliseconds.

Full-year simulation day advancement:

- `TimeManager.advance_day_for_test()` performs one direct market update for the completed day through `CommodityMarketManager.update_market_for_test_day()`.
- It enables `EventManager.process_day_synchronously_for_test`, advances the calendar once, then disables the flag.
- `day_changed` drives weather preparation, crop growth, sales rollover, and event processing.
- The event manager finishes day processing synchronously in this test mode instead of scheduling `_finish_day_event_processing()` with `call_deferred()`.
- The time of day is reset to `06:00`, and `time_changed` is emitted once after the direct day change.
- The test path intentionally avoids `CommodityMarketManager.simulate_skipped_market_hours()`, which remains available for production time skips.

Full-year simulation performance expectations:

- The default 120-day test should be measured with `Measure-Command` or the printed `Total simulation time`.
- A healthy run is expected to finish in seconds, not minutes.
- If it exceeds 10 seconds, inspect the Godot output for repeated `Simulation progress` lines, excessive production logs, duplicated `day_changed` handling, or blocked/deferred event processing.

Current crop-product integration coverage:

- All added crop items and seed items load and have matching `id` / `crop_id` values.
- Each added seed links to its crop and has `growth_days` equal to `CropData.days_to_ready`.
- Each added crop has a matching commodity registered in `CommodityMarketManager`.
- Each added crop has matching market events registered in `EventManager`.
- Each added seed has a matching shop item registered in `Data/Shop/basic_shop.tres`.
- Each added crop and seed is reachable through `SaveManager` item/crop lookup.
- Each added crop and seed is registered in silo storage.
- Inventory save/load restores the added crop and seed items.
- Storage save/load restores the added crop items.

Known crop-product test gap:

- The full gameplay loop for every added crop is not yet tested. `FarmTileLogicTest.gd` currently verifies planting, growth, readiness, and harvesting with wheat. A future test should iterate over all `CropData` resources and verify `plant_crop()`, growth to `days_to_ready`, `is_crop_ready()`, and `harvest_crop()` for each crop.

Known headless test limitation:

- `TileCropSaveTest.gd` currently expects a gameplay scene `WorldManager`. In the current headless runner setup this can fail with `WorldManager exists for tile save test` even when Event System tests pass. Treat that as a scene-fixture issue unless the world save/load flow was changed.

## Adding A Test

Create a new `.gd` file under the most specific test folder.

Use this shape:

```gdscript
extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- ExampleTest ---")

	runner.assert_true(true, "Example condition is true")
	runner.assert_eq(1 + 1, 2, "Example equality works")
```

Then register it in `Tests/TestRunner.gd` inside `run_all_tests()`:

```gdscript
_run_test_script(preload("res://Tests/Core/ExampleTest.gd").new())
```

Keep test names descriptive and keep each assertion message specific enough to identify the failing behavior from the output console.

## Assertion Helpers

`TestRunner` currently provides:

- `assert_true(value: bool, message: String)`: passes when `value` is `true`.
- `assert_eq(actual, expected, message)`: passes when `actual == expected`.

When more assertion types are needed, add them to `TestRunner` rather than duplicating comparison logic in test scripts.

## Test Data And State Hygiene

Many tests interact with autoload singletons, so tests should reset the state they mutate.

Recommended rules:

- Clear dictionaries and arrays before testing manager state, for example `SalesStatsManager.current_day_sales.clear()`.
- Restore or overwrite singleton values before assertions, for example `MoneyManager.set_money(100)`.
- Avoid relying on test execution order unless the dependency is explicit and documented.
- Prefer temporary local resources for isolated logic tests.
- Use existing data resources only when testing integration with real game content.
- Be careful with save-slot tests because they can create or delete `user://save_slot_%d.json` files.

## What To Test Next

Good next targets:

- `ToolManager` planting restrictions, watering-can usage, and harvest behavior.
- Full crop gameplay loop coverage for all crop products, not only wheat.
- `CommodityMarketManager.simulate_skipped_market_hours()` for time skips.
- `WeatherManager._water_fields_if_needed()` for rain and storm field watering.
- `WeatherManager` phase forecast generation with real `WeatherDayPatternData` resources.
- Menu and HUD panel exclusivity rules in `PlayerHUD`.
- Visual/UI verification for stacked bottom-left HUD event/news alerts.

For UI-heavy behavior, prefer small logic tests around panel state and signal connections before adding full scene interaction tests.
