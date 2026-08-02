extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- TimeManagerTest ---")

	var saved_minute_of_day := TimeManager.current_minute_of_day

	TimeManager.current_minute_of_day = 6 * 60
	runner.assert_eq(TimeManager.get_hour(), 6, "TimeManager get_hour returns exact hour")

	TimeManager.current_minute_of_day = (6 * 60) + 59
	runner.assert_eq(TimeManager.get_hour(), 6, "TimeManager get_hour floors partial hour")
	runner.assert_eq(TimeManager.get_minute(), 59, "TimeManager get_minute returns minute remainder")

	TimeManager.current_minute_of_day = TimeManager.GAME_MINUTES_PER_DAY - 1
	runner.assert_eq(TimeManager.get_hour(), 23, "TimeManager get_hour handles last minute of day")
	runner.assert_eq(TimeManager.get_time_string(), "23:59", "TimeManager time string formats last minute of day")

	TimeManager.current_minute_of_day = saved_minute_of_day
