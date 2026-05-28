extends Node

## UnlockManager — Global permission check system.
## Gates features by player level/condition. Provides is_unlocked(), get_unlock_reason(),
## and check_and_warn() for UI panels and interactables.

## Emitted when a feature becomes newly unlocked (level-up triggered).
signal feature_unlocked(feature: StringName)

## Definition of each feature's unlock requirements.
## Format: { feature_key: { "stat": stat_path, "min": min_value, "label": display_reason } }
var _requirements: Dictionary = {}

## Cache of currently unlocked features to detect new unlocks on level-up.
var _unlocked_cache: Dictionary = {}


func _ready() -> void:
	_setup_requirements()
	EventBus.player_stats_changed.connect(_on_stats_changed)
	# Build initial cache
	for feature: StringName in _requirements:
		_unlocked_cache[feature] = _check_unlocked(feature)


func _setup_requirements() -> void:
	## Define all feature unlock conditions here.
	_requirements = {
		&"fermenter": {"stat": "inn_level", "min": 1, "label": "需客栈1级"},
		&"barn_manage": {"stat": "ranching_level", "min": 1, "label": "需畜牧1级"},
		&"menu_edit": {"stat": "cooking_level", "min": 1, "label": "需烹饪1级"},
		&"cooking_advanced": {"stat": "cooking_level", "min": 3, "label": "需烹饪3级"},
		&"shop": {"stat": "inn_level", "min": 1, "label": "需客栈1级"},
		&"incubator": {"stat": "ranching_level", "min": 3, "label": "需畜牧3级"},
	}


func is_unlocked(feature: StringName) -> bool:
	## Returns true if the feature is currently unlocked.
	if not _requirements.has(feature):
		# Unknown features are considered unlocked (open by default)
		return true
	return _check_unlocked(feature)


func get_unlock_reason(feature: StringName) -> String:
	## Returns a human-readable reason string for why a feature is locked.
	## Empty string if already unlocked.
	if is_unlocked(feature):
		return ""
	var req: Dictionary = _requirements.get(feature, {})
	return req.get("label", "未解锁")


func check_and_warn(feature: StringName) -> bool:
	## Checks if a feature is unlocked. If not, shows a notification and returns false.
	## Returns true if unlocked.
	if is_unlocked(feature):
		return true
	var reason: String = get_unlock_reason(feature)
	EventBus.notification_requested.emit("功能未解锁: %s" % reason)
	return false


func _check_unlocked(feature: StringName) -> bool:
	## Internal: evaluate the unlock condition for a feature.
	var req: Dictionary = _requirements.get(feature, {})
	if req.is_empty():
		return true
	var stat_name: String = req.get("stat", "")
	var min_value: int = req.get("min", 0)
	var current_value: int = _get_stat_value(stat_name)
	return current_value >= min_value


func _get_stat_value(stat_name: String) -> int:
	## Read a stat value from PlayerData by property name.
	match stat_name:
		"inn_level":
			return PlayerData.inn_level
		"cooking_level":
			return PlayerData.cooking_level
		"ranching_level":
			return PlayerData.ranching_level
		"farming_level":
			return PlayerData.farming_level
		_:
			return 0


func _on_stats_changed() -> void:
	## When player stats change, check for newly unlocked features.
	for feature: StringName in _requirements:
		var was_unlocked: bool = _unlocked_cache.get(feature, false)
		var now_unlocked: bool = _check_unlocked(feature)
		if not was_unlocked and now_unlocked:
			_unlocked_cache[feature] = true
			feature_unlocked.emit(feature)
			EventBus.notification_requested.emit("新功能解锁: %s" % _get_feature_display_name(feature))
		elif was_unlocked != now_unlocked:
			_unlocked_cache[feature] = now_unlocked


func _get_feature_display_name(feature: StringName) -> String:
	## Returns a Chinese display name for a feature key.
	match feature:
		&"fermenter":
			return "发酵坛"
		&"barn_manage":
			return "牧场管理"
		&"menu_edit":
			return "菜单编辑"
		&"cooking_advanced":
			return "高级烹饪"
		&"shop":
			return "商店"
		&"incubator":
			return "孵化器"
		_:
			return String(feature)
