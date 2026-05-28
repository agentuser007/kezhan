extends Control

## BarnManagementUI — Overview panel for the barn.
## Shows all animals with status, feeding/watering state, products ready,
## and batch action buttons. Receives reference to BarnInterior.

@onready var occupancy_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderSection/OccupancyLabel
@onready var animal_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/AnimalListSection/ScrollContainer/AnimalList
@onready var products_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ProductsSection/ProductsLabel
@onready var feed_all_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionSection/FeedAllButton
@onready var water_all_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionSection/WaterAllButton
@onready var collect_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionSection/CollectButton
@onready var quick_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionSection/QuickButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

## Reference to the BarnInterior being managed.
var _barn: BarnInterior = null


func _ready() -> void:
	if feed_all_button:
		feed_all_button.pressed.connect(_on_feed_all)
	if water_all_button:
		water_all_button.pressed.connect(_on_water_all)
	if collect_button:
		collect_button.pressed.connect(_on_collect)
	if quick_button:
		quick_button.pressed.connect(_on_quick)
	if close_button:
		close_button.pressed.connect(_on_close)
	EventBus.animal_state_changed.connect(_on_animal_state_changed)
	BarnData.animal_added.connect(_on_animal_added_or_removed)
	BarnData.animal_removed.connect(_on_animal_added_or_removed)
	visibility_changed.connect(_on_visibility_changed)
	refresh()


func _on_visibility_changed() -> void:
	if visible:
		refresh.call_deferred()


func setup(barn: BarnInterior) -> void:
	## Set the barn reference and refresh the display.
	_barn = barn
	refresh()


func refresh() -> void:
	## Rebuild the entire display from current barn state.
	_update_occupancy()
	_rebuild_animal_list()
	_update_products()
	_update_buttons()


func _update_occupancy() -> void:
	if occupancy_label == null or _barn == null:
		return
	occupancy_label.text = "容量: %.1f / %.1f" % [BarnData.get_occupancy(), BarnData.MAX_BARN_CAPACITY]


func _rebuild_animal_list() -> void:
	if animal_list == null:
		return
	for child: Node in animal_list.get_children():
		animal_list.remove_child(child)
		child.queue_free()
	if _barn == null:
		return

	for animal: AnimalBase in _barn.animals:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size = Vector2(0, 32)

		# State icon (emoji-like text)
		var state_label: Label = Label.new()
		state_label.add_theme_font_size_override("font_size", 14)
		state_label.custom_minimum_size = Vector2(24, 24)
		match animal.current_state:
			AnimalBase.AnimalState.HEALTHY:
				state_label.text = "❤️"
			AnimalBase.AnimalState.HUNGRY:
				state_label.text = "⚠️"
			AnimalBase.AnimalState.WEAK:
				state_label.text = "💀"
			AnimalBase.AnimalState.DEAD:
				state_label.text = "☠️"
		row.add_child(state_label)

		# Animal type emoji
		var type_label: Label = Label.new()
		type_label.add_theme_font_size_override("font_size", 14)
		type_label.custom_minimum_size = Vector2(24, 24)
		if animal.animal_type == &"Pig":
			type_label.text = "🐷"
		elif animal.animal_type == &"Chicken":
			type_label.text = "🐔"
		else:
			type_label.text = "🐾"
		row.add_child(type_label)
		
		# Name with age indicator
		var name_label: Label = Label.new()
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.custom_minimum_size = Vector2(80, 24)
		var age_indicator: String = " (幼年)" if animal.is_baby else " (成年)"
		name_label.text = (animal.display_name if animal.display_name else String(animal.animal_type)) + age_indicator
		row.add_child(name_label)

		# Status text
		var status_label: Label = Label.new()
		status_label.add_theme_font_size_override("font_size", 11)
		status_label.custom_minimum_size = Vector2(50, 24)
		match animal.current_state:
			AnimalBase.AnimalState.HEALTHY:
				status_label.text = "健康"
				status_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
			AnimalBase.AnimalState.HUNGRY:
				status_label.text = "饥饿"
				status_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
			AnimalBase.AnimalState.WEAK:
				status_label.text = "虚弱"
				status_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			AnimalBase.AnimalState.DEAD:
				status_label.text = "死亡"
				status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(status_label)

		# Fed indicator
		var fed_label: Label = Label.new()
		fed_label.add_theme_font_size_override("font_size", 11)
		fed_label.custom_minimum_size = Vector2(36, 24)
		fed_label.text = "🍗已喂" if animal.fed_today else "🍗未喂"
		fed_label.add_theme_color_override("font_color",
			Color(0.6, 1, 0.6) if animal.fed_today else Color(1, 0.5, 0.3))
		row.add_child(fed_label)

		# Watered indicator
		var water_label: Label = Label.new()
		water_label.add_theme_font_size_override("font_size", 11)
		water_label.custom_minimum_size = Vector2(36, 24)
		water_label.text = "💧已喂" if animal.watered_today else "💧未喂"
		water_label.add_theme_color_override("font_color",
			Color(0.6, 1, 0.6) if animal.watered_today else Color(1, 0.5, 0.3))
		row.add_child(water_label)

		# Products ready
		# Products ready
		if animal.products_ready > 0:
			var prod_label: Label = Label.new()
			prod_label.add_theme_font_size_override("font_size", 11)
			prod_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
			var product_info: Dictionary = InventoryManager.get_item_info(animal.product_item_id)
			var product_name: String = product_info.get("name", String(animal.product_item_id))
			prod_label.text = "📦%s x%d" % [product_name, animal.products_ready]
			row.add_child(prod_label)

		animal_list.add_child(row)


func _update_products() -> void:
	if products_label == null or _barn == null:
		return
	var total_ready: int = 0
	var product_names: Array[String] = []
	for animal: AnimalBase in _barn.animals:
		if animal.products_ready > 0:
			total_ready += animal.products_ready
			var info: Dictionary = InventoryManager.get_item_info(animal.product_item_id)
			var name_str: String = info.get("name", String(animal.product_item_id))
			product_names.append("%s x%d" % [name_str, animal.products_ready])
	if total_ready > 0:
		products_label.text = "产物待收: %s" % " ".join(product_names)
		products_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	else:
		products_label.text = "暂无产物可收"
		products_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))


func _update_buttons() -> void:
	if _barn == null:
		return
	var has_animals: bool = _barn.animals.size() > 0
	if feed_all_button:
		feed_all_button.disabled = not has_animals
	if water_all_button:
		water_all_button.disabled = not has_animals
	if collect_button:
		var has_products: bool = false
		for animal: AnimalBase in _barn.animals:
			if animal.products_ready > 0:
				has_products = true
				break
		collect_button.disabled = not has_products
	if quick_button:
		quick_button.disabled = not has_animals


func _on_feed_all() -> void:
	if _barn == null:
		return
	var feed_type: StringName = _barn._get_feed_type_for_animals()
	var fed: int = _barn.feed_all(feed_type)
	EventBus.notification_requested.emit("已喂食 %d 只动物" % fed)
	refresh()


func _on_water_all() -> void:
	if _barn == null:
		return
	_barn.water_all()
	EventBus.notification_requested.emit("已喂水所有动物")
	refresh()


func _on_collect() -> void:
	if _barn == null:
		return
	var collected: Dictionary = _barn.collect_all_products()
	if collected.is_empty():
		EventBus.notification_requested.emit("没有可收取的产物")
		return
	# Note: AnimalBase.collect_products() already adds items to inventory,
	# so we only build the summary notification here.
	var summary_parts: Array[String] = []
	for item_id: StringName in collected:
		var info: Dictionary = InventoryManager.get_item_info(item_id)
		summary_parts.append("%sx%d" % [info.get("name", ""), collected[item_id]])
	EventBus.notification_requested.emit("收取: %s" % " ".join(summary_parts))
	refresh()


func _on_quick() -> void:
	if _barn == null:
		return
	_barn._quick_feed_and_collect()
	EventBus.notification_requested.emit("一键操作完成")
	refresh()


func _on_animal_state_changed(_animal_id: StringName, _new_state: int) -> void:
	## Refresh when any animal state changes.
	refresh()


func _on_animal_added_or_removed(_animal_data_or_id) -> void:
	## Refresh when animals are added or removed from BarnData
	refresh()


func _on_close() -> void:
	GameUI.close_panel()
