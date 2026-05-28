class_name AnimalTemplates


## Returns a template dictionary for creating a baby pig
static func baby_pig() -> Dictionary:
	return {
		"animal_type": &"Pig",
		"display_name": "小猪",
		"is_baby": true,
		"age_days": 0,
		"hunger_days": 0,
		"fed_today": false,
		"watered_today": false,
		"products_ready": 0,
		"cycle_days_elapsed": 0,
		"current_state": 0,
		"weak_recovery_remaining": 0,
		"daily_feed_cost": 2,
		"daily_water_cost": 1,
		"feed_item_id": &"PigFeed",
		"product_item_id": &"Pork",
		"product_cycle_days": 6,
		"base_product_amount": 5,
		"maturity_days": 8,
		"max_hunger_days": 8,
		"weak_threshold_days": 2,
		"weak_recovery_days": 2,
		"space_occupied": 1.0,
	}


## Returns a template dictionary for creating a baby chicken
static func baby_chicken() -> Dictionary:
	return {
		"animal_type": &"Chicken",
		"display_name": "小鸡",
		"is_baby": true,
		"age_days": 0,
		"hunger_days": 0,
		"fed_today": false,
		"watered_today": false,
		"products_ready": 0,
		"cycle_days_elapsed": 0,
		"current_state": 0,
		"weak_recovery_remaining": 0,
		"daily_feed_cost": 1,
		"daily_water_cost": 1,
		"feed_item_id": &"PoultryFeed",
		"product_item_id": &"Egg",
		"product_cycle_days": 4,
		"base_product_amount": 10,
		"maturity_days": 4,
		"max_hunger_days": 6,
		"weak_threshold_days": 2,
		"weak_recovery_days": 2,
		"space_occupied": 0.5,
	}
