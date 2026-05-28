extends Node

enum Shichen { ZI, CHOU, YIN, MAO, CHEN, SI, WU, WEI, SHEN, YOU, XU, HAI }

const SECONDS_PER_GAME_HOUR: float = 60.0
const SECONDS_PER_GAME_QUARTER: float = 15.0
const GAME_HOURS_PER_SHICHEN: int = 2
const SHICHEN_PER_DAY: int = 12
const GAME_HOURS_PER_DAY: int = 24
const QUARTERS_PER_SHICHEN: int = 8
const DAYS_PER_WEEK: int = 4
const WEEKS_PER_SEASON: int = 6
const DAYS_PER_SEASON: int = 24
const BONUS_WEEK: int = 1
const BONUS_DAYS: int = 4
const DAYS_PER_YEAR: int = 100
const WEEKS_PER_YEAR: int = 25

const SHICHEN_NAMES: Dictionary = {
	Shichen.ZI: &"子时",
	Shichen.CHOU: &"丑时",
	Shichen.YIN: &"寅时",
	Shichen.MAO: &"卯时",
	Shichen.CHEN: &"辰时",
	Shichen.SI: &"巳时",
	Shichen.WU: &"午时",
	Shichen.WEI: &"未时",
	Shichen.SHEN: &"申时",
	Shichen.YOU: &"酉时",
	Shichen.XU: &"戌时",
	Shichen.HAI: &"亥时",
}

const SHICHEN_HOURS: Dictionary = {
	Shichen.ZI: [23, 1],
	Shichen.CHOU: [1, 3],
	Shichen.YIN: [3, 5],
	Shichen.MAO: [5, 7],
	Shichen.CHEN: [7, 9],
	Shichen.SI: [9, 11],
	Shichen.WU: [11, 13],
	Shichen.WEI: [13, 15],
	Shichen.SHEN: [15, 17],
	Shichen.YOU: [17, 19],
	Shichen.XU: [19, 21],
	Shichen.HAI: [21, 23],
}

const SEASON_ORDER: Array[StringName] = [&"春", &"夏", &"秋", &"冬", &"闰"]

var current_year: int = 1
var current_day: int = 1
var current_hour: int = 7
var current_quarter: int = 0
var current_shichen: Shichen = Shichen.CHEN
var current_season: StringName = &"春"
var current_week: int = 1
var is_nighttime: bool = false
var is_penalty_wake: bool = false
var is_sleeping: bool = false
var meals_eaten_today: int = 0
var meal_cooldown_quarters_remaining: int = 0
var game_started: bool = false

var _accumulated_real_seconds: float = 0.0
var _time_paused: bool = false
var _prev_hour: int = 7
var _prev_shichen: Shichen = Shichen.CHEN

@export var time_speed_multiplier: float = 1.0


func _ready() -> void:
	_update_derived_time()
	EventBus.scene_change_requested.connect(_on_scene_change_requested)


func _process(delta: float) -> void:
	if not game_started or _time_paused or is_sleeping:
		return
	_accumulated_real_seconds += delta * time_speed_multiplier
	var quarters_elapsed: int = int(_accumulated_real_seconds / SECONDS_PER_GAME_QUARTER)
	if quarters_elapsed > 0:
		_accumulated_real_seconds -= quarters_elapsed * SECONDS_PER_GAME_QUARTER
		for i in quarters_elapsed:
			_advance_quarter()


func _advance_quarter() -> void:
	current_quarter += 1
	EventBus.quarter_passed.emit(current_quarter)

	if current_quarter >= QUARTERS_PER_SHICHEN:
		current_quarter = 0
		_advance_hour()


func _advance_hour() -> void:
	current_hour += 1
	_prev_hour = current_hour - 1
	_check_hour_events(current_hour)
	EventBus.hour_changed.emit(current_hour)

	if current_hour >= GAME_HOURS_PER_DAY:
		current_hour = 0

	_update_shichen()
	_update_meal_cooldown()


func _update_shichen() -> void:
	var new_shichen: Shichen = _hour_to_shichen(current_hour)
	if new_shichen != current_shichen:
		_prev_shichen = current_shichen
		current_shichen = new_shichen
		is_nighttime = (current_shichen == Shichen.ZI or current_shichen == Shichen.HAI)
		EventBus.shichen_changed.emit(SHICHEN_NAMES[current_shichen])
		_check_shichen_events(current_shichen)


func _hour_to_shichen(hour: int) -> Shichen:
	if hour == 23 or hour == 0:
		return Shichen.ZI
	elif hour == 1 or hour == 2:
		return Shichen.CHOU
	elif hour == 3 or hour == 4:
		return Shichen.YIN
	elif hour == 5 or hour == 6:
		return Shichen.MAO
	elif hour == 7 or hour == 8:
		return Shichen.CHEN
	elif hour == 9 or hour == 10:
		return Shichen.SI
	elif hour == 11 or hour == 12:
		return Shichen.WU
	elif hour == 13 or hour == 14:
		return Shichen.WEI
	elif hour == 15 or hour == 16:
		return Shichen.SHEN
	elif hour == 17 or hour == 18:
		return Shichen.YOU
	elif hour == 19 or hour == 20:
		return Shichen.XU
	else:
		return Shichen.HAI


func _check_hour_events(hour: int) -> void:
	match hour:
		7:
			EventBus.meal_time_available.emit(&"早饭")
		13:
			EventBus.meal_time_available.emit(&"午饭")
		19:
			EventBus.meal_time_available.emit(&"晚饭")


func _check_shichen_events(shichen: Shichen) -> void:
	match shichen:
		Shichen.CHOU:
			EventBus.meal_time_available.emit(&"宵夜")
		Shichen.YIN:
			if current_quarter >= 4 or (current_hour == 4 and current_quarter >= 4):
				_trigger_force_sleep()
		Shichen.YOU:
			EventBus.day_about_to_end.emit()


func _trigger_force_sleep() -> void:
	is_penalty_wake = true
	EventBus.force_sleep_triggered.emit()
	start_sleep()


func _update_meal_cooldown() -> void:
	if meal_cooldown_quarters_remaining > 0:
		meal_cooldown_quarters_remaining -= 1


func start_sleep() -> void:
	is_sleeping = true
	EventBus.screen_transition_started.emit()
	await get_tree().create_timer(1.0).timeout
	await DayTurnoverProcessor.execute()


func wake_up() -> void:
	if is_penalty_wake:
		current_hour = 11
		current_quarter = 0
	else:
		current_hour = 7
		current_quarter = 0
	is_sleeping = false
	is_penalty_wake = false
	meals_eaten_today = 0
	_update_derived_time()
	EventBus.new_day_started.emit(current_day)


func can_eat() -> bool:
	if meals_eaten_today >= 4:
		return false
	if meal_cooldown_quarters_remaining > 0:
		return false
	return true


func eat_meal() -> void:
	if not can_eat():
		return
	meals_eaten_today += 1
	meal_cooldown_quarters_remaining = 16


func advance_to_next_day() -> void:
	current_day += 1
	if current_day > DAYS_PER_YEAR:
		current_day = 1
		current_year += 1
		EventBus.year_changed.emit(current_year)
	_update_season()
	_update_week()


func _update_season() -> void:
	var total_weeks: int = ((current_day - 1) / DAYS_PER_WEEK) + 1
	if total_weeks <= 6:
		current_season = &"春"
	elif total_weeks <= 12:
		current_season = &"夏"
	elif total_weeks <= 18:
		current_season = &"秋"
	elif total_weeks <= 24:
		current_season = &"冬"
	else:
		current_season = &"闰"

	var prev_season: StringName = current_season
	if (
		current_day == 1
		or current_day == DAYS_PER_SEASON + 1
		or current_day == DAYS_PER_SEASON * 2 + 1
		or current_day == DAYS_PER_SEASON * 3 + 1
		or current_day == DAYS_PER_SEASON * 4 + 1
	):
		EventBus.season_changed.emit(current_season)


func _update_week() -> void:
	current_week = ((current_day - 1) / DAYS_PER_WEEK) + 1


func _update_derived_time() -> void:
	current_shichen = _hour_to_shichen(current_hour)
	is_nighttime = (current_shichen == Shichen.ZI or current_shichen == Shichen.HAI)
	_update_season()
	_update_week()


func get_time_string() -> String:
	var display_hour: int = current_hour % 12
	if display_hour == 0:
		display_hour = 12
	var period: String = "AM" if current_hour < 12 else "PM"
	var minute: int = current_quarter * 15
	return "%d:%02d %s" % [display_hour, minute, period]


func get_shichen_name() -> StringName:
	return SHICHEN_NAMES[current_shichen]


func get_day_of_week() -> int:
	return ((current_day - 1) % DAYS_PER_WEEK) + 1


func is_before_youshi() -> bool:
	return current_hour < 17


func set_time(hour: int, quarter: int) -> void:
	current_hour = hour
	current_quarter = quarter
	_accumulated_real_seconds = 0.0
	_update_derived_time()


func pause_time() -> void:
	_time_paused = true


func resume_time() -> void:
	_time_paused = false


func get_save_data() -> Dictionary:
	return {
		"year": current_year,
		"day": current_day,
		"hour": current_hour,
		"quarter": current_quarter,
		"meals_eaten": meals_eaten_today,
		"meal_cooldown": meal_cooldown_quarters_remaining,
		"penalty_wake": is_penalty_wake,
	}


func load_save_data(data: Dictionary) -> void:
	current_year = data.get("year", 1)
	current_day = data.get("day", 1)
	current_hour = data.get("hour", 7)
	current_quarter = data.get("quarter", 0)
	meals_eaten_today = data.get("meals_eaten", 0)
	meal_cooldown_quarters_remaining = data.get("meal_cooldown", 0)
	is_penalty_wake = data.get("penalty_wake", false)
	_accumulated_real_seconds = 0.0
	_update_derived_time()


func _on_scene_change_requested(_scene_path: String, _spawn_point: StringName) -> void:
	pass
