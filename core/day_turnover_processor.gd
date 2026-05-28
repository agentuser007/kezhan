extends Node

signal summary_confirmed

var _is_processing: bool = false


func execute() -> void:
	if _is_processing:
		return
	_is_processing = true

	var farm_data: Dictionary = _collect_farm_data()
	var animal_data: Dictionary = _collect_animal_data()

	_process_farm_growth(farm_data)
	_process_animal_growth(animal_data)

	_apply_farm_growth(farm_data)

	var revenue: float = _collect_revenue()
	var reputation_change: float = _collect_reputation_change()
	var harvests: Array[String] = _collect_harvests()

	EventBus.save_completed.emit(-1)

	TimeManager.advance_to_next_day()

	if GameUI and GameUI.fade_rect:
		await GameUI.fade_out(0.4)

	var summary: Control = GameUI.get_panel(&"DaySummary")
	if summary and summary.has_method("show_summary"):
		summary.show_summary(revenue, reputation_change, harvests)
		GameUI.open_panel(summary, true)
		await summary_confirmed

	TimeManager.wake_up()
	_is_processing = false


func confirm_summary() -> void:
	summary_confirmed.emit()


func _collect_revenue() -> float:
	return 0.0


func _collect_reputation_change() -> float:
	return 0.0


func _collect_harvests() -> Array[String]:
	return []


func _collect_farm_data() -> Dictionary:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return {}
	var result: Dictionary = {}
	for coords: Vector2i in world_map.farm_tiles:
		var tile: FarmTileData = world_map.farm_tiles[coords]
		if tile.state == FarmTileData.TileState.UNTILLED:
			continue
		var key: String = "%d,%d" % [coords.x, coords.y]
		result[key] = {
			"coords": coords,
			"has_crop": tile.crop_id != &"",
			"is_wilted": tile.state == FarmTileData.TileState.WILTED,
			"watered_today": tile.watered_today,
			"has_weeds": tile.has_weeds,
			"has_pests": tile.has_pests,
			"fertilizer_days": tile.fertilizer_days_remaining,
			"planted_before_youshi": tile.planted_before_youshi,
			"growth_progress": tile.growth_progress,
			"growth_stages": tile.growth_stages,
			"dry_days_count": tile.dry_days_count,
			"crop_id": String(tile.crop_id),
			"state": tile.state,
			"weeds_cleared_after_youshi": tile.weeds_cleared_after_youshi,
			"pests_cleared_after_youshi": tile.pests_cleared_after_youshi,
		}
	return result


func _apply_farm_growth(farm_data: Dictionary) -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	for key: String in farm_data:
		var tile_data: Dictionary = farm_data[key]
		var coords: Vector2i = tile_data["coords"]
		var tile: FarmTileData = world_map.get_tile_at(coords)
		if tile == null:
			continue
		tile.watered_today = tile_data.get("watered_today", false)
		tile.has_weeds = tile_data.get("has_weeds", false)
		tile.has_pests = tile_data.get("has_pests", false)
		tile.fertilizer_days_remaining = tile_data.get("fertilizer_days", 0)
		tile.dry_days_count = tile_data.get("dry_days_count", 0)
		tile.growth_progress = tile_data.get("growth_progress", 0.0)
		tile.weeds_cleared_after_youshi = tile_data.get("weeds_cleared_after_youshi", false)
		tile.pests_cleared_after_youshi = tile_data.get("pests_cleared_after_youshi", false)

		if tile_data.get("is_wilted", false) and tile.state != FarmTileData.TileState.WILTED:
			tile.state = FarmTileData.TileState.WILTED

		if tile.crop_id != &"" and tile.state != FarmTileData.TileState.WILTED:
			var stages: int = tile.growth_stages
			if (
				tile.growth_progress >= float(stages)
				and tile.state != FarmTileData.TileState.HARVESTABLE
			):
				tile.state = FarmTileData.TileState.HARVESTABLE

		world_map._update_dirt_visual(coords, tile)
		world_map._update_crop_visual(coords, tile)


func _get_world_map() -> Node2D:
	var current_scene: Node = get_tree().current_scene
	if current_scene and current_scene.has_node("DirtLayer"):
		return current_scene
	return null


func _collect_animal_data() -> Dictionary:
	return {}


func _process_farm_growth(farm_data: Dictionary) -> void:
	for cell_key: String in farm_data:
		var tile_data: Dictionary = farm_data[cell_key]
		if not tile_data.get("has_crop", false):
			continue
		if tile_data.get("is_wilted", false):
			continue

		var growth_added: float = 0.0
		var is_watered: bool = tile_data.get("watered_today", false)
		var has_weeds: bool = tile_data.get("has_weeds", false)
		var has_pests: bool = tile_data.get("has_pests", false)
		var is_fertile: bool = tile_data.get("fertilizer_days", 0) > 0
		var planted_before_youshi: bool = tile_data.get("planted_before_youshi", true)

		if not is_watered:
			tile_data["dry_days_count"] = tile_data.get("dry_days_count", 0) + 1
			if tile_data["dry_days_count"] >= 4:
				tile_data["is_wilted"] = true
				continue
		else:
			tile_data["dry_days_count"] = 0

		if is_fertile:
			if planted_before_youshi:
				growth_added = 1.0
			else:
				growth_added = 0.5
		else:
			if planted_before_youshi:
				growth_added = 0.5
			else:
				growth_added = 0.25

		if has_weeds:
			var weeds_cleared_after_youshi: bool = tile_data.get(
				"weeds_cleared_after_youshi", false
			)
			if weeds_cleared_after_youshi:
				growth_added *= 0.5
				tile_data["will_spawn_weeds_tomorrow"] = true

		if has_pests:
			var pests_cleared_after_youshi: bool = tile_data.get(
				"pests_cleared_after_youshi", false
			)
			if pests_cleared_after_youshi:
				growth_added *= 0.5

		tile_data["growth_progress"] = tile_data.get("growth_progress", 0.0) + growth_added
		tile_data["watered_today"] = false

		if tile_data.get("fertilizer_days", 0) > 0:
			tile_data["fertilizer_days"] -= 1

		if tile_data.get("will_spawn_weeds_tomorrow", false):
			tile_data["has_weeds"] = true
			tile_data["will_spawn_weeds_tomorrow"] = false


func _process_animal_growth(animal_data: Dictionary) -> void:
	for animal_id: String in animal_data:
		var data: Dictionary = animal_data[animal_id]
		var is_fed: bool = data.get("fed_today", false)
		var is_watered: bool = data.get("watered_today", false)
		var hunger_days: int = data.get("hunger_days", 0)

		if not is_fed or not is_watered:
			hunger_days += 1
			data["hunger_days"] = hunger_days
			data["growth_paused"] = true

			if hunger_days >= 2:
				data["is_weak"] = true
				data["weak_recovery_days"] = 2

			var animal_type: StringName = data.get("type", &"")
			if animal_type == &"pig" and hunger_days >= 8:
				data["is_dead"] = true
				continue
			if animal_type == &"chicken" and hunger_days >= 8:
				data["is_dead"] = true
				continue
		else:
			if data.get("is_weak", false):
				var recovery_days: int = data.get("weak_recovery_days", 2)
				recovery_days -= 1
				data["weak_recovery_days"] = recovery_days
				if recovery_days <= 0:
					data["is_weak"] = false
					data["growth_paused"] = false
			else:
				data["growth_paused"] = false
				data["hunger_days"] = 0

		data["fed_today"] = false
		data["watered_today"] = false

		if data.get("type", &"") == &"pig" and not data.get("growth_paused", false):
			if not data.get("is_breeding_pig", false):
				var age_days: int = data.get("age_days", 0)
				age_days += 1
				data["age_days"] = age_days
				if age_days <= 24:
					var weight: float = data.get("weight", 10.0)
					var growth_coeff: float = 1.0 + (age_days * 0.02)
					weight += growth_coeff
					data["weight"] = weight
				if age_days >= 30:
					data["is_breeding_pig"] = true

			if data.get("is_breeding_pig", false) and not data.get("is_pregnant", false):
				if data.get("barn_occupancy", 0) < 10:
					if randf() < 0.3:
						data["is_pregnant"] = true
						data["pregnancy_days"] = 0

			if data.get("is_pregnant", false):
				var preg_days: int = data.get("pregnancy_days", 0)
				preg_days += 1
				data["pregnancy_days"] = preg_days
				if preg_days >= 48:
					data["is_pregnant"] = false
					data["pregnancy_days"] = 0
					data["piglets_to_spawn"] = 3

		if data.get("type", &"") == &"chicken" and not data.get("growth_paused", false):
			if data.get("is_chick", false):
				var chick_days: int = data.get("chick_days", 0)
				chick_days += 1
				data["chick_days"] = chick_days
				if chick_days >= 4:
					data["is_chick"] = false
			else:
				var egg_cycle: int = data.get("egg_cycle_days", 0)
				egg_cycle += 1
				data["egg_cycle_days"] = egg_cycle
				if egg_cycle >= 4:
					data["egg_cycle_days"] = 0
					data["eggs_ready"] = data.get("eggs_ready", 0) + 10

	EventBus.animal_state_changed.emit(&"all", 0)


func get_save_data() -> Dictionary:
	return {"is_processing": _is_processing}


func load_save_data(_data: Dictionary) -> void:
	_is_processing = false
