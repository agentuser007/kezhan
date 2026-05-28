extends Control

var _bg_panel: PanelContainer
var _hbox: HBoxContainer
var _level_label: Label
var _xp_bar: ProgressBar
var _harvest_label: Label
var _water_label: Label
var _youshi_label: Label


func _ready() -> void:
	_build_ui()
	EventBus.farm_tile_state_changed.connect(_on_farm_changed)
	EventBus.farm_overlay_needs_update.connect(_on_farm_changed)
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.inventory_changed.connect(_update_level_display)
	EventBus.screen_transition_finished.connect(_update_farm_stats)


func _build_ui() -> void:
	_bg_panel = PanelContainer.new()
	_bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.set_border_width_all(1)
	style.border_color = Color(0.6, 0.5, 0.2, 0.6)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	_bg_panel.add_theme_stylebox_override("panel", style)
	_bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_panel)

	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 12)
	_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hbox)

	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 13)
	_level_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.5, 1))
	_level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_level_label.add_theme_constant_override("outline_size", 2)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hbox.add_child(_level_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(60, 10)
	_xp_bar.show_percentage = false
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hbox.add_child(_xp_bar)

	_harvest_label = Label.new()
	_harvest_label.add_theme_font_size_override("font_size", 13)
	_harvest_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	_harvest_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_harvest_label.add_theme_constant_override("outline_size", 2)
	_harvest_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hbox.add_child(_harvest_label)

	_water_label = Label.new()
	_water_label.add_theme_font_size_override("font_size", 13)
	_water_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 1))
	_water_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_water_label.add_theme_constant_override("outline_size", 2)
	_water_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hbox.add_child(_water_label)

	_youshi_label = Label.new()
	_youshi_label.add_theme_font_size_override("font_size", 13)
	_youshi_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 1))
	_youshi_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_youshi_label.add_theme_constant_override("outline_size", 2)
	_youshi_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hbox.add_child(_youshi_label)

	_update_level_display()
	_update_farm_stats()


func _on_farm_changed(_cell: Vector2i = Vector2i.MIN, _state: int = 0) -> void:
	_update_farm_stats()


func _on_hour_changed(_hour: int) -> void:
	_update_youshi_display()


func _update_level_display() -> void:
	if _level_label == null:
		return
	_level_label.text = "种植 Lv.%d" % PlayerData.farming_level
	if _xp_bar:
		var xp_needed: float = PlayerData.farming_level * 50.0
		_xp_bar.max_value = xp_needed
		_xp_bar.value = PlayerData.farming_xp


func _update_farm_stats() -> void:
	_update_level_display()
	var world_map: Node2D = _get_world_map()
	if world_map == null or not "farm_tiles" in world_map:
		if _harvest_label:
			_harvest_label.text = ""
		if _water_label:
			_water_label.text = ""
		if _youshi_label:
			_youshi_label.text = ""
		return

	var harvestable: int = 0
	var unwatered: int = 0
	for coords: Vector2i in world_map.farm_tiles:
		var tile: FarmTileData = world_map.farm_tiles[coords]
		if tile.state == FarmTileData.TileState.HARVESTABLE:
			harvestable += 1
		if tile.crop_id != &"" and not tile.watered_today and tile.state in [FarmTileData.TileState.SOWN, FarmTileData.TileState.WATERED]:
			unwatered += 1

	if _harvest_label:
		if harvestable > 0:
			_harvest_label.text = "★可收获: %d" % harvestable
			_harvest_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
		else:
			_harvest_label.text = "可收获: 0"
			_harvest_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))

	if _water_label:
		if unwatered > 0:
			_water_label.text = "⚠缺水: %d" % unwatered
			_water_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2, 1))
		else:
			_water_label.text = "缺水: 0"
			_water_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4, 1))

	_update_youshi_display()


func _update_youshi_display() -> void:
	if _youshi_label == null:
		return
	var hours_left: int = 17 - TimeManager.current_hour
	if hours_left <= 0:
		_youshi_label.text = "酉时已到"
		_youshi_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1))
	elif hours_left <= 2:
		_youshi_label.text = "酉时将至 (%dh)" % hours_left
		_youshi_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2, 1))
	else:
		_youshi_label.text = "酉时 %dh" % hours_left
		_youshi_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3, 1))


func _get_world_map() -> Node2D:
	var current_scene: Node = get_tree().current_scene
	if current_scene and current_scene.has_node("DirtLayer") and "farm_tiles" in current_scene:
		return current_scene
	return null
