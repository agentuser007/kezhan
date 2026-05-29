extends Node

## Persistent storage for farm tiles. Bridges WorldMap scene and DayTurnoverProcessor.
## Map coordinates (Vector2i) are mapped to FarmTileData resources.

## Internal dictionary mapping Vector2i coordinates to FarmTileData
var farm_tiles: Dictionary = {}


## Get a tile at specific coordinates
func get_tile_at(coords: Vector2i) -> FarmTileData:
	return farm_tiles.get(coords, null)


## Set a tile at specific coordinates
func set_tile_at(coords: Vector2i, tile: FarmTileData) -> void:
	farm_tiles[coords] = tile


## Check if coordinates have a tile
func has_tile_at(coords: Vector2i) -> bool:
	return farm_tiles.has(coords)


## Clear all farm tiles (e.g. for new game)
func reset() -> void:
	farm_tiles.clear()


## Serialize persistent farm tiles data for saving
func get_save_data() -> Dictionary:
	var serialized: Dictionary = {}
	for coords: Vector2i in farm_tiles:
		var tile: FarmTileData = farm_tiles[coords]
		# Skip untiled/unmodified tiles to reduce save file size
		if tile.state == FarmTileData.TileState.UNTILLED:
			continue
		var key: String = "%d,%d" % [coords.x, coords.y]
		serialized[key] = tile.get_save_data()
	return {"farm_tiles": serialized}


## Deserialize and load saved farm tiles data
func load_save_data(data: Dictionary) -> void:
	# Clear existing so we have a clean slate when loading a slot
	farm_tiles.clear()
	var tiles_data: Dictionary = data.get("farm_tiles", {})
	for key: String in tiles_data:
		var parts: PackedStringArray = key.split(",")
		if parts.size() != 2:
			continue
		var coords: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
		var tile: FarmTileData = FarmTileData.new()
		tile.load_save_data(tiles_data[key])
		farm_tiles[coords] = tile
