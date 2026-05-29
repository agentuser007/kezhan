extends Control

## MenuEditor — Allows the player to select today's menu from unlocked dishes.
## Reads recipes from InventoryManager recipe registry and filters by cooking level.

signal menu_confirmed(menu_items: Array[StringName])

@onready var available_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxAvailable/AvailableList
@onready var today_menu_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxToday/TodayMenuList
@onready var add_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ButtonContainer/AddButton
@onready var remove_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ButtonContainer/RemoveButton
@onready var confirm_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ConfirmButton
@onready var slot_count_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ButtonContainer/SlotCountLabel

var max_menu_slots: int = 4
var today_menu: Array[StringName] = []


func _ready() -> void:
	_apply_theme_styles()
	if add_button:
		add_button.pressed.connect(_on_add)
	if remove_button:
		remove_button.pressed.connect(_on_remove)
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm)
	visibility_changed.connect(_on_visibility_changed)
	_populate_available()


func _on_visibility_changed() -> void:
	if visible:
		today_menu = TavernManager.get_todays_menu().duplicate()
		_populate_available.call_deferred()


func _populate_available() -> void:
	if available_list == null:
		return
	available_list.clear()
	var dishes: Array[Dictionary] = _get_unlocked_dishes()
	for dish: Dictionary in dishes:
		available_list.add_item(dish.get("name", ""))
	_refresh_today_menu()


func _on_add() -> void:
	if available_list == null:
		return
	var indices: Array = available_list.get_selected_items()
	if indices.is_empty():
		return
	if today_menu.size() >= max_menu_slots:
		return
	var dishes: Array[Dictionary] = _get_unlocked_dishes()
	var idx: int = indices[0]
	if idx < dishes.size():
		var dish_id = StringName(dishes[idx].get("id", ""))
		if not today_menu.has(dish_id):
			today_menu.append(dish_id)
			_refresh_today_menu()


func _on_remove() -> void:
	if today_menu_list == null:
		return
	var indices: Array = today_menu_list.get_selected_items()
	if indices.is_empty():
		return
	today_menu.remove_at(indices[0])
	_refresh_today_menu()


func _on_confirm() -> void:
	TavernManager.set_todays_menu(today_menu)
	menu_confirmed.emit(today_menu)
	GameUI.close_panel()


func _refresh_today_menu() -> void:
	if today_menu_list == null:
		return
	today_menu_list.clear()
	var dishes: Array[Dictionary] = _get_unlocked_dishes()
	for dish_id: StringName in today_menu:
		for dish: Dictionary in dishes:
			if StringName(dish.get("id", "")) == dish_id:
				today_menu_list.add_item(dish.get("name", ""))
				break
	if slot_count_label:
		slot_count_label.text = "%d / %d" % [today_menu.size(), max_menu_slots]


func _get_unlocked_dishes() -> Array[Dictionary]:
	## Query the recipe registry for dishes unlocked at the player's cooking level.
	var recipes: Array[Dictionary] = InventoryManager.get_unlocked_recipes()
	var result: Array[Dictionary] = []
	for recipe: Dictionary in recipes:
		result.append({
			"id": recipe.get("id", ""),
			"name": recipe.get("name", ""),
		})
	return result


func _apply_theme_styles() -> void:
	# Style the PanelContainer background
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.10, 0.08, 0.95) # Rich dark brown
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

	for list in [available_list, today_menu_list]:
		if list:
			list.add_theme_stylebox_override("panel", list_style)
			list.add_theme_stylebox_override("focus", list_style)
			list.add_theme_stylebox_override("selected", list_selected)
			list.add_theme_stylebox_override("selected_focus", list_selected)
			list.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
			list.add_theme_color_override("font_selected_color", Color(1.0, 0.92, 0.75))

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

	for btn in [add_button, remove_button, confirm_button]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_pressed)
			btn.add_theme_color_override("font_color", Color(0.9, 0.82, 0.6))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.7))
