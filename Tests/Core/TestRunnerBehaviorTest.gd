extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- TestRunnerBehaviorTest ---")

	var source := _read_file("res://Tests/TestRunner.gd").replace("\r\n", "\n")
	runner.assert_true(
		source.contains("func should_run_heavy_simulation_tests() -> bool:"),
		"TestRunner exposes a heavy simulation gate"
	)
	runner.assert_true(
		source.contains("args.has(\"--run-tests\") or args.has(\"--run-heavy-simulations\")"),
		"Heavy simulation tests run only for headless or explicit heavy simulation runs"
	)
	runner.assert_true(
		source.contains("SKIP %s heavy simulation."),
		"Interactive test runs report skipped heavy simulations"
	)
	runner.assert_true(
		source.contains("func should_print_passed_assertions() -> bool:")
		and source.contains("--verbose-tests"),
		"Passed assertion output is gated behind --verbose-tests"
	)
	runner.assert_true(
		source.contains("Tests run: ")
		and source.contains("Tests skipped: ")
		and source.contains("Assertions passed: ")
		and source.contains("Assertions failed: "),
		"TestRunner prints a compact final summary"
	)


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	var content := file.get_as_text()
	file.close()
	return content
