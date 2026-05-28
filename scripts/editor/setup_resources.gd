extends Node

const TILESET_DIR := "res://resources/tilesets/"
const RES_DIR := "res://resources/"


func _ready() -> void:
	_ensure_dirs()
	_gen_crops()
	_gen_dirt()
	_gen_rock_wood_weed()
	_gen_interior()
	_gen_town_trees()
	_gen_explore()
	print("\n=== TILESET RESOURCES GENERATED ===\n")


func _ensure_dirs() -> void:
	var dir := DirAccess.open("res://")
	for d: String in ["resources", "resources/tilesets"]:
		if not dir.dir_exists(d):
			dir.make_dir(d)


func _save(res: Resource, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	if err == OK:
		print("  [OK] " + path)
	else:
		push_error("  [FAIL] " + path + " error=" + str(err))


func _make_tileset(
	texture_path: String,
	tile_size: Vector2i,
	tile_coords: Array[Vector2i],
	_margin: Vector2i = Vector2i.ZERO,
	separation: Vector2i = Vector2i.ZERO,
	physics_layers: int = 0
) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = tile_size
	for i in range(physics_layers):
		ts.add_physics_layer()
	var source := TileSetAtlasSource.new()
	source.texture = load(texture_path)
	source.separation = separation
	source.texture_region_size = tile_size
	for c: Vector2i in tile_coords:
		source.create_tile(c)
	ts.add_source(source, ts.get_next_source_id())
	return ts


func _add_rect_tiles(
	source: TileSetAtlasSource,
	tile_size: Vector2i,
	rects: Array[Dictionary],
	_set_offsets: bool = true
) -> void:
	for info: Dictionary in rects:
		var rx: int = int(info["x"])
		var ry: int = int(info["y"])
		var col: int = snappedi(rx, tile_size.x) / tile_size.x
		var row: int = snappedi(ry, tile_size.y) / tile_size.y
		var coords := Vector2i(col, row)
		if not source.has_tile(coords):
			source.create_tile(coords)


func _add_collision_rect(
	source: TileSetAtlasSource, coords: Vector2i, size: Vector2, offset: Vector2 = Vector2.ZERO
) -> void:
	var td: TileData = source.get_tile_data(coords, 0)
	if td == null:
		return
	var points := PackedVector2Array(
		[
			offset,
			Vector2(offset.x + size.x, offset.y),
			Vector2(offset.x + size.x, offset.y + size.y),
			Vector2(offset.x, offset.y + size.y)
		]
	)
	td.add_collision_polygon(0)
	var idx: int = td.get_collision_polygons_count(0) - 1
	td.set_collision_polygon_points(0, idx, points)
	td.set_collision_polygon_one_way(0, idx, false)


# ============================================================
# CROPS TILESET
# ============================================================
func _gen_crops() -> void:
	print("Generating crops tileset...")
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)

	var source := TileSetAtlasSource.new()
	source.texture = load("res://tilesets/Crops.png")
	source.texture_region_size = Vector2i(16, 16)

	var crop_rows: Dictionary = {
		"Turnip": 0,
		"Tomato": 1,
		"Eggplant": 2,
		"Melon": 3,
		"Wheat": 4,
		"Strawberry": 5,
		"Potato": 6,
		"Corn": 7
	}
	var crop_left_cols: Dictionary = {
		"Turnip": 0, "Tomato": 0, "Eggplant": 0, "Strawberry": 0, "Potato": 0, "Corn": 0
	}
	var crop_right_cols: Dictionary = {"Melon": 6, "Wheat": 6}

	for crop_name: String in crop_rows:
		var row: int = crop_rows[crop_name]
		if crop_name in crop_left_cols:
			var start_col: int = crop_left_cols[crop_name]
			for stage: int in range(6):
				var coords := Vector2i(start_col + stage, row)
				source.create_tile(coords)
				var td: TileData = source.get_tile_data(coords, 0)
				if td:
					td.z_index = 1
		elif crop_name in crop_right_cols:
			var start_col: int = crop_right_cols[crop_name]
			for stage: int in range(6):
				var coords := Vector2i(start_col + stage, row)
				source.create_tile(coords)
				var td: TileData = source.get_tile_data(coords, 0)
				if td:
					td.z_index = 1

	ts.add_source(source, ts.get_next_source_id())
	_save(ts, TILESET_DIR + "crops.tres")


# ============================================================
# DIRT TILESET
# ============================================================
func _gen_dirt() -> void:
	print("Generating dirt tileset...")
	var coords: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
	]
	var ts := _make_tileset("res://tilesets/terrain.png", Vector2i(32, 32), coords)

	_save(ts, TILESET_DIR + "dirt.tres")


# ============================================================
# ROCK WOOD WEED TILESET
# ============================================================
func _gen_rock_wood_weed() -> void:
	print("Generating rock_wood_weed tileset...")
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = load("res://tilesets/RockWoodWeedsImg.png")
	source.texture_region_size = Vector2i(32, 32)

	var tiles: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
	]
	for c: Vector2i in tiles:
		source.create_tile(c)

	ts.add_source(source, ts.get_next_source_id())

	_add_collision_rect(source, Vector2i(0, 0), Vector2(28, 28))
	_add_collision_rect(source, Vector2i(1, 0), Vector2(28, 28))
	_add_collision_rect(source, Vector2i(0, 1), Vector2(28, 28))
	_add_collision_rect(source, Vector2i(1, 1), Vector2(28, 28))

	_save(ts, TILESET_DIR + "rock_wood_weed.tres")


# ============================================================
# INTERIOR TILESET (combined tiles + items)
# ============================================================
func _gen_interior() -> void:
	print("Generating interior tileset...")
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = load("res://tilesets/interior/open_tileset.png")
	source.texture_region_size = Vector2i(32, 32)

	var interior_rects: Array[Dictionary] = [
		{"name": "Window", "x": 64, "y": 0},
		{"name": "FloorTile", "x": 160, "y": 0},
		{"name": "FloorTile2", "x": 192, "y": 0},
		{"name": "FloorTile3", "x": 416, "y": 416},
		{"name": "FloorTile4", "x": 672, "y": 160},
		{"name": "FloorTile5", "x": 736, "y": 160},
		{"name": "Ceiling", "x": 32, "y": 32},
		{"name": "Ceiling2", "x": 64, "y": 32},
		{"name": "Ceiling3", "x": 96, "y": 32},
		{"name": "Ceiling4", "x": 128, "y": 32},
		{"name": "Ceiling5", "x": 160, "y": 32},
		{"name": "Ceiling6", "x": 192, "y": 32},
		{"name": "Ceiling7", "x": 224, "y": 32},
		{"name": "Ceiling8", "x": 256, "y": 32},
		{"name": "Ceiling9", "x": 288, "y": 32},
		{"name": "Ceiling10", "x": 320, "y": 32},
		{"name": "Ceiling11", "x": 160, "y": 64},
		{"name": "Ceiling12", "x": 320, "y": 64},
		{"name": "CeilingToWall", "x": 0, "y": 32},
		{"name": "Wall", "x": 0, "y": 64},
		{"name": "Wall2", "x": 32, "y": 63},
		{"name": "Wall3", "x": 64, "y": 63},
		{"name": "Wall4", "x": 96, "y": 64},
		{"name": "Wall5", "x": 352, "y": 64},
		{"name": "Wall6", "x": 352, "y": 32},
		{"name": "Wall7", "x": 448, "y": 64},
		{"name": "Fridge", "x": 0, "y": 96},
		{"name": "Fridge2", "x": 0, "y": 128},
		{"name": "Stove", "x": 32, "y": 96},
		{"name": "Stove2", "x": 32, "y": 128},
		{"name": "Stove3", "x": 128, "y": 97},
		{"name": "Stove4", "x": 128, "y": 128},
		{"name": "Stove5", "x": 160, "y": 97},
		{"name": "Stove6", "x": 160, "y": 128},
		{"name": "Bookshelf", "x": 224, "y": 96},
		{"name": "Bookshelf2", "x": 224, "y": 128},
		{"name": "Bookshelf3", "x": 256, "y": 96},
		{"name": "Bookshelf4", "x": 256, "y": 128},
		{"name": "Bed", "x": 416, "y": 97},
		{"name": "Bed2", "x": 447, "y": 97},
		{"name": "Bed3", "x": 416, "y": 129},
		{"name": "Bed4", "x": 447, "y": 129},
		{"name": "Bed5", "x": 416, "y": 161},
		{"name": "Bed6", "x": 447, "y": 161},
		{"name": "Table", "x": 64, "y": 96},
		{"name": "Table2", "x": 96, "y": 96},
		{"name": "Table3", "x": 64, "y": 128},
		{"name": "Table4", "x": 96, "y": 128},
		{"name": "Plant", "x": 224, "y": 161},
		{"name": "Plant2", "x": 224, "y": 191},
	]

	_add_rect_tiles(source, Vector2i(32, 32), interior_rects)

	ts.add_source(source, ts.get_next_source_id())

	var wall_coords: Array[Vector2i] = [
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2),
		Vector2i(3, 2),
		Vector2i(11, 2),
		Vector2i(14, 2),
	]
	for wc: Vector2i in wall_coords:
		_add_collision_rect(source, wc, Vector2(32, 32))

	_save(ts, TILESET_DIR + "interior.tres")


# ============================================================
# TOWN & TREES TILESET
# ============================================================
func _gen_town_trees() -> void:
	print("Generating town_trees tileset...")
	var ts := TileSet.new()
	ts.tile_size = Vector2i(48, 48)
	ts.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = load("res://tilesets/Pokemon tiles.png")
	source.texture_region_size = Vector2i(48, 48)

	var tree_coords: Array[Vector2i] = []
	for col: int in [0, 1, 2, 3, 6, 7, 8, 9]:
		tree_coords.append(Vector2i(col, 0))
	for col: int in [0, 1, 2, 3, 5, 6, 7]:
		tree_coords.append(Vector2i(col, 3))

	var ground_coords: Array[Vector2i] = [
		Vector2i(5, 5),
		Vector2i(7, 5),
		Vector2i(8, 5),
		Vector2i(11, 5),
		Vector2i(12, 5),
		Vector2i(13, 5),
		Vector2i(14, 5),
	]

	var all_coords: Array[Vector2i] = []
	all_coords.append_array(tree_coords)
	all_coords.append_array(ground_coords)

	for c: Vector2i in all_coords:
		source.create_tile(c)

	ts.add_source(source, ts.get_next_source_id())

	for tc: Vector2i in tree_coords:
		_add_collision_rect(source, tc, Vector2(32, 40), Vector2(0, 8))

	_save(ts, TILESET_DIR + "town_trees.tres")


# ============================================================
# EXPLORE TILESET
# ============================================================
func _gen_explore() -> void:
	print("Generating explore tileset...")
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = load("res://tilesets/houseTiles.png")
	source.texture_region_size = Vector2i(32, 32)

	var coords: Array[Vector2i] = []
	for row: int in range(3):
		for col: int in range(3):
			coords.append(Vector2i(col, row + 1))
	coords.append(Vector2i(13, 1))
	coords.append(Vector2i(13, 3))
	for col: int in range(3):
		for row: int in range(3):
			coords.append(Vector2i(col + 3, row + 5))
	for col: int in range(3):
		for row: int in range(3):
			coords.append(Vector2i(col + 3, row + 8))
	coords.append(Vector2i(3, 10))
	coords.append(Vector2i(4, 10))
	coords.append(Vector2i(3, 11))
	coords.append(Vector2i(5, 10))
	coords.append(Vector2i(5, 11))
	coords.append(Vector2i(3, 21))

	for c: Vector2i in coords:
		if not source.has_tile(c):
			source.create_tile(c)

	ts.add_source(source, ts.get_next_source_id())

	_add_collision_rect(source, Vector2i(3, 21), Vector2(32, 32))

	_save(ts, TILESET_DIR + "explore.tres")


# ============================================================
# PLAYER SPRITE FRAMES
# ============================================================
func _gen_player_sprite_frames() -> void:
	print("Generating player sprite frames...")
	var sf := SpriteFrames.new()

	var A := "res://player/animations/"
	var _idle := A + "idle/"
	var _walk := A + "walking/"
	var _axe := A + "axe/"
	var _hoe := A + "hoe/"
	var _hammer := A + "hammer/"
	var _sickle := A + "sickle/"
	var _water := A + "watering/"
	var _hold := A + "hold/"
	var _bag := A + "bag/"
	var _seeds := A + "seeds/"
	var _pass := A + "passingOut/"

	_add_anim(sf, "idle_down", true, 5.0, [_idle + "Idle Down.png"])
	_add_anim(sf, "idle_up", true, 5.0, [_idle + "Idle Up.png"])
	_add_anim(sf, "idle_left", true, 5.0, [_idle + "Idle Left.png"])

	_add_anim(sf, "walk_down", true, 5.0, [_walk + "Down4.png", _walk + "Down5.png"])
	_add_anim(sf, "walk_up", true, 5.0, [_walk + "Up1.png", _walk + "Up2.png"])
	_add_anim(sf, "walk_left", true, 5.0, [_walk + "left1.png", _walk + "left2.png"])

	_add_anim(sf, "axe_down", false, 12.5, _seq(_axe, "axeDown", 1, 12) + [_idle + "Idle Down.png"])
	_add_anim(sf, "axe_up", false, 12.5, _seq(_axe, "axeUp", 1, 12) + [_idle + "Idle Up.png"])
	_add_anim(sf, "axe_left", false, 12.5, _seq(_axe, "axeLeft", 1, 12) + [_idle + "Idle Left.png"])

	_add_anim(sf, "hoe_down", false, 12.5, _seq(_hoe, "hoeDown", 1, 11) + [_idle + "Idle Down.png"])
	_add_anim(sf, "hoe_up", false, 12.5, _seq(_hoe, "hoeUp", 1, 11) + [_idle + "Idle Up.png"])
	_add_anim(sf, "hoe_left", false, 12.5, _seq(_hoe, "hoeLeft", 1, 11) + [_idle + "Idle Left.png"])

	_add_anim(
		sf,
		"hammer_down",
		false,
		12.5,
		_seq(_hammer, "hammerDown", 1, 12) + [_idle + "Idle Down.png"]
	)
	_add_anim(
		sf, "hammer_up", false, 12.5, _seq(_hammer, "hammerUp", 1, 12) + [_idle + "Idle Up.png"]
	)
	_add_anim(
		sf,
		"hammer_left",
		false,
		12.5,
		_seq(_hammer, "hammerLeft", 1, 12) + [_idle + "Idle Left.png"]
	)

	_add_anim(
		sf,
		"sickle_down",
		false,
		12.5,
		_seq(_sickle, "sickleDown", 1, 11) + [_idle + "Idle Down.png"]
	)
	_add_anim(
		sf, "sickle_up", false, 12.5, _seq(_sickle, "sickleUp", 1, 11) + [_idle + "Idle Up.png"]
	)
	_add_anim(
		sf,
		"sickle_left",
		false,
		12.5,
		_seq(_sickle, "sickleLeft", 1, 11) + [_idle + "Idle Left.png"]
	)

	var water_up_frames: Array[String] = _seq(_water, "waterUp", 1, 13)
	_add_anim(
		sf,
		"water_up",
		false,
		12.5,
		water_up_frames + water_up_frames.slice(11, 0).slice(0, 8) + [_idle + "Idle Up.png"]
	)

	var water_down_frames: Array[String] = _seq(_water, "waterDown", 1, 13)
	_add_anim(
		sf,
		"water_down",
		false,
		12.5,
		(
			water_down_frames
			+ [
				_water + "waterDown13Inverted.png",
				_water + "waterDown13Inverted.png",
				_water + "waterDown12Inverted.png",
				_water + "waterDown12Inverted.png"
			]
			+ water_down_frames.slice(11, 8)
			+ [_idle + "Idle Down.png"]
		)
	)

	var water_left_frames: Array[String] = _seq(_water, "waterLeft", 1, 13)
	_add_anim(
		sf,
		"water_left",
		false,
		12.5,
		(
			water_left_frames
			+ [
				_water + "waterLeft13.png",
				_water + "waterLeft13.png",
				_water + "waterLeft12.png",
				_water + "waterLeft12.png"
			]
			+ water_left_frames.slice(11, 8)
			+ [_idle + "Idle Left.png"]
		)
	)

	_add_anim(
		sf,
		"sickle_circle",
		false,
		7.0,
		_seq(_sickle, "sickleCircle", 1, 4) + [_idle + "Idle Down.png"]
	)
	_add_anim(sf, "seeds", false, 5.0, _seq(_seeds, "seeds", 1, 3) + [_idle + "Idle Down.png"])

	_add_anim(sf, "hold_idle_down", true, 5.0, [_hold + "holdDownIdle.png"])
	_add_anim(sf, "hold_idle_up", true, 5.0, [_hold + "holdUpIdle.png"])
	_add_anim(sf, "hold_idle_left", true, 5.0, [_hold + "holdLeftIdle.png"])

	_add_anim(
		sf, "hold_walk_down", true, 5.0, [_hold + "holdDownWalk1.png", _hold + "holdDownWalk2.png"]
	)
	_add_anim(sf, "hold_walk_up", true, 5.0, [_hold + "holdUpWalk1.png", _hold + "holdUpWalk2.png"])
	_add_anim(
		sf, "hold_walk_left", true, 5.0, [_hold + "holdLeftWalk1.png", _hold + "holdLeftWalk2.png"]
	)

	_add_anim(
		sf,
		"pickup_down",
		false,
		7.5,
		[
			_hold + "pickupDown1.png",
			_hold + "pickupDown1.png",
			_hold + "pickupDown1.png",
			_hold + "holdDownIdle.png"
		]
	)
	_add_anim(
		sf,
		"pickup_up",
		false,
		7.5,
		[
			_hold + "pickupUp1.png",
			_hold + "pickupUp1.png",
			_hold + "pickupUp1.png",
			_hold + "holdUpIdle.png"
		]
	)
	_add_anim(
		sf,
		"pickup_left",
		false,
		7.5,
		[
			_hold + "pickupLeft1.png",
			_hold + "pickupLeft1.png",
			_hold + "pickupLeft1.png",
			_hold + "holdLeftIdle.png"
		]
	)

	_add_anim(
		sf,
		"drop_down",
		false,
		7.5,
		[
			_hold + "pickupDown1.png",
			_hold + "pickupDown1.png",
			_hold + "pickupDown1.png",
			_idle + "Idle Down.png"
		]
	)
	_add_anim(
		sf,
		"drop_up",
		false,
		7.5,
		[
			_hold + "pickupUp1.png",
			_hold + "pickupUp1.png",
			_hold + "pickupUp1.png",
			_idle + "Idle Up.png"
		]
	)
	_add_anim(
		sf,
		"drop_left",
		false,
		7.5,
		[
			_hold + "pickupLeft1.png",
			_hold + "pickupLeft1.png",
			_hold + "pickupLeft1.png",
			_idle + "Idle Left.png"
		]
	)

	_add_anim(
		sf,
		"store_down",
		false,
		7.5,
		[
			_bag + "storeDown3.png",
			_bag + "storeDown2.png",
			_bag + "storeDown1.png",
			_idle + "Idle Down.png"
		]
	)
	_add_anim(
		sf,
		"store_up",
		false,
		7.5,
		[_bag + "storeUp3.png", _bag + "storeUp2.png", _bag + "storeUp1.png", _idle + "Idle Up.png"]
	)
	_add_anim(
		sf,
		"store_left",
		false,
		7.5,
		[
			_bag + "storeLeft3.png",
			_bag + "storeLeft2.png",
			_bag + "storeLeft1.png",
			_idle + "Idle Left.png"
		]
	)

	_add_anim(
		sf,
		"pull_out_down",
		false,
		12.5,
		[
			_bag + "storeDown1.png",
			_bag + "storeDown2.png",
			_bag + "storeDown3.png",
			_hold + "holdDownIdle.png"
		]
	)
	_add_anim(
		sf,
		"pull_out_up",
		false,
		12.5,
		[
			_bag + "storeUp1.png",
			_bag + "storeUp2.png",
			_bag + "storeUp3.png",
			_hold + "holdUpIdle.png"
		]
	)
	_add_anim(
		sf,
		"pull_out_left",
		false,
		12.5,
		[
			_bag + "storeLeft1.png",
			_bag + "storeLeft2.png",
			_bag + "storeLeft3.png",
			_hold + "holdLeftIdle.png"
		]
	)

	_add_anim(
		sf,
		"pass_out",
		false,
		2.5,
		(
			_seq(_pass, "passOut", 1, 11)
			+ [
				_pass + "passOut11.png",
				_pass + "passOut11.png",
				_pass + "passOut11.png",
				_pass + "passOut11.png",
				_pass + "passOut11.png"
			]
		)
	)

	_save(sf, RES_DIR + "player_sprite_frames.tres")


func _add_anim(
	sf: SpriteFrames, name: String, loop: bool, speed: float, frame_paths: Array[String]
) -> void:
	sf.add_animation(name)
	sf.set_animation_loop(name, loop)
	sf.set_animation_speed(name, speed)
	for path: String in frame_paths:
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			sf.add_frame(name, tex)
		else:
			push_warning("  Frame not found: " + path)


func _seq(base: String, pattern: String, start: int, end: int) -> Array[String]:
	var result: Array[String] = []
	for i: int in range(start, end + 1):
		result.append(base + pattern + str(i) + ".png")
	return result
