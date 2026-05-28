extends PanelContainer

const STATE_NAMES: Dictionary = {
	FarmTileData.TileState.UNTILLED: "荒地",
	FarmTileData.TileState.TILLED_BARREN: "已耕地",
	FarmTileData.TileState.TILLED_FERTILE: "肥沃地",
	FarmTileData.TileState.SOWN: "已播种",
	FarmTileData.TileState.WATERED: "已浇水",
	FarmTileData.TileState.HARVESTABLE: "★可收获",
	FarmTileData.TileState.WILTED: "✗枯萎",
}

const STATE_COLORS: Dictionary = {
	FarmTileData.TileState.UNTILLED: Color(0.7, 0.7, 0.7, 1),
	FarmTileData.TileState.TILLED_BARREN: Color(0.8, 0.6, 0.3, 1),
	FarmTileData.TileState.TILLED_FERTILE: Color(0.5, 0.8, 0.3, 1),
	FarmTileData.TileState.SOWN: Color(0.6, 0.8, 0.4, 1),
	FarmTileData.TileState.WATERED: Color(0.3, 0.6, 1.0, 1),
	FarmTileData.TileState.HARVESTABLE: Color(1.0, 0.85, 0.2, 1),
	FarmTileData.TileState.WILTED: Color(0.9, 0.2, 0.2, 1),
}

var _vbox: VBoxContainer
var _state_label: Label
var _crop_label: Label
var _progress_bar: ProgressBar
var _status_label: Label
var _season_label: Label

var _last_cell: Vector2i = Vector2i.MIN


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.8)
	style.set_border_width_all(1)
	style.border_color = Color(0.7, 0.6, 0.3, 0.8)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 3)
	add_child(_vbox)

	_state_label = Label.new()
	_state_label.add_theme_font_size_override("font_size", 13)
	_state_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_state_label.add_theme_constant_override("outline_size", 2)
	_vbox.add_child(_state_label)

	_crop_label = Label.new()
	_crop_label.add_theme_font_size_override("font_size", 12)
	_crop_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.6, 1))
	_crop_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_crop_label.add_theme_constant_override("outline_size", 2)
	_vbox.add_child(_crop_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(120, 10)
	_progress_bar.show_percentage = false
	_vbox.add_child(_progress_bar)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_status_label.add_theme_constant_override("outline_size", 1)
	_vbox.add_child(_status_label)

	_season_label = Label.new()
	_season_label.add_theme_font_size_override("font_size", 11)
	_season_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_season_label.add_theme_constant_override("outline_size", 1)
	_vbox.add_child(_season_label)


func _process(_delta: float) -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		visible = false
		return

	var mouse_pos: Vector2 = world_map.get_global_mouse_position()
	var cell: Vector2i = world_map.dirt_layer.local_to_map(mouse_pos)
	if cell == _last_cell and visible:
		_update_position(mouse_pos)
		return

	_last_cell = cell
	var tile: FarmTileData = world_map.get_tile_at(cell)
	if tile == null:
		visible = false
		return

	_update_content(tile)
	visible = true
	_update_position(mouse_pos)


func _update_content(tile: FarmTileData) -> void:
	var state_name: String = STATE_NAMES.get(tile.state, "未知")
	var state_color: Color = STATE_COLORS.get(tile.state, Color.WHITE)
	_state_label.text = state_name
	_state_label.add_theme_color_override("font_color", state_color)

	if tile.crop_id != &"":
		var crop_name: String = _get_crop_display_name(tile.crop_id)
		var stage: int = tile.get_growth_stage_index()
		if tile.state == FarmTileData.TileState.HARVESTABLE:
			_crop_label.text = crop_name + " (成熟)"
		elif tile.state == FarmTileData.TileState.WILTED:
			_crop_label.text = crop_name + " (枯萎)"
		else:
			_crop_label.text = crop_name + " — 生长阶段 %d/%d" % [stage + 1, tile.growth_stages]

		_progress_bar.visible = true
		_progress_bar.value = (tile.growth_progress / float(tile.growth_stages)) * 100.0
		_progress_bar.max_value = 100.0
	else:
		_crop_label.text = ""
		_progress_bar.visible = false

	var statuses: PackedStringArray = []
	if tile.watered_today:
		statuses.append("💧已浇水")
	elif tile.state in [FarmTileData.TileState.SOWN, FarmTileData.TileState.WATERED]:
		statuses.append("⚠未浇水")
	if tile.fertilizer_days_remaining > 0:
		statuses.append("🧪施肥(%d天)" % tile.fertilizer_days_remaining)
	if tile.has_weeds:
		statuses.append("🌿有杂草")
	if tile.has_pests:
		statuses.append("🐛有虫害")
	if tile.dry_days_count > 0:
		statuses.append("干旱%d天" % tile.dry_days_count)
	_status_label.text = " ".join(statuses) if statuses.size() > 0 else ""

	if tile.crop_id != &"":
		var in_season: bool = _is_crop_in_season(tile.crop_id, TimeManager.current_season)
		if in_season:
			_season_label.text = "✓ 当季作物"
			_season_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1))
		else:
			_season_label.text = "✗ 非当季作物"
			_season_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))
	else:
		_season_label.text = ""


func _update_position(mouse_pos: Vector2) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var offset: Vector2 = Vector2(16, 16)
	var target: Vector2 = mouse_pos + offset
	var tooltip_size: Vector2 = size
	if target.x + tooltip_size.x > viewport_size.x:
		target.x = mouse_pos.x - tooltip_size.x - 8
	if target.y + tooltip_size.y > viewport_size.y:
		target.y = mouse_pos.y - tooltip_size.y - 8
	position = target


func _get_crop_display_name(crop_id: StringName) -> String:
	var info: Dictionary = InventoryManager.get_item_info(crop_id)
	if not info.is_empty():
		return String(info.get("name", String(crop_id)))
	return String(crop_id)


func _is_crop_in_season(crop_id: StringName, season: StringName) -> bool:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return true
	return world_map._is_crop_in_season(crop_id, season)


func _get_world_map() -> Node2D:
	var current_scene: Node = get_tree().current_scene
	if current_scene and current_scene.has_node("DirtLayer"):
		return current_scene
	return null
