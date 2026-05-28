extends Control

@onready var event_label: Label = $EventLabel

var _dismiss_timer: Timer = null
var _current_type: String = ""


func _ready() -> void:
	EventBus.shichen_changed.connect(_on_shichen_changed)
	EventBus.meal_time_available.connect(_on_meal_time)
	EventBus.force_sleep_triggered.connect(_on_force_sleep)
	EventBus.quarter_passed.connect(_on_quarter_passed)
	_create_timer()
	_setup_style()
	visible = false


func _create_timer() -> void:
	_dismiss_timer = Timer.new()
	_dismiss_timer.one_shot = true
	_dismiss_timer.wait_time = 5.0
	add_child(_dismiss_timer)
	_dismiss_timer.timeout.connect(_on_dismiss)


func _setup_style() -> void:
	if event_label == null:
		return
	event_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	event_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	event_label.add_theme_constant_override("outline_size", 3)
	event_label.add_theme_font_size_override("font_size", 16)


func _show_event(text: String, type: String, duration: float = 5.0) -> void:
	if event_label:
		event_label.text = text
	_current_type = type
	visible = true
	_apply_type_color(type)
	if _dismiss_timer:
		_dismiss_timer.wait_time = duration
		_dismiss_timer.start()


func _apply_type_color(type: String) -> void:
	if event_label == null:
		return
	var colors: Dictionary = {
		"shichen": Color(0.8, 0.8, 1.0, 1),
		"meal": Color(1.0, 0.9, 0.3, 1),
		"force_sleep": Color(1.0, 0.15, 0.15, 1),
		"youshi": Color(0.9, 0.7, 0.3, 1),
		"warning": Color(1.0, 0.5, 0.2, 1),
	}
	event_label.add_theme_color_override("font_color", colors.get(type, Color(1, 1, 1, 1)))


func _on_dismiss() -> void:
	visible = false
	_current_type = ""


func _on_shichen_changed(shichen_name: StringName) -> void:
	_show_event("时辰更替: %s" % String(shichen_name), "shichen", 4.0)


func _on_meal_time(meal_type: StringName) -> void:
	_show_event("%s时段 — 可以进食了" % String(meal_type), "meal", 6.0)


func _on_force_sleep() -> void:
	_show_event("寅时4刻！强制昏迷！", "force_sleep", 10.0)


func _on_quarter_passed(quarter: int) -> void:
	var hour: int = TimeManager.current_hour
	if hour == 17 and quarter == 0:
		_show_event("酉时已至 — 今日种植不再计入生长", "youshi", 6.0)
	elif hour == 3 and quarter == 3:
		_show_event("寅时将尽，请尽快就寝！", "warning", 8.0)
