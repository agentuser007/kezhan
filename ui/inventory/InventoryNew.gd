extends Control

const SLOT_SIZE: int = 64
const COLUMNS: int = 6

var move_button: Button = null
var _slot_controls: Array[Control] = []
var _selected_index: int = -1

@onready var panel_container: PanelContainer = $PanelContainer
@onready var grid: GridContainer = \
	$PanelContainer/MarginContainer/VBoxContainer/GridContainer
@onready var detail_panel: HBoxContainer = \
	$PanelContainer/MarginContainer/VBoxContainer/DetailPanel
@onready var item_name_label: Label = \
	$PanelContainer/MarginContainer/VBoxContainer/DetailPanel/ItemName
@onready var item_desc_label: Label = \
	$PanelContainer/MarginContainer/VBoxContainer/DetailPanel/ItemDesc
@onready var use_button: Button = \
	$PanelContainer/MarginContainer/VBoxContainer/DetailPanel/UseButton
@onready var close_button: Button = \
	$PanelContainer/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	if use_button:
		use_button.pressed.connect(_on_use_pressed)
		use_button.visible = false

	if detail_panel:
		move_button = Button.new()
		move_button.name = "MoveButton"
		move_button.text = "放入快捷栏"
		move_button.custom_minimum_size = Vector2(100, 0)
		move_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		detail_panel.add_child(move_button)
		move_button.pressed.connect(_on_move_pressed)
		move_button.visible = false

	if close_button:
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		close_button.focus_mode = Control.FOCUS_NONE

		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color(0.18, 0.12, 0.12, 0.8)
		style_normal.set_border_width_all(1)
		style_normal.border_color = Color(0.6, 0.3, 0.3, 0.6)
		style_normal.set_corner_radius_all(3)
		close_button.add_theme_stylebox_override("normal", style_normal)

		var style_hover := StyleBoxFlat.new()
		style_hover.bg_color = Color(0.35, 0.15, 0.15, 0.95)
		style_hover.set_border_width_all(1.5)
		style_hover.border_color = Color(0.9, 0.4, 0.4, 0.9)
		style_hover.set_corner_radius_all(3)
		close_button.add_theme_stylebox_override("hover", style_hover)

		close_button.add_theme_color_override("font_color", Color(0.85, 0.7, 0.7, 1.0))
		close_button.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.85, 1.0))
		close_button.add_theme_font_size_override("font_size", 12)

		close_button.pressed.connect(_on_close_pressed)
		close_button.visible = true

	EventBus.inventory_changed.connect(_update_display)
	visibility_changed.connect(_on_visibility_changed)
	_build_slots()
	_update_display()


func _on_visibility_changed() -> void:
	if visible:
		# Refresh display when panel becomes visible to ensure
		# it shows the current inventory state
		_update_display.call_deferred()


func _build_slots() -> void:
	if grid == null:
		return

	# Clear grid children
	for child: Node in grid.get_children():
		child.queue_free()

	# Clear any dynamically added hotbar elements from previous runs
	var v_box = grid.get_parent()
	if v_box:
		var old_lbl = v_box.get_node_or_null("HotbarLabel")
		if old_lbl:
			old_lbl.queue_free()
		var old_cnt = v_box.get_node_or_null("HotbarContainer")
		if old_cnt:
			old_cnt.queue_free()

	_slot_controls.clear()
	grid.columns = COLUMNS

	# Build backpack slots (indices 0 to 29)
	for i: int in InventoryManager.inventory_size:
		var slot: Control = _create_slot(i)
		grid.add_child(slot)
		_slot_controls.append(slot)

	# Dynamically add the separate hotbar row (indices 30 to 39)
	if v_box:
		var grid_idx = grid.get_index()

		var hotbar_label := Label.new()
		hotbar_label.name = "HotbarLabel"
		hotbar_label.text = "快捷栏"
		hotbar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hotbar_label.add_theme_font_size_override("font_size", 13)
		hotbar_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4, 0.9))
		v_box.add_child(hotbar_label)
		v_box.move_child(hotbar_label, grid_idx + 1)

		var hotbar_container := HBoxContainer.new()
		hotbar_container.name = "HotbarContainer"
		hotbar_container.alignment = BoxContainer.ALIGNMENT_CENTER
		hotbar_container.add_theme_constant_override("separation", 6)
		v_box.add_child(hotbar_container)
		v_box.move_child(hotbar_container, grid_idx + 2)

		# Build hotbar slots
		for i: int in InventoryManager.hotbar_size:
			var slot_idx: int = InventoryManager.inventory_size + i
			var slot: Control = _create_slot(slot_idx)
			# Make hotbar slots slightly more compact in the backpack menu
			slot.custom_minimum_size = Vector2(52, 52)
			var margin: MarginContainer = slot.get_node_or_null("MarginContainer")
			if margin:
				margin.add_theme_constant_override("margin_top", 2)
				margin.add_theme_constant_override("margin_bottom", 2)
				margin.add_theme_constant_override("margin_left", 2)
				margin.add_theme_constant_override("margin_right", 2)
			var icon: TextureRect = slot.get_node_or_null("MarginContainer/Icon")
			if icon:
				icon.custom_minimum_size = Vector2(40, 40)
			hotbar_container.add_child(slot)
			_slot_controls.append(slot)


func _create_slot(index: int) -> Control:
	var slot: PanelContainer = PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.name = "Slot_%d" % index
	slot.tooltip_text = ""

	_apply_normal_style(slot)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	slot.add_child(margin)

	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(SLOT_SIZE - 12, SLOT_SIZE - 12)
	margin.add_child(icon)

	var count_label: Label = Label.new()
	count_label.name = "CountLabel"
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	count_label.add_theme_constant_override("outline_size", 2)
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	count_label.position = Vector2(-2, -2)
	slot.add_child(count_label)

	# Add transparent button on top for mouse events
	var btn: Button = Button.new()
	btn.name = "Button"
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(btn)

	btn.pressed.connect(_on_slot_pressed.bind(index))
	return slot


func _on_slot_pressed(index: int) -> void:
	_selected_index = index
	_update_selection_highlight()
	_update_detail()


func _on_move_pressed() -> void:
	if _selected_index < 0 or _selected_index >= InventoryManager.items.size():
		return
	var item: Dictionary = InventoryManager.items[_selected_index]
	var item_id: StringName = item.get("id", &"")
	if item_id == &"":
		return

	if _selected_index < InventoryManager.inventory_size:
		# Item is in backpack. Move to hotbar.
		var target_idx: int = -1
		var start = InventoryManager.inventory_size
		var end = start + InventoryManager.hotbar_size
		for i in range(start, end):
			if InventoryManager.items[i].get("id", &"") == &"":
				target_idx = i
				break
		if target_idx == -1:
			var active = InventoryManager.selected_hotbar_slot
			target_idx = active + InventoryManager.inventory_size

		InventoryManager.move_item(_selected_index, target_idx)
		_selected_index = target_idx
	else:
		# Item is in hotbar. Move to backpack.
		var target_idx: int = -1
		for i in range(0, InventoryManager.inventory_size):
			if InventoryManager.items[i].get("id", &"") == &"":
				target_idx = i
				break
		if target_idx != -1:
			InventoryManager.move_item(_selected_index, target_idx)
			_selected_index = target_idx

	_update_display()


func _update_display() -> void:
	for i: int in _slot_controls.size():
		var slot: Control = _slot_controls[i]
		var icon: TextureRect = slot.get_node_or_null("MarginContainer/Icon")
		var count_label: Label = slot.get_node_or_null("CountLabel")

		if i >= InventoryManager.items.size():
			continue
		var item: Dictionary = InventoryManager.items[i]
		if item.is_empty() or item.get("id", &"") == &"":
			if icon:
				icon.texture = null
			if count_label:
				count_label.text = ""
			slot.tooltip_text = ""
		else:
			if icon:
				icon.texture = _get_item_icon(item["id"])
			var amount: int = item.get("amount", 0)
			var info: Dictionary = InventoryManager.get_item_info(item["id"])
			if count_label:
				var is_tool: bool = info.get("category", "") == "工具"
				if is_tool:
					count_label.text = ""
				else:
					count_label.text = str(amount) if amount >= 1 else ""
			var name_str: String = info.get("name", String(item["id"]))
			slot.tooltip_text = "%s (数量: %d)" % [name_str, amount]
	_update_selection_highlight()
	_update_detail()


func _apply_normal_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.14, 0.75)
	style.set_border_width_all(2)
	style.border_color = Color(0.55, 0.50, 0.40, 0.7)
	style.set_corner_radius_all(4)
	style.set_shadow_color(Color(0, 0, 0, 0.3))
	style.shadow_size = 2
	panel.add_theme_stylebox_override("panel", style)


func _apply_selected_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.20, 0.15, 0.9)
	style.set_border_width_all(3)
	style.border_color = Color(1.0, 0.85, 0.3, 0.95)
	style.set_corner_radius_all(4)
	style.set_shadow_color(Color(1.0, 0.85, 0.3, 0.25))
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)


func _update_selection_highlight() -> void:
	for i: int in _slot_controls.size():
		var slot: Control = _slot_controls[i]
		if i == _selected_index:
			_apply_selected_style(slot)
		else:
			_apply_normal_style(slot)


func _update_detail() -> void:
	if item_name_label == null or item_desc_label == null:
		return
	if _selected_index < 0 or _selected_index >= InventoryManager.items.size():
		item_name_label.text = ""
		item_desc_label.text = ""
		if use_button:
			use_button.visible = false
		if move_button:
			move_button.visible = false
		return
	var item: Dictionary = InventoryManager.items[_selected_index]
	var item_id: StringName = item.get("id", &"")
	if item_id == &"":
		item_name_label.text = ""
		item_desc_label.text = ""
		if use_button:
			use_button.visible = false
		if move_button:
			move_button.visible = false
		return
	var info: Dictionary = InventoryManager.get_item_info(item_id)
	item_name_label.text = String(info.get("name", ""))
	var category: String = String(info.get("category", ""))
	var sell_price: int = info.get("sell_price", 0)
	item_desc_label.text = "类别: %s  售价: %d金" % [category, sell_price]

	if use_button:
		use_button.visible = _is_usable(item_id)

	if move_button:
		move_button.visible = true
		if _selected_index < InventoryManager.inventory_size:
			move_button.text = "放入快捷栏"
		else:
			move_button.text = "收回背包"


func _is_usable(item_id: StringName) -> bool:
	var info: Dictionary = InventoryManager.get_item_info(item_id)
	var category: StringName = info.get("category", &"")
	match category:
		&"蔬菜", &"水果", &"肉类", &"蛋类", &"饮品", &"主食", &"菜类":
			return true
		_:
			return false


func _on_use_pressed() -> void:
	if _selected_index < 0 or _selected_index >= InventoryManager.items.size():
		return
	var item: Dictionary = InventoryManager.items[_selected_index]
	var item_id: StringName = item.get("id", &"")
	if item_id == &"":
		return
	if not _is_usable(item_id):
		return
	var info: Dictionary = InventoryManager.get_item_info(item_id)
	var category: StringName = info.get("category", &"")
	_apply_use_effect(category)
	InventoryManager.remove_item(item_id, 1)
	_selected_index = -1
	_update_display()


func _apply_use_effect(category: StringName) -> void:
	PlayerData.current_stamina = mini(PlayerData.current_stamina + 5, PlayerData.max_stamina)
	PlayerData.current_hp = mini(PlayerData.current_hp + 3, PlayerData.max_hp)
	PlayerData.apply_food(category, 1.0)
	TimeManager.eat_meal()


func _get_item_icon(item_id: StringName) -> Texture2D:
	return InventoryManager.get_item_icon(item_id)


func _on_close_pressed() -> void:
	GameUI.close_panel()
