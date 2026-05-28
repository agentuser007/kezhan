extends Control

@export var clock_hand_path: NodePath = ^"ClockFace/Hand"

@onready var day_label: Label = $DayLabel
@onready var week_label: Label = $WeekLabel
@onready var season_label: Label = $SeasonLabel
@onready var shichen_label: Label = $ShichenLabel
@onready var time_label: Label = $TimeLabel
@onready var clock_hand: Node2D = null


func _ready() -> void:
	EventBus.shichen_changed.connect(_on_shichen_changed)
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.new_day_started.connect(_on_new_day)
	EventBus.season_changed.connect(_on_season_changed)
	if clock_hand_path:
		clock_hand = get_node_or_null(clock_hand_path)
	_create_time_bg.call_deferred()
	_apply_placeholder_styles()
	_update_display()


func _create_time_bg() -> void:
	var bg := PanelContainer.new()
	bg.name = "TimeInfoBg"
	bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	bg.offset_left = 4.0
	bg.offset_top = 4.0
	bg.offset_right = 210.0
	bg.offset_bottom = 215.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.set_border_width_all(1)
	style.border_color = Color(0.5, 0.45, 0.3, 0.6)
	style.set_corner_radius_all(4)
	bg.add_theme_stylebox_override("panel", style)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parent := get_parent()
	if parent:
		parent.add_child(bg)
		parent.move_child(bg, get_index())


func _apply_placeholder_styles() -> void:
	var labels: Array[Label] = [day_label, week_label, season_label, shichen_label, time_label]
	for label: Label in labels:
		if label == null:
			continue
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_font_size_override("font_size", 16)


func _process(_delta: float) -> void:
	if clock_hand:
		var total_hours: float = float(TimeManager.current_hour) + float(TimeManager.current_quarter) / 8.0
		var angle: float = total_hours / 24.0 * 2.0 * PI - PI / 2.0
		clock_hand.rotation = angle


func _update_display() -> void:
	if day_label:
		day_label.text = "第 %d 天" % TimeManager.current_day
	if week_label:
		week_label.text = "第 %d 周" % TimeManager.current_week
	if season_label:
		season_label.text = "%s 季" % String(TimeManager.current_season)
	if shichen_label:
		shichen_label.text = "%s" % String(TimeManager.get_shichen_name())
	if time_label:
		time_label.text = "%s" % TimeManager.get_time_string()


func _on_shichen_changed(_name: StringName) -> void:
	_update_display()


func _on_hour_changed(_hour: int) -> void:
	_update_display()


func _on_new_day(_day: int) -> void:
	_update_display()


func _on_season_changed(_season: StringName) -> void:
	_update_display()
