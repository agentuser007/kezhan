extends Node2D

var _farm_tiles: Dictionary = {}
var _tile_size: int = 32
var _z_index_offset: int = 10


func _ready() -> void:
	EventBus.farm_overlay_needs_update.connect(queue_redraw)
	EventBus.farm_tile_state_changed.connect(_on_tile_state_changed)
	set_z_index(_z_index_offset)


func setup(world_map: Node2D) -> void:
	_farm_tiles = world_map.farm_tiles
	_tile_size = world_map.tile_size
	queue_redraw()


func _on_tile_state_changed(_cell: Vector2i, _state: int) -> void:
	queue_redraw()


func _draw() -> void:
	if _farm_tiles.is_empty():
		return
	for coords: Vector2i in _farm_tiles:
		var tile: FarmTileData = _farm_tiles[coords]
		if tile.state == FarmTileData.TileState.UNTILLED:
			continue
		var pos: Vector2 = Vector2(coords.x * _tile_size, coords.y * _tile_size)
		_draw_tile_overlay(pos, tile)


func _draw_tile_overlay(pos: Vector2, tile: FarmTileData) -> void:
	var ts: float = float(_tile_size)

	if tile.crop_id != &"" and tile.state != FarmTileData.TileState.WILTED:
		if tile.state == FarmTileData.TileState.HARVESTABLE:
			draw_rect(Rect2(pos.x, pos.y, ts, ts), Color(1.0, 0.85, 0.2, 0.15))
			draw_rect(Rect2(pos.x + 1, pos.y + 1, ts - 2, ts - 2), Color(1.0, 0.85, 0.2, 0.6), false, 1.5)
		elif tile.growth_stages > 0:
			var progress: float = tile.growth_progress / float(tile.growth_stages)
			var bar_w: float = ts - 4.0
			var bar_h: float = 3.0
			var bar_x: float = pos.x + 2.0
			var bar_y: float = pos.y + ts - bar_h - 1.0
			draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.0, 0.0, 0.0, 0.5))
			var fill_color: Color = Color(0.3, 0.8, 0.3, 0.8)
			if not tile.watered_today and tile.state in [FarmTileData.TileState.SOWN, FarmTileData.TileState.WATERED]:
				fill_color = Color(0.8, 0.6, 0.2, 0.8)
			draw_rect(Rect2(bar_x, bar_y, bar_w * progress, bar_h), fill_color)

	if tile.has_weeds:
		draw_string(ThemeDB.fallback_font, Vector2(pos.x + ts - 14, pos.y + 12), "草", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.7, 0.2, 0.9))

	if tile.has_pests:
		draw_string(ThemeDB.fallback_font, Vector2(pos.x + 2, pos.y + 12), "虫", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.3, 0.2, 0.9))

	if tile.dry_days_count > 0 and tile.crop_id != &"" and tile.state != FarmTileData.TileState.WILTED:
		draw_string(ThemeDB.fallback_font, Vector2(pos.x + ts / 2.0 - 5, pos.y + 12), "干", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.8, 0.2, 0.9))

	if tile.fertilizer_days_remaining > 0:
		draw_circle(Vector2(pos.x + ts - 5, pos.y + ts - 5), 3.0, Color(0.3, 0.6, 1.0, 0.7))

	if tile.state == FarmTileData.TileState.WILTED:
		draw_rect(Rect2(pos.x, pos.y, ts, ts), Color(0.5, 0.0, 0.0, 0.12))
