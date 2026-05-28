class_name CropData
extends Resource

enum HarvestType { ONE_TIME_PULL, ONE_TIME_CUT, INFINITE_REGROW }
enum CropTier { BASIC_VEGETABLE, BASIC_FRUIT, ADVANCED_VEGETABLE, ADVANCED_FRUIT }

@export var crop_id: StringName = &""
@export var display_name: String = ""
@export var allowed_seasons: Array[StringName] = []
@export var bonus_season: StringName = &""
@export var base_growth_days: float = 3.0
@export var regrowth_days: float = 0.0
@export var harvest_type: HarvestType = HarvestType.ONE_TIME_PULL
@export var crop_tier: CropTier = CropTier.BASIC_VEGETABLE
@export var seed_item_id: StringName = &""
@export var harvest_item_id: StringName = &""
@export var farming_level_required: int = 1
@export var base_quality: int = 10
@export var growth_stages: int = 4
