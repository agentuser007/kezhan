class_name FarmTileData
extends Resource

enum TileState { UNTILLED, TILLED_BARREN, TILLED_FERTILE, SOWN, WATERED, HARVESTABLE, WILTED }

@export var state: TileState = TileState.UNTILLED
@export var crop_id: StringName = &""
@export var growth_progress: float = 0.0
@export var growth_stages: int = 4
@export var watered_today: bool = false
@export var fertilizer_days_remaining: int = 0
@export var has_weeds: bool = false
@export var has_pests: bool = false
@export var dry_days_count: int = 0
@export var planted_before_youshi: bool = true
@export var is_fertilized_today: bool = false
@export var weeds_cleared_after_youshi: bool = false
@export var pests_cleared_after_youshi: bool = false


func can_till() -> bool:
	return state == TileState.UNTILLED


func can_fertilize() -> bool:
	return state == TileState.TILLED_BARREN


func can_plant() -> bool:
	return state == TileState.TILLED_FERTILE or state == TileState.TILLED_BARREN


func can_water() -> bool:
	return state in [TileState.SOWN, TileState.WATERED, TileState.TILLED_FERTILE]


func can_harvest() -> bool:
	return state == TileState.HARVESTABLE


func till() -> void:
	if can_till():
		state = TileState.TILLED_BARREN


func fertilize() -> void:
	if can_fertilize():
		state = TileState.TILLED_FERTILE
		fertilizer_days_remaining = 100
		is_fertilized_today = true


func plant(crop: StringName, stages: int = 4) -> void:
	if can_plant():
		crop_id = crop
		growth_stages = stages
		growth_progress = 0.0
		state = TileState.SOWN
		planted_before_youshi = TimeManager.is_before_youshi()


func water() -> void:
	if can_water():
		watered_today = true
		if state == TileState.SOWN:
			state = TileState.WATERED


func clear_weeds() -> void:
	has_weeds = false
	if not TimeManager.is_before_youshi():
		weeds_cleared_after_youshi = true


func clear_pests() -> void:
	has_pests = false
	if not TimeManager.is_before_youshi():
		pests_cleared_after_youshi = true


func clear_wilted() -> void:
	if state == TileState.WILTED:
		_reset_to_tilled()


func _reset_to_tilled() -> void:
	state = TileState.TILLED_BARREN
	crop_id = &""
	growth_progress = 0.0
	watered_today = false
	has_weeds = false
	has_pests = false
	dry_days_count = 0


func reset_to_untilled() -> void:
	state = TileState.UNTILLED
	crop_id = &""
	growth_progress = 0.0
	watered_today = false
	has_weeds = false
	has_pests = false
	dry_days_count = 0
	fertilizer_days_remaining = 0


func get_growth_stage_index() -> int:
	if crop_id == &"":
		return -1
	return clampi(int(growth_progress), 0, growth_stages - 1)


func get_save_data() -> Dictionary:
	return {
		"state": state,
		"crop_id": String(crop_id),
		"growth_progress": growth_progress,
		"growth_stages": growth_stages,
		"watered_today": watered_today,
		"fertilizer_days": fertilizer_days_remaining,
		"has_weeds": has_weeds,
		"has_pests": has_pests,
		"dry_days_count": dry_days_count,
		"planted_before_youshi": planted_before_youshi,
	}


func load_save_data(data: Dictionary) -> void:
	state = data.get("state", TileState.UNTILLED) as TileState
	crop_id = StringName(data.get("crop_id", ""))
	growth_progress = data.get("growth_progress", 0.0)
	growth_stages = data.get("growth_stages", 4)
	watered_today = data.get("watered_today", false)
	fertilizer_days_remaining = data.get("fertilizer_days", 0)
	has_weeds = data.get("has_weeds", false)
	has_pests = data.get("has_pests", false)
	dry_days_count = data.get("dry_days_count", 0)
	planted_before_youshi = data.get("planted_before_youshi", true)
