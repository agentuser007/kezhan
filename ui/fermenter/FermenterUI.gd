extends Control

## FermenterUI — Panel for interacting with a FermentationJar.
## Shows backpack fermentable crops on the left, progress & jar status on the right.

@onready var content_icon: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxStatus/ContentSection/ContentIcon
@onready var content_name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxStatus/ContentSection/ContentInfo/ContentName
@onready var content_amount_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxStatus/ContentSection/ContentInfo/ContentAmount
@onready var quality_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxStatus/ProgressSection/QualityLabel
@onready var progress_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxStatus/ProgressSection/ProgressBar
@onready var days_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxStatus/ProgressSection/DaysLabel
@onready var place_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxStatus/ActionSection/PlaceButton
@onready var collect_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxStatus/ActionSection/CollectButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton
@onready var ingredient_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxIngredients/IngredientList

## Reference to the jar being interacted with.
var _jar: FermentationJarInteractable = null

## Selected crop ID to place
var _selected_item_id: StringName = &""

## Supported crops for fermentation
var _fermentable_registry: Array[StringName] = [&"GlutinousRice", &"Soybean", &"Wheat"]


func _ready() -> void:
	_apply_theme_styles()
	if place_button:
		place_button.pressed.connect(_on_place)
	if collect_button:
		collect_button.pressed.connect(_on_collect)
	if close_button:
		close_button.pressed.connect(_on_close)
	if ingredient_list:
		ingredient_list.item_selected.connect(_on_ingredient_selected)
	visibility_changed.connect(_on_visibility_changed)
	refresh()


func _on_visibility_changed() -> void:
	if visible:
		_selected_item_id = &""
		if ingredient_list:
			ingredient_list.deselect_all()
		refresh.call_deferred()


func setup(jar: FermentationJarInteractable) -> void:
	_jar = jar
	_selected_item_id = &""
	if ingredient_list:
		ingredient_list.deselect_all()
	refresh()


func refresh() -> void:
	_populate_ingredients()
	
	if _jar == null:
		_show_empty()
		return

	if _jar.content_item_id == &"":
		_show_empty_slot()
	else:
		_show_content()

	_update_buttons()


func _populate_ingredients() -> void:
	if ingredient_list == null:
		return
	ingredient_list.clear()
	for item_id: StringName in _fermentable_registry:
		var info: Dictionary = InventoryManager.get_item_info(item_id)
		var name: String = info.get("name", String(item_id))
		var icon: Texture2D = InventoryManager.get_item_icon(item_id)
		var count: int = InventoryManager.get_amount(item_id)
		var idx: int = ingredient_list.add_item("%s (x%d)" % [name, count], icon)
		if count == 0:
			ingredient_list.set_item_custom_fg_color(idx, Color(0.5, 0.45, 0.4, 0.6))


func _on_ingredient_selected(idx: int) -> void:
	if idx < _fermentable_registry.size():
		_selected_item_id = _fermentable_registry[idx]
	_update_buttons()


func _show_empty() -> void:
	if content_icon:
		content_icon.texture = null
	if content_name_label:
		content_name_label.text = "未选择发酵坛"
	if content_amount_label:
		content_amount_label.text = ""
	if quality_label:
		quality_label.text = "品质: —"
	if progress_bar:
		progress_bar.value = 0
	if days_label:
		days_label.text = ""


func _show_empty_slot() -> void:
	if content_icon:
		content_icon.texture = null
	if content_name_label:
		content_name_label.text = "[空] 可放入物料"
	if content_amount_label:
		content_amount_label.text = ""
	if quality_label:
		quality_label.text = "品质: —"
	if progress_bar:
		progress_bar.value = 0
	if days_label:
		days_label.text = "请从左侧选择发酵原料"


func _show_content() -> void:
	var item_id: StringName = _jar.content_item_id
	var info: Dictionary = InventoryManager.get_item_info(item_id)

	if content_icon:
		var tex: Texture2D = InventoryManager.get_item_icon(item_id)
		content_icon.texture = tex
	if content_name_label:
		content_name_label.text = info.get("name", String(item_id))
	if content_amount_label:
		content_amount_label.text = "x%d" % _jar.content_amount

	# Quality tier display
	var tiers: Array[Dictionary] = [
		{"name": "普通", "quality": 10},
		{"name": "优质", "quality": 16},
		{"name": "珍藏", "quality": 22},
	]
	var tier_idx: int = _jar.current_quality_tier
	var tier_name: String = "普通"
	if tier_idx < tiers.size():
		tier_name = tiers[tier_idx]["name"]
		
	var dots: String = ""
	for i in tiers.size():
		if i <= tier_idx:
			dots += "●"
		else:
			dots += "○"
			
	if quality_label:
		quality_label.text = "品质: %s %s" % [dots, tier_name]

	var max_days: int = tiers.size() * 4
	var current: int = _jar.fermentation_days
	if progress_bar:
		progress_bar.max_value = max_days
		progress_bar.value = current
	if days_label:
		days_label.text = "发酵进度: %d / %d 天" % [current, max_days]


func _update_buttons() -> void:
	if _jar == null:
		if place_button: place_button.disabled = true
		if collect_button: collect_button.disabled = true
		return

	var is_empty: bool = _jar.content_item_id == &""
	
	if collect_button:
		collect_button.disabled = is_empty
		
	if place_button:
		if is_empty:
			var has_selected: bool = _selected_item_id != &""
			var has_amount: bool = InventoryManager.get_amount(_selected_item_id) > 0
			place_button.disabled = not (has_selected and has_amount)
		else:
			place_button.disabled = true


func _on_place() -> void:
	if _jar == null or _jar.content_item_id != &"":
		return
	if _selected_item_id == &"":
		return
	var count: int = InventoryManager.get_amount(_selected_item_id)
	if count <= 0:
		return
		
	if _jar.place_content(_selected_item_id, 1):
		var crop_name: String = InventoryManager.get_item_info(_selected_item_id).get("name", String(_selected_item_id))
		EventBus.notification_requested.emit("已放入 %s" % crop_name)
		_selected_item_id = &""
		if ingredient_list:
			ingredient_list.deselect_all()
		refresh()


func _on_collect() -> void:
	if _jar == null or _jar.content_item_id == &"":
		return
	var item_id: StringName = _jar.content_item_id
	var info: Dictionary = InventoryManager.get_item_info(item_id)
	var amount: int = _jar.content_amount
	_jar.collect()
	EventBus.notification_requested.emit("取出了 %s x%d" % [info.get("name", ""), amount])
	_selected_item_id = &""
	if ingredient_list:
		ingredient_list.deselect_all()
	refresh()


func _on_close() -> void:
	GameUI.close_panel()


func _apply_theme_styles() -> void:
	# Style the PanelContainer background
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.10, 0.08, 0.96) # Warm dark brown
	panel_style.border_color = Color(0.76, 0.65, 0.35, 0.8) # Gold border
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.set_shadow_color(Color(0, 0, 0, 0.4))
	panel_style.shadow_size = 8
	$PanelContainer.add_theme_stylebox_override("panel", panel_style)

	# Style ItemLists
	var list_style := StyleBoxFlat.new()
	list_style.bg_color = Color(0.08, 0.06, 0.04, 0.8)
	list_style.border_color = Color(0.5, 0.4, 0.3, 0.5)
	list_style.set_border_width_all(1)
	list_style.set_corner_radius_all(4)

	var list_selected := StyleBoxFlat.new()
	list_selected.bg_color = Color(0.25, 0.20, 0.15, 0.9)
	list_selected.border_color = Color(0.76, 0.65, 0.35, 0.8)
	list_selected.set_border_width_all(1)
	list_selected.set_corner_radius_all(4)

	if ingredient_list:
		ingredient_list.add_theme_stylebox_override("panel", list_style)
		ingredient_list.add_theme_stylebox_override("focus", list_style)
		ingredient_list.add_theme_stylebox_override("selected", list_selected)
		ingredient_list.add_theme_stylebox_override("selected_focus", list_selected)
		ingredient_list.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
		ingredient_list.add_theme_color_override("font_selected_color", Color(1.0, 0.92, 0.75))

	# Style ProgressBar
	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color(0.06, 0.05, 0.04, 0.9)
	progress_bg.set_corner_radius_all(4)
	
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color(0.76, 0.65, 0.35, 0.95) # Amber gold fill
	progress_fill.set_corner_radius_all(3)
	
	if progress_bar:
		progress_bar.add_theme_stylebox_override("background", progress_bg)
		progress_bar.add_theme_stylebox_override("fill", progress_fill)

	# Style Buttons
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.18, 0.14, 0.10, 0.9)
	btn_style.border_color = Color(0.6, 0.5, 0.35, 0.8)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(4)

	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.25, 0.20, 0.15, 0.95)
	btn_hover.border_color = Color(0.76, 0.65, 0.35, 0.95)

	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = Color(0.10, 0.08, 0.06, 0.95)

	for btn in [place_button, collect_button, close_button]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_pressed)
			btn.add_theme_color_override("font_color", Color(0.9, 0.82, 0.6))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.7))
