extends Control

## ServeUI — Panel for serving customer orders.
## Shows order info & recipe on the left, matching backpack dishes on the right.

@onready var content_icon: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxOrder/ContentSection/ContentIcon
@onready var content_name: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxOrder/ContentSection/ContentInfo/ContentName
@onready var content_price: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxOrder/ContentSection/ContentInfo/ContentPrice
@onready var recipe_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxOrder/RecipeLabel
@onready var dish_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxBackpack/DishList
@onready var placeholder_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxMain/VBoxBackpack/PlaceholderLabel
@onready var serve_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionSection/ServeButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionSection/CloseButton

var _guest: GuestNPC = null
var _ordered_item_id: StringName = &""

func _ready() -> void:
	_apply_theme_styles()
	if serve_button:
		serve_button.pressed.connect(_on_serve)
	if close_button:
		close_button.pressed.connect(_on_close)
	visibility_changed.connect(_on_visibility_changed)
	refresh()


func _on_visibility_changed() -> void:
	if visible:
		refresh.call_deferred()


func setup(guest: GuestNPC) -> void:
	_guest = guest
	if _guest:
		_ordered_item_id = _guest.ordered_item_id
	refresh()


func refresh() -> void:
	if _guest == null or _ordered_item_id == &"":
		_show_empty()
		return

	var info := InventoryManager.get_item_info(_ordered_item_id)
	var item_name: String = info.get("name", "红烧肉")
	
	if content_icon:
		content_icon.texture = InventoryManager.get_item_icon(_ordered_item_id)
	if content_name:
		content_name.text = item_name
		
	# Pricing display
	var base_price = info.get("sell_price", 40)
	var final_price = int(base_price * 1.5)
	if content_price:
		content_price.text = "售价: %d 金 (含1.5x加成)" % final_price

	# Dynamic recipe display
	if recipe_label:
		var recipe_text := "需要配方原料:\n"
		var recipe = InventoryManager.get_recipe(_guest.ordered_recipe_id)
		if not recipe.is_empty():
			var ingredients: Array = recipe.get("ingredients", [])
			for ing in ingredients:
				var ing_name = ing.get("name", String(ing.id))
				var ing_amount = ing.get("amount", 1)
				recipe_text += "- %s x%d\n" % [ing_name, ing_amount]
			recipe_text += "可在灶台制作。"
		else:
			recipe_text += "- 猪肉 x2\n- 酱油 x1\n- 柴火 x1\n可在灶台制作。"
		recipe_label.text = recipe_text

	# Populate backpack matching dish
	if dish_list:
		dish_list.clear()
		var count = InventoryManager.get_amount(_ordered_item_id)
		if count > 0:
			var idx = dish_list.add_item("%s (x%d)" % [item_name, count], InventoryManager.get_item_icon(_ordered_item_id))
			dish_list.select(idx)
			if placeholder_label: placeholder_label.visible = false
			dish_list.visible = true
			if serve_button: serve_button.disabled = false
		else:
			if placeholder_label: placeholder_label.visible = true
			dish_list.visible = false
			if serve_button: serve_button.disabled = true


func _show_empty() -> void:
	if content_icon: content_icon.texture = null
	if content_name: content_name.text = "未选中顾客"
	if content_price: content_price.text = ""
	if recipe_label: recipe_label.text = ""
	if dish_list: dish_list.clear()
	if placeholder_label: placeholder_label.visible = true
	if serve_button: serve_button.disabled = true


func _on_serve() -> void:
	if _guest == null or _ordered_item_id == &"":
		return
		
	var count = InventoryManager.get_amount(_ordered_item_id)
	if count <= 0:
		return
		
	# Deduct item
	InventoryManager.remove_item(_ordered_item_id, 1)
	
	# Calculate revenue & reputation
	var info := InventoryManager.get_item_info(_ordered_item_id)
	var base_price = info.get("sell_price", 40)
	var final_price = int(base_price * 1.5)
	
	TavernManager.add_revenue(final_price)
	TavernManager.add_reputation(3.0)
	
	# Play sound sfx
	if AudioManager:
		AudioManager.play_sfx(&"sell")
		
	# Update guest state
	_guest.current_state = GuestNPC.GuestState.EATING
	_guest.eating_timer = 3.0
	_guest._update_bubble_text()
	
	# Event notification
	var item_name: String = info.get("name", "红烧肉")
	EventBus.notification_requested.emit("成功服务 %s！收入 %d 金" % [item_name, final_price])
	
	# Close panel
	GameUI.close_panel()


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

	if dish_list:
		dish_list.add_theme_stylebox_override("panel", list_style)
		dish_list.add_theme_stylebox_override("focus", list_style)
		dish_list.add_theme_stylebox_override("selected", list_selected)
		dish_list.add_theme_stylebox_override("selected_focus", list_selected)
		dish_list.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
		dish_list.add_theme_color_override("font_selected_color", Color(1.0, 0.92, 0.75))

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

	for btn in [serve_button, close_button]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_pressed)
			btn.add_theme_color_override("font_color", Color(0.9, 0.82, 0.6))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.7))
