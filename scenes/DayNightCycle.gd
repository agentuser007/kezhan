extends CanvasLayer

@onready var morning_overlay: ColorRect = $MorningOverlay
@onready var evening_overlay: ColorRect = $EveningOverlay
@onready var night_overlay: ColorRect = $NightOverlay

var _is_indoors: bool = false


func _ready() -> void:
	EventBus.shichen_changed.connect(_on_shichen_changed)
	EventBus.scene_change_requested.connect(_on_scene_change)
	_update_overlays()


func _on_shichen_changed(_name: StringName) -> void:
	_update_overlays()


func _on_scene_change(_scene_path: String, _spawn: StringName) -> void:
	_is_indoors = (
		_scene_path.contains("inn") or _scene_path.contains("barn") or _scene_path.contains("house")
	)
	_update_overlays()


func _update_overlays() -> void:
	if _is_indoors:
		_set_all_alpha(0.0)
		return

	match TimeManager.current_shichen:
		TimeManager.Shichen.ZI, TimeManager.Shichen.HAI:
			_fade_to_night()
		TimeManager.Shichen.CHOU, TimeManager.Shichen.YIN:
			_fade_to_night()
		TimeManager.Shichen.MAO:
			_fade_to_morning()
		TimeManager.Shichen.CHEN:
			_fade_to_morning()
		TimeManager.Shichen.SI:
			_fade_to_day()
		TimeManager.Shichen.WU, TimeManager.Shichen.WEI:
			_fade_to_day()
		TimeManager.Shichen.SHEN:
			_fade_to_evening()
		TimeManager.Shichen.YOU:
			_fade_to_evening()
		TimeManager.Shichen.XU:
			_fade_to_evening()


func _fade_to_morning() -> void:
	_create_tween().tween_property(morning_overlay, "color:a", 0.35, 2.0)
	_create_tween().tween_property(evening_overlay, "color:a", 0.0, 2.0)
	_create_tween().tween_property(night_overlay, "color:a", 0.0, 2.0)


func _fade_to_day() -> void:
	_create_tween().tween_property(morning_overlay, "color:a", 0.0, 2.0)
	_create_tween().tween_property(evening_overlay, "color:a", 0.0, 2.0)
	_create_tween().tween_property(night_overlay, "color:a", 0.0, 2.0)


func _fade_to_evening() -> void:
	_create_tween().tween_property(morning_overlay, "color:a", 0.0, 2.0)
	_create_tween().tween_property(evening_overlay, "color:a", 0.25, 2.0)
	_create_tween().tween_property(night_overlay, "color:a", 0.0, 2.0)


func _fade_to_night() -> void:
	_create_tween().tween_property(morning_overlay, "color:a", 0.0, 2.0)
	_create_tween().tween_property(evening_overlay, "color:a", 0.0, 2.0)
	_create_tween().tween_property(night_overlay, "color:a", 0.75, 2.0)


func _set_all_alpha(alpha: float) -> void:
	if morning_overlay:
		morning_overlay.color.a = alpha
	if evening_overlay:
		evening_overlay.color.a = alpha
	if night_overlay:
		night_overlay.color.a = alpha


func _create_tween() -> Tween:
	return get_tree().create_tween()
