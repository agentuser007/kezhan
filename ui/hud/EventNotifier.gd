extends Control

@export var max_visible: int = 5
@export var auto_dismiss_time: float = 3.5

@onready var notification_stack: VBoxContainer = $NotificationStack

var _queue: Array[Dictionary] = []
var _active: Array[Control] = []


func _ready() -> void:
	EventBus.new_day_started.connect(_on_new_day)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.cooking_started.connect(_on_cooking_started)
	EventBus.cooking_finished.connect(_on_cooking_finished)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.animal_product_collected.connect(_on_animal_product)
	EventBus.inn_reputation_changed.connect(_on_reputation_changed)


func push(message: String, color: Color = Color(1, 1, 1, 1)) -> void:
	_queue.append({"message": message, "color": color})
	_flush_queue()


func _flush_queue() -> void:
	while _queue.size() > 0 and _active.size() < max_visible:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		return
	var entry: Dictionary = _queue.pop_front()
	var toast: PanelContainer = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.set_border_width_all(1)
	style.border_color = entry.get("color", Color(1, 1, 1, 1))
	style.set_corner_radius_all(4)
	toast.add_theme_stylebox_override("panel", style)
	toast.custom_minimum_size = Vector2(260, 0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	toast.add_child(margin)
	var label := Label.new()
	label.name = "MessageLabel"
	label.text = str(entry.get("message", ""))
	label.add_theme_color_override("font_color", entry.get("color", Color(1, 1, 1, 1)))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(label)
	toast.modulate.a = 0.0
	notification_stack.add_child(toast)
	_active.append(toast)
	var tween: Tween = create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.25)
	var timer := Timer.new()
	timer.wait_time = auto_dismiss_time
	timer.one_shot = true
	toast.add_child(timer)
	timer.timeout.connect(_dismiss.bind(toast))
	timer.start()


func _dismiss(toast: Control) -> void:
	_active.erase(toast)
	var tween: Tween = toast.create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func() -> void:
		toast.queue_free()
		_flush_queue()
	)


func _on_new_day(_day: int) -> void:
	push("第 %d 天开始" % _day, Color(0.5, 1.0, 0.5, 1))


func _on_season_changed(season: StringName) -> void:
	push("进入 %s 季" % String(season), Color(0.4, 0.9, 1.0, 1))


func _on_cooking_started(_station: StringName, recipe: StringName) -> void:
	push("开始制作: %s" % String(recipe), Color(1, 0.7, 0.3, 1))


func _on_cooking_finished(_station: StringName, recipe: StringName) -> void:
	push("制作完成: %s" % String(recipe), Color(0.3, 1.0, 0.5, 1))


func _on_crop_harvested(crop_id: StringName, amount: int) -> void:
	push("收获 %s x%d" % [String(crop_id), amount], Color(0.6, 1.0, 0.3, 1))


func _on_animal_product(animal: StringName, product: StringName, amount: int) -> void:
	push("%s产出 %s x%d" % [String(animal), String(product), amount], Color(0.9, 0.8, 0.4, 1))


func _on_reputation_changed(dish: StringName, _value: float) -> void:
	push("%s 美誉度变化" % String(dish), Color(1, 0.85, 0.5, 1))
