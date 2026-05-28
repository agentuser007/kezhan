extends Control

## CookingUI — Displays available recipes, ingredient counts (have/needed format),
## quality preview, and cooking actions. Reads recipes from InventoryManager registry.

signal recipe_selected(recipe_id: StringName)
signal cooking_started(recipe_id: StringName)
signal cooking_cancelled

@onready var recipe_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RecipeList
@onready var recipe_detail: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RecipeDetail
@onready var ingredient_slots: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RightPanel/IngredientSlots
@onready var quality_preview: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RightPanel/QualityPreview
@onready var player_only_check: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RightPanel/PlayerOnlyCheck
@onready var retain_recipe_check: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RightPanel/RetainRecipeCheck
@onready var update_recipe_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RightPanel/UpdateRecipeButton
@onready var start_cooking_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RightPanel/StartCookingButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

var _current_recipe: Dictionary = {}
var _all_recipes: Array[Dictionary] = []


func _ready() -> void:
	if recipe_list:
		recipe_list.item_selected.connect(_on_recipe_selected)
	if start_cooking_button:
		start_cooking_button.pressed.connect(_on_start_cooking)
	if update_recipe_button:
		update_recipe_button.pressed.connect(_on_update_recipe)
	if player_only_check:
		player_only_check.toggled.connect(_on_player_only_toggled)
	if close_button:
		close_button.pressed.connect(_on_close)
	visibility_changed.connect(_on_visibility_changed)
	_populate_recipe_list()


func _on_visibility_changed() -> void:
	if visible:
		_populate_recipe_list()


func _populate_recipe_list() -> void:
	if recipe_list == null:
		return
	recipe_list.clear()
	_all_recipes = InventoryManager.get_all_recipes()
	var cooking_level: int = PlayerData.cooking_level
	for recipe: Dictionary in _all_recipes:
		var required_level: int = recipe.get("required_cooking_level", 1)
		if required_level <= cooking_level:
			recipe_list.add_item(recipe.get("name", "???"))
		else:
			recipe_list.add_item("[锁定] %s (需烹饪%d级)" % [recipe.get("name", "???"), required_level])
	_clear_ingredient_slots()


func _on_recipe_selected(index: int) -> void:
	if index < 0 or index >= _all_recipes.size():
		return
	var recipe: Dictionary = _all_recipes[index]
	var cooking_level: int = PlayerData.cooking_level
	var required_level: int = recipe.get("required_cooking_level", 1)
	if required_level > cooking_level:
		_current_recipe = {}
		_clear_ingredient_slots()
		if recipe_detail:
			recipe_detail.clear()
			recipe_detail.append_text("[b][锁定菜谱][/b]\n需烹饪等级: %d" % required_level)
		if start_cooking_button:
			start_cooking_button.disabled = true
		return
	_current_recipe = recipe
	recipe_selected.emit(StringName(recipe.get("id", "")))
	_show_recipe_detail(recipe)


func _show_recipe_detail(recipe: Dictionary) -> void:
	if recipe_detail:
		recipe_detail.clear()
		var desc: String = recipe.get("description", "")
		recipe_detail.append_text("[b]%s[/b]\n\n%s" % [recipe.get("name", ""), desc])
	_build_ingredient_slots(recipe)
	_update_quality_preview()
	_update_cook_button_state()


func _clear_ingredient_slots() -> void:
	if ingredient_slots == null:
		return
	for child: Node in ingredient_slots.get_children():
		child.queue_free()


func _build_ingredient_slots(recipe: Dictionary) -> void:
	_clear_ingredient_slots()
	if ingredient_slots == null:
		return
	var ingredients: Array = recipe.get("ingredients", [])
	var missing_count: int = 0
	for ing: Dictionary in ingredients:
		var slot: PanelContainer = PanelContainer.new()
		slot.custom_minimum_size = Vector2(72, 72)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.08, 0.04, 0.8)
		style.border_color = Color(0.5, 0.45, 0.3, 0.6)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		slot.add_theme_stylebox_override("panel", style)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		slot.add_child(vbox)

		var icon: TextureRect = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36, 36)
		var item_id: StringName = StringName(ing.get("id", ""))
		var tex: Texture2D = InventoryManager.get_item_icon(item_id)
		if tex:
			icon.texture = tex
		vbox.add_child(icon)

		# Enhanced ingredient label: "食材名 have/needed" with color coding
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("outline_size", 1)
		var needed: int = ing.get("amount", 1)
		var have: int = InventoryManager.get_amount(item_id)
		var name_text: String = ing.get("name", "?")
		label.text = "%s %d/%d" % [name_text, have, needed]
		if have >= needed:
			label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 0.95))
		else:
			label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 0.95))
			missing_count += 1
		vbox.add_child(label)

		ingredient_slots.add_child(slot)

	# Add missing ingredients summary
	if missing_count > 0:
		var summary: Label = Label.new()
		summary.name = "MissingSummary"
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary.add_theme_font_size_override("font_size", 11)
		summary.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3, 0.9))
		summary.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		summary.add_theme_constant_override("outline_size", 1)
		summary.text = "缺少 %d 种食材" % missing_count
		ingredient_slots.add_child(summary)


func _on_start_cooking() -> void:
	if _current_recipe.is_empty():
		return
	if not _can_cook():
		if quality_preview:
			quality_preview.text = "食材不足，无法烹饪!"
		return
	_consume_ingredients()
	cooking_started.emit(StringName(_current_recipe.get("id", "")))
	var output_id: StringName = StringName(_current_recipe.get("output_id", ""))
	var output_amount: int = _current_recipe.get("output_amount", 1)
	if not output_id.is_empty():
		InventoryManager.add_item(output_id, output_amount)
	GameUI.close_panel()


func _can_cook() -> bool:
	var ingredients: Array = _current_recipe.get("ingredients", [])
	for ing: Dictionary in ingredients:
		var item_id: StringName = StringName(ing.get("id", ""))
		var needed: int = ing.get("amount", 1)
		if not InventoryManager.has_item(item_id, needed):
			return false
	return true


func _update_cook_button_state() -> void:
	if start_cooking_button == null:
		return
	if _current_recipe.is_empty():
		start_cooking_button.disabled = true
		return
	start_cooking_button.disabled = not _can_cook()
	if not _can_cook():
		start_cooking_button.tooltip_text = "食材不足"
	else:
		start_cooking_button.tooltip_text = ""


func _on_update_recipe() -> void:
	pass


func _on_player_only_toggled(is_on: bool) -> void:
	if retain_recipe_check:
		retain_recipe_check.disabled = not is_on


func _on_close() -> void:
	GameUI.close_panel()


func _update_quality_preview() -> void:
	if quality_preview == null:
		return
	if _current_recipe.is_empty():
		quality_preview.text = "预期成色: ☆☆☆☆☆"
		return
	var base_quality: int = _current_recipe.get("base_quality", 14)
	var cooking_level: int = PlayerData.cooking_level
	var cooking_mastery: int = PlayerData.cooking_mastery
	var quality_score: float = float(base_quality) + cooking_level * 2.0 + cooking_mastery * 3.0
	var stars: int = clampi(int(quality_score / 8.0) + 1, 1, 5)
	var star_text: String = ""
	for i in stars:
		star_text += "★"
	for i in (5 - stars):
		star_text += "☆"
	quality_preview.text = "预期成色: %s" % star_text


func _consume_ingredients() -> void:
	var ingredients: Array = _current_recipe.get("ingredients", [])
	for ing: Dictionary in ingredients:
		var item_id: StringName = StringName(ing.get("id", ""))
		var amount: int = ing.get("amount", 1)
		InventoryManager.remove_item(item_id, amount)
	PlayerData.add_cooking_xp(15.0)
	EventBus.inventory_changed.emit()
