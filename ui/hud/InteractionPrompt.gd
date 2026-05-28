extends Control

@onready var prompt_label: Label = $PromptLabel

var _current_target: Interactable = null
var _bg_panel: PanelContainer = null


func _ready() -> void:
	EventBus.interaction_highlight_changed.connect(_on_highlight_changed)
	EventBus.hotbar_selection_changed.connect(_on_hotbar_changed)
	_create_background.call_deferred()
	_style_label()
	visible = false


func _create_background() -> void:
	_bg_panel = PanelContainer.new()
	_bg_panel.name = "BgPanel"
	_bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	style.set_border_width_all(1)
	style.border_color = Color(0.8, 0.75, 0.4, 0.7)
	style.set_corner_radius_all(4)
	_bg_panel.add_theme_stylebox_override("panel", style)
	_bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_panel)
	move_child(_bg_panel, 0)


func _style_label() -> void:
	if prompt_label == null:
		return
	prompt_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("outline_size", 2)
	prompt_label.add_theme_font_size_override("font_size", 15)
	prompt_label.text = ""


func _on_highlight_changed(target: Interactable) -> void:
	_current_target = target
	if target == null or not is_instance_valid(target):
		_check_seed_prompt()
		return
	if prompt_label:
		prompt_label.text = target.get_interaction_text()
	visible = true


func _on_hotbar_changed(_slot: int) -> void:
	if _current_target == null or not is_instance_valid(_current_target):
		_check_seed_prompt()


func _check_seed_prompt() -> void:
	var item_id: StringName = InventoryManager.get_selected_item_id()
	if item_id == &"":
		visible = false
		if prompt_label:
			prompt_label.text = ""
		return
	var info: Dictionary = InventoryManager.get_item_info(item_id)
	if info.get("category", &"") == &"种子":
		var display_name: String = String(info.get("name", String(item_id)))
		var seasons: String = _get_seed_seasons_text(item_id)
		if prompt_label:
			prompt_label.text = "%s [%s] — 点击播种" % [display_name, seasons]
		visible = true
	else:
		visible = false
		if prompt_label:
			prompt_label.text = ""


func _get_seed_seasons_text(seed_id: StringName) -> String:
	var season_map: Dictionary = {
		&"TurnipSeeds": "春/秋", &"StrawberrySeeds": "春/夏",
		&"EggplantSeeds": "夏/秋", &"TomatoSeeds": "夏/秋",
		&"MelonSeeds": "夏", &"PotatoSeeds": "春/夏/秋",
		&"CornSeeds": "夏/秋", &"ScallionSeeds": "春/夏/秋/冬",
		&"GingerSeeds": "夏/秋", &"ChiliSeeds": "夏/秋",
		&"WheatSeeds": "春/秋/冬", &"SweetPotatoSeeds": "夏/秋",
		&"SugarcaneSeeds": "夏/秋", &"GlutinousRiceSeeds": "春/夏",
	}
	return season_map.get(seed_id, "?")
