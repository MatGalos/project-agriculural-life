extends Node


func _ready() -> void:
	if OS.get_cmdline_args().has("--run-tests"):
		_run_tests.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("run_tests_debug"):
		_run_tests()


func _run_tests() -> void:
	var runner := TestRunner.new()
	add_child(runner)
	runner.run_all_tests()
	var failed := runner.failed
	runner.queue_free()

	if OS.get_cmdline_args().has("--run-tests"):
		get_tree().quit(1 if failed > 0 else 0)
