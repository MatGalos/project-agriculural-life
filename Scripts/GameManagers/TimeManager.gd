extends Node

signal time_changed
signal day_changed
signal month_changed
signal year_changed
signal season_changed

const REAL_SECONDS_PER_GAME_DAY := 5.0 * 60.0
const GAME_MINUTES_PER_DAY := 24 * 60
const DAYS_PER_MONTH := 30
const MONTHS_PER_YEAR := 4

var current_minute_of_day := 6 * 60
var current_day := 1
var current_month := 1
var current_year := 1

var is_time_running := true

var _minute_accumulator := 0.0

func _process(delta: float) -> void:
	if not is_time_running:
		return

	var game_minutes_per_real_second := GAME_MINUTES_PER_DAY / REAL_SECONDS_PER_GAME_DAY
	_minute_accumulator += delta * game_minutes_per_real_second

	while _minute_accumulator >= 1.0:
		_minute_accumulator -= 1.0
		_add_minutes(1)

func _add_minutes(minutes: int) -> void:
	current_minute_of_day += minutes

	while current_minute_of_day >= GAME_MINUTES_PER_DAY:
		current_minute_of_day -= GAME_MINUTES_PER_DAY
		_advance_day()

	time_changed.emit()

func _advance_day() -> void:
	current_day += 1

	if current_day > DAYS_PER_MONTH:
		current_day = 1
		_advance_month()

	day_changed.emit()

func _advance_month() -> void:
	var previous_season := get_season_name()

	current_month += 1

	if current_month > MONTHS_PER_YEAR:
		current_month = 1
		_advance_year()

	month_changed.emit()

	if previous_season != get_season_name():
		season_changed.emit()

func _advance_year() -> void:
	current_year += 1
	year_changed.emit()

func get_hour() -> int:
	return current_minute_of_day / 60

func get_minute() -> int:
	return current_minute_of_day % 60

func get_time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]

func get_season_name() -> String:
	match current_month:
		1:
			return get_current_season_display_name()
		2:
			return get_current_season_display_name()
		3:
			return get_current_season_display_name()
		4:
			return get_current_season_display_name()
		_:
			return "Unknown"

func get_date_string() -> String:
	return "%s of %s, Year %d" % [
		get_ordinal_day(),
		get_season_name(),
		current_year
	]

func get_day_progress() -> float:
	return float(current_minute_of_day) / float(GAME_MINUTES_PER_DAY)

func skip_to_morning() -> void:
	var previous_day := current_day
	var previous_hour := get_hour()

	if get_hour() < 6:
		current_minute_of_day = 6 * 60
	else:
		CommodityMarketManager.simulate_skipped_market_hours(previous_day, previous_hour, previous_day, 17)
		_advance_day()
		current_minute_of_day = 6 * 60

	time_changed.emit()

func get_ordinal_day() -> String:
	var suffix := "th"

	if current_day % 100 < 11 or current_day % 100 > 13:
		match current_day % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"

	return "%d%s" % [current_day, suffix]

func get_current_season() -> SeasonData.Season:
	match current_month:
		1:
			return SeasonData.Season.SPRING
		2:
			return SeasonData.Season.SUMMER
		3:
			return SeasonData.Season.AUTUMN
		4:
			return SeasonData.Season.WINTER
		_:
			return SeasonData.Season.SPRING

func get_current_season_display_name() -> String:
	match get_current_season():
		SeasonData.Season.SPRING:
			return "Spring"
		SeasonData.Season.SUMMER:
			return "Summer"
		SeasonData.Season.AUTUMN:
			return "Autumn"
		SeasonData.Season.WINTER:
			return "Winter"
		_:
			return "Unknown"
