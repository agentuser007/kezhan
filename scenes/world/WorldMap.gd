extends Node2D

@export var farm_grid_width: int = 40
@export var farm_grid_height: int = 25
@export var tile_size: int = 32

var farm_tiles: Dictionary:
	get:
		return FarmData.farm_tiles

@onready var player: CharacterBody2D = $Player
@onready var crop_layer: TileMapLayer = $CropLayer
@onready var dirt_layer: TileMapLayer = $DirtLayer
@onready var junk_layer: TileMapLayer = $JunkLayer
@onready var object_layer: TileMapLayer = $ObjectLayer
@onready var background_layer: TileMapLayer = $BackgroundLayer

@onready var farm_tile_overlay: Node2D = $FarmTileOverlay


func _ready() -> void:
	EventBus.scene_change_requested.connect(_on_scene_change)
	EventBus.new_day_started.connect(_on_new_day)
	_assign_tilesets()
	_build_border_walls()
	
	if FarmData.farm_tiles.is_empty():
		print("WorldMap: Initializing global farm tiles")
		_initialize_farm_tiles()
	else:
		print("WorldMap: Restoring farm tiles from FarmData, count: ", FarmData.farm_tiles.size())
		_restore_tile_visuals()
		
	if farm_tile_overlay:
		farm_tile_overlay.setup(self)


func _assign_tilesets() -> void:
	var dirt_ts_path: String = "res://resources/tilesets/dirt.tres"
	var crops_ts_path: String = "res://resources/tilesets/crops.tres"
	var explore_ts_path: String = "res://resources/tilesets/explore.tres"
	if ResourceLoader.exists(dirt_ts_path) and dirt_layer:
		dirt_layer.tile_set = load(dirt_ts_path) as TileSet
	if ResourceLoader.exists(crops_ts_path) and crop_layer:
		crop_layer.tile_set = load(crops_ts_path) as TileSet
	if ResourceLoader.exists(explore_ts_path) and object_layer:
		object_layer.tile_set = load(explore_ts_path) as TileSet


func _build_border_walls() -> void:
	if object_layer == null or object_layer.tile_set == null:
		return
	var w: int = farm_grid_width
	var h: int = farm_grid_height
	var wall_atlas: Vector2i = Vector2i(3, 21)
	for x: int in w:
		object_layer.set_cell(Vector2i(x, 0), 0, wall_atlas)
		object_layer.set_cell(Vector2i(x, h - 1), 0, wall_atlas)
	for y: int in h:
		object_layer.set_cell(Vector2i(0, y), 0, wall_atlas)
		object_layer.set_cell(Vector2i(w - 1, y), 0, wall_atlas)
	_create_boundary_collisions(w, h)


func _create_boundary_collisions(w: int, h: int) -> void:
	var thickness: float = 8.0
	var map_pixel_w: float = w * tile_size
	var map_pixel_h: float = h * tile_size
	var walls: Array[Dictionary] = [
		{
			"pos": Vector2(map_pixel_w / 2.0, -thickness / 2.0),
			"size": Vector2(map_pixel_w + thickness * 2, thickness)
		},
		{
			"pos": Vector2(map_pixel_w / 2.0, map_pixel_h + thickness / 2.0),
			"size": Vector2(map_pixel_w + thickness * 2, thickness)
		},
		{
			"pos": Vector2(-thickness / 2.0, map_pixel_h / 2.0),
			"size": Vector2(thickness, map_pixel_h + thickness * 2)
		},
		{
			"pos": Vector2(map_pixel_w + thickness / 2.0, map_pixel_h / 2.0),
			"size": Vector2(thickness, map_pixel_h + thickness * 2)
		},
	]
	for wall_data: Dictionary in walls:
		var body: StaticBody2D = StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		body.position = wall_data.pos
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = wall_data.size
		shape.shape = rect
		body.add_child(shape)
		add_child(body)


func _initialize_farm_tiles() -> void:
	for x: int in farm_grid_width:
		for y: int in farm_grid_height:
			var coords: Vector2i = Vector2i(x, y)
			if _is_farmable_cell(coords):
				var tile = FarmTileData.new()
				FarmData.set_tile_at(coords, tile)


func _restore_tile_visuals() -> void:
	for coords: Vector2i in FarmData.farm_tiles:
		var tile: FarmTileData = FarmData.get_tile_at(coords)
		_update_dirt_visual(coords, tile)
		_update_crop_visual(coords, tile)


func _is_farmable_cell(coords: Vector2i) -> bool:
	if object_layer == null:
		return true
	var cell_source: int = object_layer.get_cell_source_id(coords)
	return cell_source == -1


func get_tile_at(coords: Vector2i) -> FarmTileData:
	return FarmData.get_tile_at(coords)


func has_junk_at(coords: Vector2i) -> bool:
	if junk_layer == null:
		return false
	return junk_layer.get_cell_source_id(coords) != -1


func till_tile(coords: Vector2i) -> bool:
	var tile: FarmTileData = get_tile_at(coords)
	if tile == null:
		return false
	if not tile.can_till():
		return false
	if has_junk_at(coords):
		return false
	if not PlayerData.take_action(1):
		return false
	tile.till()
	_update_dirt_visual(coords, tile)
	EventBus.farm_overlay_needs_update.emit()
	return true


func fertilize_tile(coords: Vector2i) -> bool:
	var tile: FarmTileData = get_tile_at(coords)
	if tile == null:
		return false
	if not tile.can_fertilize():
		return false
	if not InventoryManager.remove_item(&"Fertilizer", 1):
		return false
	if not PlayerData.take_action(1):
		return false
	tile.fertilize()
	_update_dirt_visual(coords, tile)
	EventBus.farm_overlay_needs_update.emit()
	return true


func plant_tile(coords: Vector2i, seed_id: StringName) -> bool:
	var tile: FarmTileData = get_tile_at(coords)
	if tile == null:
		return false
	if not tile.can_plant():
		return false
	if not InventoryManager.has_item(seed_id, 1):
		return false
	if not PlayerData.take_action(1):
		return false

	var stages: int = 4
	InventoryManager.remove_item(seed_id, 1)
	tile.plant(seed_id, stages)
	_update_dirt_visual(coords, tile)
	_update_crop_visual(coords, tile)
	EventBus.farm_overlay_needs_update.emit()
	return true


func water_tile(coords: Vector2i) -> bool:
	var tile: FarmTileData = get_tile_at(coords)
	if tile == null:
		return false
	if not tile.can_water():
		return false
	if not PlayerData.take_action(1):
		return false
	tile.water()
	_update_dirt_visual(coords, tile)
	EventBus.farm_overlay_needs_update.emit()
	return true


func harvest_tile(coords: Vector2i) -> bool:
	var tile: FarmTileData = get_tile_at(coords)
	if tile == null:
		return false
	if not tile.can_harvest():
		return false
	if not PlayerData.take_action(1):
		return false

	var crop_id: StringName = tile.crop_id
	var harvest_id: StringName = _get_harvest_item_id(crop_id)
	var yield_multiplier: float = PlayerData.get_farming_yield_multiplier()
	var amount: int = maxi(1, int(1.0 * yield_multiplier))

	InventoryManager.add_item(harvest_id, amount)
	PlayerData.add_farming_xp(10.0 * yield_multiplier)

	if _is_regrow_crop(crop_id):
		tile.growth_progress = 0.0
		tile.state = FarmTileData.TileState.SOWN
	else:
		tile._reset_to_tilled()

	_update_dirt_visual(coords, tile)
	_update_crop_visual(coords, tile)
	EventBus.crop_harvested.emit(crop_id, amount)
	EventBus.farm_overlay_needs_update.emit()
	return true


func clear_weeds_at(coords: Vector2i) -> bool:
	var tile: FarmTileData = get_tile_at(coords)
	if tile == null or not tile.has_weeds:
		return false
	if not PlayerData.take_action(1):
		return false
	tile.clear_weeds()
	_update_crop_visual(coords, tile)
	EventBus.farm_overlay_needs_update.emit()
	return true


func clear_pests_at(coords: Vector2i) -> bool:
	var tile: FarmTileData = get_tile_at(coords)
	if tile == null or not tile.has_pests:
		return false
	if not InventoryManager.remove_item(&"PestRemedy", 1):
		return false
	if not PlayerData.take_action(1):
		return false
	tile.clear_pests()
	_update_crop_visual(coords, tile)
	EventBus.farm_overlay_needs_update.emit()
	return true


func until_tile(coords: Vector2i) -> bool:
	var tile: FarmTileData = get_tile_at(coords)
	if tile == null:
		return false
	if tile.state == FarmTileData.TileState.WILTED:
		if not PlayerData.take_action(1):
			return false
		tile.reset_to_untilled()
		_update_dirt_visual(coords, tile)
		_update_crop_visual(coords, tile)
		EventBus.farm_overlay_needs_update.emit()
		return true
	if tile.crop_id != &"":
		return false
	if (
		tile.state
		in [
			FarmTileData.TileState.TILLED_BARREN,
			FarmTileData.TileState.TILLED_FERTILE,
			FarmTileData.TileState.WATERED
		]
	):
		if not PlayerData.take_action(1):
			return false
		tile.reset_to_untilled()
		_update_dirt_visual(coords, tile)
		EventBus.farm_overlay_needs_update.emit()
		return true
	return false


func chop_wood_at(coords: Vector2i) -> bool:
	if junk_layer == null:
		return false
	var atlas: Vector2i = junk_layer.get_cell_atlas_coords(coords)
	if atlas != Vector2i(0, 0):
		return false
	if not PlayerData.take_action(1):
		return false
	junk_layer.erase_cell(coords)
	InventoryManager.add_item(&"Firewood", 2)
	return true


func smash_stone_at(coords: Vector2i) -> bool:
	if junk_layer == null:
		return false
	var atlas: Vector2i = junk_layer.get_cell_atlas_coords(coords)
	if atlas != Vector2i(1, 0):
		return false
	if not PlayerData.take_action(1):
		return false
	junk_layer.erase_cell(coords)
	InventoryManager.add_item(&"Stone", 1)
	return true


func clear_junk_weeds_at(coords: Vector2i) -> bool:
	if junk_layer == null:
		return false
	var atlas: Vector2i = junk_layer.get_cell_atlas_coords(coords)
	if atlas != Vector2i(2, 0):
		return false
	if not PlayerData.take_action(1):
		return false
	junk_layer.erase_cell(coords)
	return true


func get_hoe_cells(facing_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [facing_cell]
	var facing: Vector2 = PlayerData.facing_direction
	if absf(facing.x) > absf(facing.y):
		cells.append(facing_cell + Vector2i(0, -1))
		cells.append(facing_cell + Vector2i(0, 1))
	else:
		cells.append(facing_cell + Vector2i(-1, 0))
		cells.append(facing_cell + Vector2i(1, 0))
	return cells


func get_circle_cells(center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			cells.append(center + Vector2i(dx, dy))
	return cells


func till_tiles(cells: Array[Vector2i]) -> int:
	var count: int = 0
	for cell: Vector2i in cells:
		var tile: FarmTileData = get_tile_at(cell)
		if tile == null:
			continue
		if not tile.can_till():
			continue
		if has_junk_at(cell):
			continue
		if not PlayerData.take_action(1):
			break
		tile.till()
		_update_dirt_visual(cell, tile)
		count += 1
	EventBus.farm_overlay_needs_update.emit()
	return count


func plant_tiles_around(center: Vector2i, seed_id: StringName) -> int:
	var cells: Array[Vector2i] = get_circle_cells(center)
	var count: int = 0
	for cell: Vector2i in cells:
		var tile: FarmTileData = get_tile_at(cell)
		if tile == null:
			continue
		if not tile.can_plant():
			continue
		if not InventoryManager.has_item(seed_id, 1):
			break
		if not PlayerData.take_action(1):
			break
		var stages: int = 4
		InventoryManager.remove_item(seed_id, 1)
		tile.plant(seed_id, stages)
		_update_dirt_visual(cell, tile)
		_update_crop_visual(cell, tile)
		count += 1
	EventBus.farm_overlay_needs_update.emit()
	return count


func water_tiles(cells: Array[Vector2i]) -> int:
	var count: int = 0
	for cell: Vector2i in cells:
		var tile: FarmTileData = get_tile_at(cell)
		if tile == null:
			continue
		if not tile.can_water():
			continue
		if not PlayerData.take_action(1):
			break
		tile.water()
		_update_dirt_visual(cell, tile)
		count += 1
	EventBus.farm_overlay_needs_update.emit()
	return count


func clear_weeds_in_cells(cells: Array[Vector2i]) -> int:
	var count: int = 0
	for cell: Vector2i in cells:
		var tile: FarmTileData = get_tile_at(cell)
		if tile == null:
			continue
		if not tile.has_weeds:
			continue
		if not PlayerData.take_action(1):
			break
		tile.clear_weeds()
		_update_crop_visual(cell, tile)
		count += 1
	EventBus.farm_overlay_needs_update.emit()
	return count


func clear_junk_weeds_in_cells(cells: Array[Vector2i]) -> int:
	if junk_layer == null:
		return 0
	var count: int = 0
	for cell: Vector2i in cells:
		var atlas: Vector2i = junk_layer.get_cell_atlas_coords(cell)
		if atlas != Vector2i(2, 0):
			continue
		if not PlayerData.take_action(1):
			break
		junk_layer.erase_cell(cell)
		count += 1
	return count


func _get_harvest_item_id(crop_id: StringName) -> StringName:
	var seed_to_crop: Dictionary = {
		&"ScallionSeeds": &"Scallion",
		&"GingerSeeds": &"Ginger",
		&"ChiliSeeds": &"Chili",
		&"WheatSeeds": &"Wheat",
		&"SweetPotatoSeeds": &"SweetPotato",
		&"SugarcaneSeeds": &"Sugarcane",
		&"GlutinousRiceSeeds": &"GlutinousRice",
		&"TurnipSeeds": &"Turnip",
		&"StrawberrySeeds": &"Strawberry",
		&"EggplantSeeds": &"Eggplant",
		&"TomatoSeeds": &"Tomato",
		&"MelonSeeds": &"Melon",
		&"PotatoSeeds": &"Potato",
		&"CornSeeds": &"Corn",
	}
	return seed_to_crop.get(crop_id, crop_id)


func _is_regrow_crop(crop_id: StringName) -> bool:
	return crop_id == &"ChiliSeeds"


func _update_dirt_visual(coords: Vector2i, tile: FarmTileData) -> void:
	if dirt_layer == null:
		return
	var atlas_coords: Vector2i = Vector2i.ZERO
	match tile.state:
		FarmTileData.TileState.UNTILLED:
			dirt_layer.erase_cell(coords)
			return
		FarmTileData.TileState.TILLED_BARREN:
			atlas_coords = Vector2i(0, 0)
		FarmTileData.TileState.TILLED_FERTILE, FarmTileData.TileState.SOWN:
			atlas_coords = Vector2i(1, 0)
		FarmTileData.TileState.WATERED:
			atlas_coords = Vector2i(2, 0)
		FarmTileData.TileState.HARVESTABLE:
			atlas_coords = Vector2i(2, 0)
		FarmTileData.TileState.WILTED:
			atlas_coords = Vector2i(0, 1)
	dirt_layer.set_cell(coords, 0, atlas_coords)


func _update_crop_visual(coords: Vector2i, tile: FarmTileData) -> void:
	if crop_layer == null:
		return
	if tile.crop_id == &"" or tile.state == FarmTileData.TileState.UNTILLED:
		crop_layer.erase_cell(coords)
		return
	if tile.state == FarmTileData.TileState.WILTED:
		crop_layer.erase_cell(coords)
		return
	var stage: int = tile.get_growth_stage_index()
	if tile.state == FarmTileData.TileState.HARVESTABLE:
		stage = tile.growth_stages - 1
	var atlas_y: int = _get_crop_atlas_row(tile.crop_id)
	var atlas_x: int = _get_crop_atlas_col(tile.crop_id, stage)
	crop_layer.set_cell(coords, 0, Vector2i(atlas_x, atlas_y))


func _get_crop_atlas_row(crop_id: StringName) -> int:
	var rows: Dictionary = {
		&"TurnipSeeds": 0,
		&"TomatoSeeds": 1,
		&"EggplantSeeds": 2,
		&"MelonSeeds": 3,
		&"WheatSeeds": 4,
		&"StrawberrySeeds": 5,
		&"PotatoSeeds": 6,
		&"CornSeeds": 7,
		&"ScallionSeeds": 0,
		&"GingerSeeds": 1,
		&"ChiliSeeds": 2,
		&"SweetPotatoSeeds": 5,
		&"SugarcaneSeeds": 3,
		&"GlutinousRiceSeeds": 4,
	}
	return rows.get(crop_id, 0)


func _get_crop_atlas_col(crop_id: StringName, stage: int) -> int:
	var right_crops: Dictionary = {
		&"MelonSeeds": 6,
		&"WheatSeeds": 6,
		&"SugarcaneSeeds": 6,
	}
	if right_crops.has(crop_id):
		return right_crops[crop_id] + stage
	return stage


func simulate_rain() -> void:
	for coords: Vector2i in farm_tiles:
		var tile: FarmTileData = farm_tiles[coords]
		if (
			tile.state
			in [
				FarmTileData.TileState.SOWN,
				FarmTileData.TileState.TILLED_FERTILE,
				FarmTileData.TileState.WATERED
			]
		):
			tile.water()
			_update_dirt_visual(coords, tile)
	EventBus.farm_overlay_needs_update.emit()


func _on_new_day(_day: int) -> void:
	_check_season_wilt()
	_spawn_random_junk()
	_spawn_random_weeds_and_pests()
	EventBus.farm_overlay_needs_update.emit()


func _check_season_wilt() -> void:
	var current_season: StringName = TimeManager.current_season
	for coords: Vector2i in farm_tiles:
		var tile: FarmTileData = farm_tiles[coords]
		if tile.crop_id == &"" or tile.state == FarmTileData.TileState.WILTED:
			continue
		var allowed: bool = _is_crop_in_season(tile.crop_id, current_season)
		if not allowed:
			tile.state = FarmTileData.TileState.WILTED
		_update_dirt_visual(coords, tile)
		_update_crop_visual(coords, tile)
	EventBus.farm_overlay_needs_update.emit()


func get_farm_stats() -> Dictionary:
	var total: int = 0
	var tilled: int = 0
	var planted: int = 0
	var harvestable: int = 0
	var wilted: int = 0
	var weeds: int = 0
	var pests: int = 0
	for coords: Vector2i in farm_tiles:
		var tile: FarmTileData = farm_tiles[coords]
		total += 1
		match tile.state:
			FarmTileData.TileState.TILLED_BARREN, FarmTileData.TileState.TILLED_FERTILE:
				if tile.crop_id == &"":
					tilled += 1
			FarmTileData.TileState.SOWN, FarmTileData.TileState.WATERED:
				planted += 1
			FarmTileData.TileState.HARVESTABLE:
				harvestable += 1
			FarmTileData.TileState.WILTED:
				wilted += 1
		if tile.has_weeds:
			weeds += 1
		if tile.has_pests:
			pests += 1
	return {
		"total": total,
		"tilled": tilled,
		"planted": planted,
		"harvestable": harvestable,
		"wilted": wilted,
		"weeds": weeds,
		"pests": pests,
	}


func get_harvestable_count() -> int:
	var count: int = 0
	for coords: Vector2i in farm_tiles:
		var tile: FarmTileData = farm_tiles[coords]
		if tile.state == FarmTileData.TileState.HARVESTABLE:
			count += 1
	return count


func get_unwatered_count() -> int:
	var count: int = 0
	for coords: Vector2i in farm_tiles:
		var tile: FarmTileData = farm_tiles[coords]
		if (
			tile.crop_id != &""
			and not tile.watered_today
			and tile.state in [FarmTileData.TileState.SOWN, FarmTileData.TileState.WATERED]
		):
			count += 1
	return count


func _is_crop_in_season(crop_id: StringName, season: StringName) -> bool:
	var season_map: Dictionary = {
		&"TurnipSeeds": [&"春", &"秋"],
		&"StrawberrySeeds": [&"春", &"夏"],
		&"EggplantSeeds": [&"夏", &"秋"],
		&"TomatoSeeds": [&"夏", &"秋"],
		&"MelonSeeds": [&"夏"],
		&"PotatoSeeds": [&"春", &"夏", &"秋"],
		&"CornSeeds": [&"夏", &"秋"],
		&"ScallionSeeds": [&"春", &"夏", &"秋", &"冬"],
		&"GingerSeeds": [&"夏", &"秋"],
		&"ChiliSeeds": [&"夏", &"秋"],
		&"WheatSeeds": [&"春", &"秋", &"冬"],
		&"SweetPotatoSeeds": [&"夏", &"秋"],
		&"SugarcaneSeeds": [&"夏", &"秋"],
		&"GlutinousRiceSeeds": [&"春", &"夏"],
	}
	var allowed: Array = season_map.get(crop_id, [&"春", &"夏", &"秋", &"冬"])
	return season in allowed


func _spawn_random_junk() -> void:
	if junk_layer == null:
		return
	for coords: Vector2i in farm_tiles:
		if randf() < 0.05:
			var tile: FarmTileData = farm_tiles[coords]
			if tile.state == FarmTileData.TileState.UNTILLED:
				if not has_junk_at(coords):
					junk_layer.set_cell(coords, 0, Vector2i(randi() % 3, 0))


func _spawn_random_weeds_and_pests() -> void:
	for coords: Vector2i in farm_tiles:
		var tile: FarmTileData = farm_tiles[coords]
		if tile.crop_id == &"" or tile.state == FarmTileData.TileState.WILTED:
			continue
		if randf() < PlayerData.get_farming_pest_chance():
			if randf() < 0.5:
				tile.has_weeds = true
			else:
				tile.has_pests = true
			_update_crop_visual(coords, tile)


func _on_scene_change(_scene_path: String, _spawn_point: StringName) -> void:
	pass



