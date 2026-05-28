extends Control

## MenuEditor — Allows the player to select today's menu from unlocked dishes.
## Reads recipes from InventoryManager recipe registry and filters by cooking level.

signal menu_confirmed(menu_items: Array[StringName])

@onready var available_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/AvailableList
@onready var today_menu_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/TodayMenuList
@onready var add_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ButtonContainer/AddButton
@onready var remove_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ButtonContainer/RemoveButton
@onready var confirm_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ConfirmButton
@onready var slot_count_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SlotCountLabel

var max_menu_slots: int = 4
var today_menu: Array[StringName] = []


func _ready() -> void:
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
		today_menu.append(StringName(dishes[idx].get("id", "")))
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
