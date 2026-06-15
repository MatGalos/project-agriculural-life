extends Node


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("run_tests_debug"):
		var runner := TestRunner.new()
		add_child(runner)
		runner.run_all_tests()
		runner.queue_free()
