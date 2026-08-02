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
- Interactive `F6` runs skip heavy simulation tests by default so they do not stress an active editor/gameplay scene. Launch with `--run-heavy-simulations` before pressing `F6` if those simulations need to run interactively.

Tests can also be run headless by launching the project with the `--run-tests` argument:

```powershell
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . -- --run-tests
```

To print every passed assertion, add `--verbose-tests`:

```powershell
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . -- --run-tests --verbose-tests
```

Use the full path to the Godot executable if `godot` is not available in `PATH`:

```powershell
cd D:\project-agriculural-life
Measure-Command {
	& 'C:\Path\To\Godot_v4.6-stable_win64.exe' --headless --path . -- --run-tests
}
```

`DebugManager` exits with code `1` when any test fails and `0` when all tests pass.
Headless `--run-tests` includes the heavy simulation tests.

When the action is pressed, results are printed to the Godot output console:

- `========== RUNNING TESTS ==========` starts the run.
- Each test prints its section name.
- Passing assertions increment `passed`; individual pass lines are printed only when the project is launched with `--verbose-tests`.
- Failing assertions increment `failed` and call `push_error()`.
- Each completed test prints one compact `PASS/FAIL <TestName> assertions=<count> failed=<count>` line.
- Skipped heavy simulations print one `SKIP <TestName> heavy simulation...` line each.
- Final totals, including skipped heavy simulations, are printed under `========== TEST RESULTS ==========`.

The runner keeps explicit local types around command-line arguments, script references, test names, and compact status strings. This avoids Godot 4.6 type-inference warnings such as `Cannot infer the type of "test_name"` when reading `get_script().resource_path`.

## Current Test Coverage

Core tests:

- `UIFormatHelperTest.gd`: money, market percentage, season date, compact ordinal season day, product/seed display name, market trend, weather display name, news category, and input label formatting.
- `FarmPhoneLayoutTest.gd`: FarmPhone scene structure, black smartphone shell nodes, 4-column/16-slot home grid, app icon labels, shared app container, hidden initial app panels, disabled Storage placeholder, and visible-text branding guardrails.
- `MarketAppLayoutTest.gd`: Market app two-view scene structure, local details back button, product list scroll container, details hero, price-history chart, compact min/max/average stats, removed product/sample count labels, and compact commodity row fields.
- `ShopAppLayoutTest.gd`: Shop app cart scene structure, money/feedback labels, product list scroll container, collapsible cart panel with `v`/`^` toggle states, clear/purchase controls, product row Add flow, editable cart quantity field, subtotal fields, and removal of immediate Buy row behavior.
- `SellAppLayoutTest.gd`: Sell app scene structure, storage product list, empty state, selected sale value summary, product sale cards, editable selected quantity field, quantity controls, Half/All controls, per-row Sell/Sell All buttons, summary Sell Selected button, and removal of the old one-click `SellOneButton` layout.
- `GameplayFeedbackTest.gd`: source-level coverage for Shop/Sell/Silo/world feedback strings, HUD duplicate-message cooldown, selected sale feedback, transfer feedback, invalid world action feedback, item-use feedback, and inventory-gain feedback.
- `UIResponsivenessSourceTest.gd`: source-level coverage for responsive FarmPhone sizing, Inventory panel/slot scaling, Silo Storage panel sizing, drop-handler parameter naming that avoids `Control.position` shadowing, typed scroll-mode enum usage for custom scroll lines, scroll-line repositioning, Options board scaling, centralized HUD bottom layout, typed HUD UI mode enum usage, and visibility helper names that avoid `CanvasLayer.is_visible` shadowing.
- `UIVisualPolishSourceTest.gd`: source-level visual polish coverage for visible UI text avoiding technical IDs, Weather forecast labels avoiding `Tomorrow`/`Day +N`, FarmPhone app safe left insets, and manual checklist coverage for left-edge clipping and actual season-date forecast labels.
- `TestRunnerBehaviorTest.gd`: source-level coverage for keeping heavy simulation tests behind the headless/explicit simulation gate, gating verbose passed-assertion output, and printing compact final summaries.
- `TimeManagerTest.gd`: current time formatting coverage for exact hours, partial-hour flooring, minute remainders, and the last minute of the day.
- `WeatherAppLayoutTest.gd`: Weather app scene structure, scroll container, Today card, Day Parts grid, Next Days container, unavailable state text, safe FarmPhone insets, compact forecast row width budget, actual season-date forecast labels with season rollover, and forecast row weather icon/label fields.
- `NewsAppLayoutTest.gd`: News app scene structure, empty state card, scroll container, card list container, adjusted FarmPhone insets, scrollbar gutter, and news card fields for icon, title, date, category, and body wrapping.
- `MoneyManagerTest.gd`: money setting, adding, spending, and failed spending.
- `StorageDataTest.gd`: storage item add/remove/count behavior.
- `HotbarDataTest.gd`: hotbar setup, first-five inventory slot mapping, and selected slot behavior.
- `SalesStatsManagerTest.gd`: sales recording, recent sales totals, day rollover, and suppressible sale debug logs for long simulations.
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
- `MarketSaveTest.gd`: commodity market prices, typed trend enum restore, volatility, and history.
- `EventSaveTest.gd`: active market event persistence.
- `CropProductIntegrationTest.gd`: integration coverage for added crop products, seeds, crop data, commodity data, market events, shop items, storage registration, and save-manager lookup.
- `FarmTileLogicTest.gd`: farm tile state transitions, planting, growth, and crop clearing.
- `TileCropSaveTest.gd`: farm tile crop data in world save/load flow.

Simulation tests:

- `FullYearSimulationTest.gd`: deterministic multi-seed 120-day market/event/weather simulation. Each run simulates exactly five seeds: `123456`, `234567`, `345678`, `456789`, and `567890`.
- `OversupplySalesSimulationTest.gd`: deterministic integration test for sales-driven Oversupply events across all 10 crop products.
- `CropProfitabilityAnalysisTest.gd`: static crop-economy analyzer for product prices, seed prices, growth time, yield, seasonal profitability, ROI, role classification, market scenarios, Oversupply risk, and recommendation diagnostics.
- Heavy simulation tests are skipped by interactive debug-key runs to avoid crashing or freezing an active editor/gameplay scene with long market/event simulations. Run them headless with `--run-tests`, or launch with `--run-heavy-simulations` before pressing `F6`.
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
- It suppresses production-style market/event/weather/sales logs during the mass scenarios so high-volume crop sales such as Corn threshold runs do not flood the Godot console.
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

- Stage 6 UI animation pass for gameplay feedback, phone apps, menu transitions, and HUD messages.
- Screenshot or viewport-rect UI tests for 1280x720, 1600x900, 1920x1080, and 2560x1440 once the Godot executable is available in automation.
- Runtime interaction tests for opening/closing all major UI panels and confirming HUD/crosshair mode restoration once a stable Godot scene fixture is available.
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
3. Open FarmPhone and confirm the black smartphone shell, simple black wallpaper, 4x4 home grid, app icons, app labels, and lower home button are readable.
4. Open FarmPhone apps from the home screen: News, Market, Shop, Weather, and Sell. Confirm the shell remains visible, app content stays inside the phone screen, left-edge titles are not clipped by the phone frame, and the home button returns to the home grid.
5. In Market, confirm the first screen is a scrollable product list. Each row should show product icon, product name, current price, and percentage change; it should not show a product count in the header.
6. In Market, click a product and confirm the details view opens inside the app. The local `<` back button should return to the product list without closing FarmPhone or invoking the phone home screen.
7. In Market details, confirm the chart is drawn from real price history, bars use green/red/neutral movement colors, min/max/average stats are readable, and there is no `Samples` count.
8. In Shop, confirm product rows show seed icon, seed name, current price, owned count, and `Add`; pressing `Add` should update the cart without immediately spending money.
9. In Shop cart, confirm each row shows editable quantity, unit price, subtotal, `-`, `+`, and remove controls. Clicking the quantity should allow typing a new value; Enter or focus loss should apply it. Quantity should not go below zero; setting it to zero should remove the row.
10. In Shop cart, confirm `Total` and `Available` are readable before purchase. `Purchase` should be disabled for an empty cart and for a cart the player cannot afford.
11. In Shop cart, collapse and expand the cart. Confirm the expanded state shows `v`, the collapsed state shows `^`, the product list gets more room while collapsed, cart contents are preserved, and `Total`, `Available`, and `Purchase` remain usable.
12. In Shop checkout, confirm an empty cart shows `Cart is empty.`, insufficient money shows `Not enough money.`, a full inventory blocks purchase with `Inventory is full.`, and a successful purchase spends money, adds all items, clears the cart, and refreshes owned counts.
13. In Sell, confirm products from Silo Storage appear as cards with icon, product name, stored quantity, current unit price, selected quantity, and selected sale value.
14. In Sell, test `-1`, `+1`, `Half`, `All`, and direct typing in the selected quantity field. Quantity should stay between `0` and the stored amount, invalid text should reset to the previous valid number, and the row subtotal plus bottom `Selected value` should update immediately.
15. In Sell, click `Sell` after selecting an amount. Confirm storage quantity decreases, money increases, sale feedback appears, and sales are still recorded for `SalesStatsManager`-driven events.
16. In Sell, click per-row `Sell All` for one product. Confirm only that product is sold and feedback appears.
17. In Sell, click summary `Sell Selected`. Confirm only the typed/selected quantities are sold, money increases by the selected value, selected quantities clear after success, and each sold product is recorded for `SalesStatsManager`-driven events.
18. In Sell, confirm empty storage shows `No products in storage.` instead of a blank list.
19. In Silo Storage, transfer an inventory product to storage and confirm `Transferred 10x Wheat to Silo.` style feedback in the footer.
20. In Silo Storage, transfer a product from storage to inventory and confirm `Transferred 10x Wheat to Inventory.` style feedback. Confirm empty lists show `Empty Storage` and `Empty Inventory`, invalid drops show `Cannot transfer item.`, and missing item transfers show `Not enough items.`
21. In gameplay, use LMB with no selected hotbar item and confirm `No tool selected.`. Use LMB while looking at nothing and confirm `Nothing to interact with.`.
22. In gameplay, try invalid tool actions and confirm concise feedback: `Cannot use this here.`, `Cannot plant here.`, `No seeds selected.`, `Need a watering can.`, `Crop is not ready.`, or `Cannot harvest this.` as appropriate.
23. In gameplay, confirm successful seed use and harvest show `Used 1x <Seed>.` and `Added 1x <Product>.` without technical item IDs.
24. Repeat one invalid action quickly and confirm duplicate HUD messages are not spammed.
25. In Weather, confirm there is no hourly forecast. The app should show Today, Day Parts with Dawn/Morning/Afternoon/Night cards, and Next Days/Weekly Forecast rows labeled with actual future season dates such as `7th Spring`, not `Day +2`.
26. In Weather, confirm temperature, rain chance, and weather icons are readable. The first letters of `Weather`, `Day Parts`, `Dawn`, `Afternoon`, and `Next Days` must not be clipped by the left edge of the phone screen. Humidity should appear only after real humidity data exists.
27. In News, confirm news items are cards with icon/category marker, title, date, category, and wrapped body text. If there are no news items, confirm the empty state says `No news yet.`.
28. In News, confirm the feed scrolls inside the phone screen when multiple cards exist, the scrollbar does not overlap card content, and the home button does not cover the last card.
29. Confirm the Storage icon is visible but disabled until storage is intentionally wired into the FarmPhone app flow. Storage/Silo should still open through its existing gameplay interaction.
30. Open Inventory and Storage/Silo. Confirm panels and slots are readable against bright and dark world backgrounds.
31. In Inventory, confirm the top leather strip is centered and contains exactly 5 hotbar slots, the lower grid contains 20 regular slots in 5 columns, and both zones together represent the 25 inventory slots.
32. In Inventory, hover and select filled and empty slots. Confirm hover/selected states are readable, item amounts stay inside their badges, and the bottom description panel has enough spacing between title, amount, and description.
33. Open Options from Main Menu and Pause Menu. Confirm the root segment list opens Sound, Controls, Graphics, and Feedback submenus; `Back to Options`, root `Back`, and Escape return to the correct previous state.
34. In Options, verify Graphics dropdown popups, the square fullscreen checkbox, and the Controls scroll line match the wooden menu style.
35. Open New Game and Load Game from their supported contexts. Confirm wooden panels, paper save-slot cards, empty/occupied slot labels, disabled empty load slots, and occupied-slot overwrite confirmation in New Game.
36. Check interaction prompts near the crosshair and bottom-left notifications for readable typography and formatting. Prompts should show as white text without a background and should not show placeholder text after starting or loading a game.
37. Confirm the date/time and money displays sit inside compact wooden plaques, and that the money value is right-aligned with inner padding.
38. Repeat the UI pass at 1280x720, 1600x900, 1920x1080, and 2560x1440.
39. In Graphics options, switch Interface Scale between Small, Medium, and Big. Confirm FarmPhone, Inventory, Silo Storage, and Options panels remain inside the viewport and keep buttons clickable.

## Manual Stage 5.4 Visual Checklist

Run this checklist in Godot after lighting, day/night, sun, or moon visual changes:

1. Start gameplay around daytime and confirm the player, house, silo, farm tiles, HUD, prompts, and FarmPhone remain readable.
2. Let time advance through night, dawn, day, evening, and back to night. Confirm transitions are smooth enough and do not jump abruptly at 05:00, 07:00, 10:00, 16:00, 18:30, 20:00, or 21:00.
3. At 05:00-07:00, confirm the sun appears low and rises upward rather than moving downward.
4. Around midday, confirm the sun is high in the sky and shadows point consistently away from the visible sun.
5. Around evening, confirm the sun descends toward the horizon and fades out before night.
6. During night, confirm the moon is visible, the sun is hidden, and the scene remains playable rather than fully black.
7. During dawn, confirm the moon fades out as the sun fades in.
8. Open FarmPhone, Inventory, and Silo Storage during day and night. Confirm CanvasLayer UI readability is unaffected by world lighting.
9. Interact with the silo and house during day and night. Confirm interaction prompts remain readable.
10. Confirm Weather VFX, audio, terrain, crop visuals, world boundaries, house model polish, silo model polish, gameplay time, economy, save/load, and UI behavior were not changed by the visual pass.
