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
- `HotbarDataTest.gd`: hotbar setup, first-five inventory slot mapping, and selected slot behavior.
- `SalesStatsManagerTest.gd`: sales recording, recent sales totals, and day rollover.
- `InventoryDataTest.gd`: default 25-slot inventory capacity, setup, stacking, removal, and slot movement behavior.
- `WeatherManagerTest.gd`: day phase hour boundaries, cached phase updates from time changes, phase temperatures derived from one daily base temperature, expanded daily forecast entry fields, and season weather profile modifiers for temperature and rainy/stormy pattern weights.
- `EventSystemTest.gd`: event data compatibility, multi-product modifiers, deterministic trend stacking, volatility reset behavior, season/day/weather/temperature requirements, calendar-event locks, cooldowns, once-per-season rules, daily event start limits, seed buy-price modifiers, save/load event state, duplicate-news protection, bad-harvest crop-season restrictions, and configured trigger chances for Demand Spike, Export Contract, and Market Panic.

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

- `FullYearSimulationTest.gd`: deterministic multi-seed 120-day market/event/weather simulation. Each run simulates exactly five seeds: `123456`, `234567`, `345678`, `456789`, and `567890`.
- `OversupplySalesSimulationTest.gd`: deterministic integration test for sales-driven Oversupply events across all 10 crop products.
- `CropProfitabilityAnalysisTest.gd`: static crop-economy analyzer for product prices, seed prices, growth time, yield, seasonal profitability, ROI, role classification, market scenarios, Oversupply risk, and recommendation diagnostics.
- Each seed reports exactly one calendar year: `Year 1 Spring 1` through `Year 1 Winter 30`.
- Total reported coverage is `5 seeds * 120 days = 600 days`.
- The test advances calendar days directly through `TimeManager.advance_day_for_test()` and must not wait for the normal in-game clock, timers, process frames, physics frames, or per-minute/per-hour playback.

Full-year simulation reports:

- CSV output is written after the 120-day loop completes, not once per simulated day.
- Daily report per seed: `user://simulation_reports/full_year/full_year_daily_seed_<seed>.csv`.
- Event report per seed: `user://simulation_reports/full_year/full_year_events_seed_<seed>.csv`.
- Validation report per seed: `user://simulation_reports/full_year/full_year_validation_seed_<seed>.csv`.
- Multi-seed summary: `user://simulation_reports/full_year/full_year_multi_seed_summary.csv`.
- Multi-seed aggregate: `user://simulation_reports/full_year/full_year_multi_seed_aggregate.csv`.
- On Windows, `user://` usually resolves to `C:\Users\<user>\AppData\Roaming\Godot\app_userdata\Project_Agricultural_life\`.
- The test prints progress every 10 simulated days per seed, for example `Simulation progress seed 123456: 10/120`.
- The summary prints completed seeds, passed/failed seeds, total reported days, per-seed validation errors, total simulation time in milliseconds, and slowest simulated day in milliseconds.
- Balance warnings are reported as warnings. Technical issues such as invalid prices, invalid volatility, wrong date range, duplicate fixed-date events, cooldown errors, or incorrect event counts remain validation failures.

Oversupply sales simulation reports:

- Detailed report: `user://simulation_reports/oversupply/oversupply_sales_simulation.csv`.
- Summary report: `user://simulation_reports/oversupply/oversupply_sales_summary.csv`.
- Threshold analysis: `user://simulation_reports/oversupply/oversupply_threshold_analysis.csv`.
- The test uses `SalesStatsManager.record_sale()` and the production event requirement checks.
- It covers no sales, below threshold, exact threshold, above threshold, distributed sales, product isolation, small regular sales, mass regular sales, and Wheat save/load.
- Technical validation covers sales-window summing, `>=` threshold semantics, product isolation, bearish trend, volatility modifier application, no volatility accumulation, modifier reset after event end, save/load restoration, cooldown behavior, news duplication, event duration, and price min/max bounds.
- `condition_met` in the detailed CSV is kept as a compatibility alias for `condition_ever_met`; use `condition_met_at_end` when inspecting the final state of long-running scenarios.
- `save_load_status` is `passed`, `failed`, or `not_tested`; only Wheat currently runs the active Oversupply save/load scenario.

Crop profitability analysis reports:

- Main profitability report: `user://simulation_reports/crop_profitability/crop_profitability_report.csv`.
- Product/seed suggestion report: `user://simulation_reports/crop_profitability/crop_profitability_suggestions.csv`.
- Summary report: `user://simulation_reports/crop_profitability/crop_profitability_summary.csv`.
- Seed-price balance report: `user://simulation_reports/crop_profitability/seed_price_balance_report.csv`.
- Seed-price balance summary: `user://simulation_reports/crop_profitability/seed_price_balance_summary.csv`.
- The analyzer reads real `CropData`, `SeedItemData`, `ItemPriceData`, and `CommodityData` resources.
- It does not mutate production resources. Balance changes are applied manually to `.tres` files after reviewing the reports.
- Balance warnings such as high ROI, large price changes, or Oversupply risk do not fail the test. Missing data, invalid prices, invalid yield/growth time, NaN, infinity, or CSV write failures remain validation failures.

Full-year simulation day advancement:

- The first reported row is collected before the first day advance, after the `Year 1 Spring 1` state and fixed-date events are prepared.
- The simulation then performs 119 direct day advances and collects the remaining rows, ending on `Year 1 Winter 30`.
- `TimeManager.advance_day_for_test()` performs one direct market update for the completed day through `CommodityMarketManager.update_market_for_test_day()`.
- It enables `EventManager.process_day_synchronously_for_test`, advances the calendar once, then disables the flag.
- `day_changed` drives weather preparation, crop growth, sales rollover, and event processing.
- The event manager finishes day processing synchronously in this test mode instead of scheduling `_finish_day_event_processing()` with `call_deferred()`.
- The time of day is reset to `06:00`, and `time_changed` is emitted once after the direct day change.
- The test path intentionally avoids `CommodityMarketManager.simulate_skipped_market_hours()`, which remains available for production time skips.

Full-year simulation performance expectations:

- The default five-seed 600-reported-day test should be measured with `Measure-Command` or the printed `Total simulation time`.
- A healthy run is expected to finish in seconds, not minutes.
- If it exceeds 10 seconds, inspect the Godot output for repeated `Simulation progress` lines, excessive production logs, duplicated `day_changed` handling, or blocked/deferred event processing.

Current balance values covered by tests or simulation reports:

- Demand Spike trigger chance: `0.032`.
- Export Contract trigger chance: `0.01`.
- Market Panic trigger chance: `0.02`.
- Summer Heatwave trigger chance: `0.56`.
- Heavy Rain trigger chance: `0.25`, cooldown `7` days.
- Bad Harvest cooldown: `5` days.
- `beetroot_bad_harvest` trend strength modifier: `0.024`.
- Other Bad Harvest trend strength modifier: `0.03`.
- Oversupply cooldown: `5` days.
- Oversupply thresholds: `200` for yield-1 crops and `600` for yield-3 crops.
- Crop product base sell prices:
  - Wheat `15`, Carrot `23`, Beetroot `33`, Lettuce `33`, Cabbage `50`, Pumpkin `39`.
  - Potatoe `16`, Corn `15`, Strawberry `15`, Tomatoe `13`.
- Seed buy prices:
  - Wheat `5`, Carrot `5`, Beetroot `8`, Lettuce `8`, Cabbage `12`, Pumpkin `8`.
  - Potatoe `8`, Corn `9`, Strawberry `11`, Tomatoe `10`.

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
- Visual/UI verification for stacked bottom-left HUD event/news alerts, including paper-card alignment and readable font size.
- Visual verification for the Inventory wooden panel, centered five-slot leather hotbar strip, lower 20-slot grid, readable amount badges, and spaced description panel.
- Visual verification for wooden menu panels, text-style menu buttons, paper save-slot cards, Options submenus, custom Options scroll/checkbox/dropdown controls, and save/overwrite confirmation popups.
- Manual regression pass for HUD visibility modes: gameplay, pause, phone, inventory, and storage.
- Manual pass for UI formatting consistency in money, dates, market percentages, product/seed names, weather names, input labels, and short control-action interaction prompts.

For UI-heavy behavior, prefer small logic tests around panel state and signal connections before adding full scene interaction tests.

## Manual UI Polish Checklist

Run this checklist in Godot after UI polish changes, especially when no screenshot-based test exists:

1. Start gameplay and verify that crosshair, hotbar, date/time, money, interaction prompts, and gameplay notifications appear only in normal gameplay.
2. Open Pause Menu. Confirm the world remains visible behind the blur, the blur is not doubled, the dark overlay disappears after closing, the HUD is hidden, and Save / Save and Quit actions show confirmation popups before writing.
3. Open FarmPhone and each app: News, Market, Shop, Weather, Storage, and Sell. Confirm labels use the display formatting helpers and panel backgrounds keep text readable.
4. Open Inventory and Storage/Silo. Confirm panels and slots are readable against bright and dark world backgrounds.
5. In Inventory, confirm the top leather strip is centered and contains exactly 5 hotbar slots, the lower grid contains 20 regular slots in 5 columns, and both zones together represent the 25 inventory slots.
6. In Inventory, hover and select filled and empty slots. Confirm hover/selected states are readable, item amounts stay inside their badges, and the bottom description panel has enough spacing between title, amount, and description.
7. Open Options from Main Menu and Pause Menu. Confirm the root segment list opens Sound, Controls, Graphics, and Feedback submenus; `Back to Options`, root `Back`, and Escape return to the correct previous state.
8. In Options, verify Graphics dropdown popups, the square fullscreen checkbox, and the Controls scroll line match the wooden menu style.
9. Open New Game and Load Game from their supported contexts. Confirm wooden panels, paper save-slot cards, empty/occupied slot labels, disabled empty load slots, and occupied-slot overwrite confirmation in New Game.
10. Check interaction prompts near the crosshair and bottom-left notifications for readable typography and formatting. Prompts should show as white text without a background and should not show placeholder text after starting or loading a game.
11. Confirm the date/time and money displays sit inside compact wooden plaques, and that the money value is right-aligned with inner padding.
12. Repeat the UI pass at 1280x720, 1920x1080, and 2560x1440.
