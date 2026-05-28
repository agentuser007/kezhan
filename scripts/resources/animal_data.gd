class_name AnimalData
extends Resource

enum AnimalType { CHICKEN, PIG, DUCK, SHEEP, COW, FISH }

@export var animal_type: AnimalType = AnimalType.CHICKEN
@export var display_name: String = ""
@export var ranching_level_required: int = 1
@export var daily_feed_consumption: int = 2
@export var daily_water_consumption: int = 1
@export var feed_item_id: StringName = &""
@export var product_item_id: StringName = &""
@export var product_cycle_days: int = 4
@export var base_product_amount: int = 10
@export var maturity_days: int = 4
@export var max_hunger_days: int = 8
@export var weak_threshold_days: int = 2
@export var weak_recovery_days: int = 2
@export var base_weight: float = 10.0
@export var max_weight: float = 40.0
@export var breeding_age_days: int = 30
@export var pregnancy_days: int = 48
@export var offspring_count: int = 3
@export var space_occupied: float = 1.0
@export var slaughter_drops: Dictionary = {}
