extends Node

const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://saves/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_auto_generate_resources()


func new_game() -> void:
	SceneManagerAutoload.clear_scene_cache()
	TimeManager.game_started = true
	TimeManager.load_save_data(_default_time_data())
	PlayerData.load_save_data(_default_player_data())
	InventoryManager._initialize_starting_items()
	# Reset barn data for new game
	BarnData.reset()
	GameUI.show_game_ui()
	SceneManagerAutoload._on_scene_change_requested(
		"res://scenes/world/WorldMap.tscn", &"farm_spawn"
	)


func save_game(slot: int) -> void:
	var world_map_data: Dictionary = {}
	var current_scene: Node = get_tree().current_scene
	if current_scene and current_scene.has_method("get_save_data"):
		world_map_data = current_scene.get_save_data()
	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"time": TimeManager.get_save_data(),
		"player": PlayerData.get_save_data(),
		"inventory": InventoryManager.get_save_data(),
		"day_turnover": DayTurnoverProcessor.get_save_data(),
		"world_map": world_map_data,
		"barn_data": BarnData.get_save_data(),
	}
	var file_path: String = SAVE_DIR + "save_%d.json" % slot
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file: %s" % file_path)
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	EventBus.save_completed.emit(slot)


func load_game(slot: int) -> void:
	var file_path: String = SAVE_DIR + "save_%d.json" % slot
	if not FileAccess.file_exists(file_path):
		push_error("Save file not found: %s" % file_path)
		return
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file: %s" % file_path)
		return
	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(json_text)
	if error != OK:
		push_error("JSON parse error: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	var version: int = data.get("version", 0)
	data = _migrate(data, version)

	# Clear scene cache so save-file data takes precedence over stale cache,
	# then pre-populate the cache with the save file's world_map data.
	# The SceneManagerAutoload will apply it automatically when the new
	# scene finishes loading – no manual load_save_data() call needed.
	SceneManagerAutoload.clear_scene_cache()

	TimeManager.game_started = true
	TimeManager.load_save_data(data.get("time", {}))
	PlayerData.load_save_data(data.get("player", {}))
	InventoryManager.load_save_data(data.get("inventory", []))
	DayTurnoverProcessor.load_save_data(data.get("day_turnover", {}))

	if data.has("barn_data"):
		BarnData.load_save_data(data.get("barn_data", {}))

	var scene_path: String = PlayerData.current_scene
	if scene_path.is_empty():
		scene_path = "res://scenes/world/WorldMap.tscn"

	SceneManagerAutoload.preload_scene_cache(scene_path, data.get("world_map", {}))

	GameUI.show_game_ui()
	SceneManagerAutoload._on_scene_change_requested(scene_path, &"")

	EventBus.load_completed.emit(slot)


func get_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for i in range(1, 4):
		var file_path: String = SAVE_DIR + "save_%d.json" % i
		if FileAccess.file_exists(file_path):
			var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var json: JSON = JSON.new()
				if json.parse(file.get_as_text()) == OK:
					var data: Dictionary = json.data
					(
						slots
						. append(
							{
								"slot": i,
								"exists": true,
								"day": data.get("time", {}).get("day", 1),
								"season": data.get("time", {}).get("current_season", &"春"),
								"reputation": data.get("player", {}).get("inn_reputation", 0.0),
							}
						)
					)
				file.close()
		else:
			slots.append({"slot": i, "exists": false})
	return slots


func delete_save(slot: int) -> void:
	var file_path: String = SAVE_DIR + "save_%d.json" % slot
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)


func quit_game() -> void:
	get_tree().quit()


func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	var current: int = from_version
	while current < SAVE_VERSION:
		current += 1
		match current:
			1:
				pass
	return data


func _auto_generate_resources() -> void:
	var tileset_dir: String = "res://resources/tilesets/"
	var required_tilesets: Array[String] = [
		"crops.tres",
		"dirt.tres",
		"rock_wood_weed.tres",
		"interior.tres",
		"town_trees.tres",
		"explore.tres"
	]
	var needs_generation: bool = false
	for ts_name: String in required_tilesets:
		if not FileAccess.file_exists(ProjectSettings.globalize_path(tileset_dir + ts_name)):
			needs_generation = true
			break
	if needs_generation:
		print("Tileset resources not found, auto-generating...")
		var gen_script: Node = load("res://scripts/editor/setup_resources.gd").new()
		add_child(gen_script)
		await get_tree().process_frame
		gen_script.queue_free()


func _default_time_data() -> Dictionary:
	return {
		"year": 1,
		"day": 1,
		"hour": 7,
		"quarter": 0,
		"meals_eaten": 0,
		"meal_cooldown": 0,
		"penalty_wake": false
	}


func _default_player_data() -> Dictionary:
	return {
		"attributes": {},
		"attribute_levels": {},
		"max_hp": 100,
		"current_hp": 100,
		"max_stamina": 50,
		"current_stamina": 50,
		"max_mana": 30,
		"current_mana": 30,
		"max_sanity": 100,
		"current_sanity": 100,
		"max_weight": 100,
		"current_weight": 0,
		"farming_level": 1,
		"farming_mastery": 1,
		"farming_xp": 0.0,
		"ranching_level": 1,
		"ranching_mastery": 1,
		"ranching_xp": 0.0,
		"cooking_level": 1,
		"cooking_mastery": 1,
		"cooking_xp": 0.0,
		"morning_training": {},
		"morning_training_wushu": "",
		"consecutive_no_eat_days": 0,
		"gold": 1000,
		"inn_reputation": 0.0,
		"inn_level": 1,
		"player_position": {"x": 0, "y": 0},
		"current_scene": "",
		"facing_direction": {"x": 0, "y": 1},
	}
