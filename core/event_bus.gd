extends Node

signal hour_changed(hour: int)
signal shichen_changed(shichen_name: StringName)
signal quarter_passed(quarter: int)
signal day_about_to_end
signal force_sleep_triggered
signal new_day_started(day: int)
signal season_changed(season: StringName)
signal year_changed(year: int)
signal meal_time_available(meal_type: StringName)

signal player_interacted(target: Interactable)
signal interaction_highlight_changed(target: Interactable)

signal inventory_changed
signal hotbar_selection_changed(slot: int)
signal player_stats_changed

signal farm_tile_state_changed(cell_coords: Vector2i, new_state: int)
signal crop_harvested(crop_id: StringName, amount: int)
signal farm_overlay_needs_update
signal farm_info_requested

signal cooking_started(station_id: StringName, recipe_id: StringName)
signal cooking_finished(station_id: StringName, recipe_id: StringName)
signal dish_served(dish_id: StringName, quality: int)

signal animal_product_collected(animal_type: StringName, product_id: StringName, amount: int)
signal animal_state_changed(animal_id: StringName, new_state: int)

signal inn_reputation_changed(dish_id: StringName, new_value: float)

signal scene_change_requested(scene_path: String, spawn_point: StringName)
signal screen_transition_started
signal screen_transition_finished

signal notification_requested(message: String)
signal feature_unlocked(feature: StringName)

signal game_paused(is_paused: bool)
signal save_completed(slot: int)
signal load_completed(slot: int)
