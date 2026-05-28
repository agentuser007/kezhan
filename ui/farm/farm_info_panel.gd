extends Control

const SEASON_CROP_MAP: Dictionary = {
	&"春": [&"TurnipSeeds", &"StrawberrySeeds", &"PotatoSeeds", &"ScallionSeeds", &"WheatSeeds", &"GlutinousRiceSeeds"],
	&"夏": [&"StrawberrySeeds", &"EggplantSeeds", &"TomatoSeeds", &"MelonSeeds", &"PotatoSeeds", &"CornSeeds", &"ScallionSeeds", &"GingerSeeds", &"ChiliSeeds", &"SweetPotatoSeeds", &"SugarcaneSeeds", &"GlutinousRiceSeeds"],
	&"秋": [&"TurnipSeeds", &"EggplantSeeds", &"TomatoSeeds", &"CornSeeds", &"ScallionSeeds", &"GingerSeeds", &"ChiliSeeds", &"WheatSeeds", &"SweetPotatoSeeds", &"SugarcaneSeeds"],
	&"冬": [&"ScallionSeeds", &"WheatSeeds"],
	&"闰": [],
}

var _dim_bg: ColorRect
var _main_panel: PanelContainer
var _content_vbox: VBoxContainer
var _close_button: Button
var _tab_container: TabContainer


func _ready() -> void:
	visible = false
	_build_ui()


func show_panel() -> void:
	_refresh_content()
	visible = true


func _build_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	_dim_bg = ColorRect.new()
	_dim_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim_bg.color = Color(0, 0, 0, 0.4)
	_dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim_bg)

	_main_panel = PanelContainer.new()
	_main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_main_panel.offset_left = -220.0
	_main_panel.offset_top = -200.0
	_main_panel.offset_right = 220.0
	_main_panel.offset_bottom = 200.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.04, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.7, 0.6, 0.3, 0.8)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(12)
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_main_panel)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 6)
	_main_panel.add_child(_content_vbox)

	var title_hbox: HBoxContainer = HBoxContainer.new()
	var title_label: Label = Label.new()
	title_label.text = "农事手册"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title_label.add_theme_constant_override("outline_size", 2)
	title_hbox.add_child(title_label)

	title_hbox.add_child(HSpacer.new())

	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.custom_minimum_size = Vector2(28, 28)
	_close_button.pressed.connect(_on_close_pressed)
	title_hbox.add_child(_close_button)
	_content_vbox.add_child(title_hbox)

	_tab_container = TabContainer.new()
	_tab_container.add_theme_font_size_override("font_size", 13)
	_tab_container.custom_minimum_size = Vector2(400, 340)
	_content_vbox.add_child(_tab_container)

	_build_overview_tab()
	_build_skill_tab()
	_build_season_tab()


func _build_overview_tab() -> void:
	var tab: VBoxContainer = VBoxContainer.new()
	tab.name = "农田总览"
	tab.add_theme_constant_override("separation", 4)

	var labels_to_create: PackedStringArray = [
		"TotalLabel", "TilledLabel", "PlantedLabel",
		"HarvestableLabel", "WiltedLabel", "WeedsLabel", "PestsLabel"
	]
	for lbl_name: String in labels_to_create:
		var lbl: Label = Label.new()
		lbl.name = lbl_name
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("outline_size", 1)
		tab.add_child(lbl)

	_tab_container.add_child(tab)


func _build_skill_tab() -> void:
	var tab: VBoxContainer = VBoxContainer.new()
	tab.name = "种植技能"
	tab.add_theme_constant_override("separation", 4)

	var skill_labels: PackedStringArray = [
		"LevelLabel", "MasteryLabel", "XPLabel",
		"YieldLabel", "PestLabel", "InteractLabel"
	]
	for lbl_name: String in skill_labels:
		var lbl: Label = Label.new()
		lbl.name = lbl_name
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("outline_size", 1)
		tab.add_child(lbl)

	_tab_container.add_child(tab)


func _build_season_tab() -> void:
	var tab: VBoxContainer = VBoxContainer.new()
	tab.name = "季节信息"
	tab.add_theme_constant_override("separation", 4)

	var season_label: Label = Label.new()
	season_label.name = "SeasonLabel"
	season_label.add_theme_font_size_override("font_size", 13)
	season_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	season_label.add_theme_constant_override("outline_size", 1)
	tab.add_child(season_label)

	var crop_list: RichTextLabel = RichTextLabel.new()
	crop_list.name = "CropList"
	crop_list.bbcode_enabled = true
	crop_list.fit_content = true
	crop_list.scroll_following = true
	crop_list.custom_minimum_size = Vector2(0, 240)
	tab.add_child(crop_list)

	_tab_container.add_child(tab)


func _refresh_content() -> void:
	_refresh_overview()
	_refresh_skill()
	_refresh_season()


func _refresh_overview() -> void:
	var tab: VBoxContainer = _tab_container.get_node_or_null("农田总览")
	if tab == null:
		return

	var world_map: Node2D = _get_world_map()
	var total: int = 0
	var tilled: int = 0
	var planted: int = 0
	var harvestable: int = 0
	var wilted: int = 0
	var weeds: int = 0
	var pests: int = 0

	if world_map:
		for coords: Vector2i in world_map.farm_tiles:
			var tile: FarmTileData = world_map.farm_tiles[coords]
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

	_set_tab_label(tab, "TotalLabel", "总地块: %d" % total)
	_set_tab_label(tab, "TilledLabel", "空闲耕地: %d" % tilled)
	_set_tab_label(tab, "PlantedLabel", "种植中: %d" % planted, Color(0.5, 0.9, 0.5, 1) if planted > 0 else Color(1, 1, 1, 0.85))
	_set_tab_label(tab, "HarvestableLabel", "可收获: %d" % harvestable, Color(1.0, 0.85, 0.2, 1) if harvestable > 0 else Color(1, 1, 1, 0.85))
	_set_tab_label(tab, "WiltedLabel", "枯萎: %d" % wilted, Color(0.9, 0.2, 0.2, 1) if wilted > 0 else Color(1, 1, 1, 0.85))
	_set_tab_label(tab, "WeedsLabel", "杂草: %d" % weeds, Color(0.6, 0.8, 0.3, 1) if weeds > 0 else Color(1, 1, 1, 0.85))
	_set_tab_label(tab, "PestsLabel", "虫害: %d" % pests, Color(0.9, 0.3, 0.3, 1) if pests > 0 else Color(1, 1, 1, 0.85))


func _refresh_skill() -> void:
	var tab: VBoxContainer = _tab_container.get_node_or_null("种植技能")
	if tab == null:
		return

	_set_tab_label(tab, "LevelLabel", "种植等级: Lv.%d" % PlayerData.farming_level, Color(0.8, 1.0, 0.5, 1))
	_set_tab_label(tab, "MasteryLabel", "精通: %d级" % PlayerData.farming_mastery)

	var xp_needed: float = PlayerData.farming_level * 50.0
	_set_tab_label(tab, "XPLabel", "经验: %.0f / %.0f" % [PlayerData.farming_xp, xp_needed])
	_set_tab_label(tab, "YieldLabel", "产量加成: x%.2f" % PlayerData.get_farming_yield_multiplier(), Color(0.4, 1.0, 0.4, 1))
	_set_tab_label(tab, "PestLabel", "虫害概率: %.0f%%" % (PlayerData.get_farming_pest_chance() * 100.0))
	_set_tab_label(tab, "InteractLabel", "操作耗时: %.1fs" % PlayerData.get_farming_interact_time())


func _refresh_season() -> void:
	var tab: VBoxContainer = _tab_container.get_node_or_null("季节信息")
	if tab == null:
		return

	var season: StringName = TimeManager.current_season
	var season_colors: Dictionary = {&"春": Color(0.5, 1.0, 0.5, 1), &"夏": Color(1.0, 0.8, 0.3, 1), &"秋": Color(1.0, 0.6, 0.2, 1), &"冬": Color(0.6, 0.8, 1.0, 1), &"闰": Color(0.8, 0.6, 1.0, 1)}
	_set_tab_label(tab, "SeasonLabel", "当前季节: %s" % String(season), season_colors.get(season, Color.WHITE))

	var days_in_season: int = 24
	var day_of_season: int = ((TimeManager.current_day - 1) % days_in_season) + 1
	var days_left: int = days_in_season - day_of_season

	var crop_list: RichTextLabel = tab.get_node_or_null("CropList")
	if crop_list == null:
		return
	crop_list.clear()
	crop_list.append_text("[color=#aaaaaa]本季剩余 %d 天[/color]\n\n" % days_left)

	var crops: Array = SEASON_CROP_MAP.get(season, [])
	if crops.is_empty():
		crop_list.append_text("[color=#888888]本季无适宜作物[/color]")
		return

	crop_list.append_text("[color=#cccc88]当季可种作物:[/color]\n")
	for seed_id: StringName in crops:
		var info: Dictionary = InventoryManager.get_item_info(seed_id)
		var display_name: String = String(info.get("name", String(seed_id)))
		var _in_season: bool = true
		crop_list.append_text("  [color=#88cc88]✓ %s[/color]\n" % display_name)


func _set_tab_label(tab: VBoxContainer, label_name: String, text: String, color: Color = Color(1, 1, 1, 0.85)) -> void:
	var lbl: Label = tab.get_node_or_null(label_name)
	if lbl == null:
		return
	lbl.text = text
	if color != Color(1, 1, 1, 0.85):
		lbl.add_theme_color_override("font_color", color)


func _on_close_pressed() -> void:
	GameUI.close_panel()


func _get_world_map() -> Node2D:
	var current_scene: Node = get_tree().current_scene
	if current_scene and current_scene.has_node("DirtLayer"):
		return current_scene
	return null


class HSpacer:
	extends Control
	func _init() -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
