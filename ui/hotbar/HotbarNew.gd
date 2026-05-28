extends Control

## Enhanced Hotbar with clearer visuals, selection highlight, and quantity overlay.

const SLOT_SIZE: int = 52
const SLOT_GAP: int = 4

@onready var slot_container: HBoxContainer = $SlotContainer

var _slot_controls: Array[Control] = []
var _slot_icons: Array[TextureRect] = []
var _slot_count_labels: Array[Label] = []
var _selected_index: int = 0
var _name_label: Label = null


func _ready() -> void:
	_name_label = Label.new()
	_name_label.name = "SelectedNameLabel"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_name_label.add_theme_constant_override("outline_size", 2)
	_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_name_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_name_label.position = Vector2(0, -25)
	add_child(_name_label)

	_build_slots()
	EventBus.inventory_changed.connect(_update_display)
	EventBus.hotbar_selection_changed.connect(_on_selection_changed)
	_update_display()


func _build_slots() -> void:
	if slot_container == null:
		return
	for child: Node in slot_container.get_children():
		child.queue_free()
	_slot_controls.clear()
	_slot_icons.clear()
	_slot_count_labels.clear()
	for i: int in InventoryManager.hotbar_size:
		var slot: Control = _create_slot(i)
		slot_container.add_child(slot)
		_slot_controls.append(slot)


func _create_slot(index: int) -> Control:
	## Build a single hotbar slot with icon, count overlay, and key label.
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.add_theme_constant_override("margin", 2)
	panel.tooltip_text = ""
	_apply_default_style(panel)

	# Use a MarginContainer for inner padding so icon doesn't touch borders
	var margin: MarginContainer = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	panel.add_child(margin)

	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(SLOT_SIZE - 12, SLOT_SIZE - 12)
	margin.add_child(icon)
	_slot_icons.append(icon)

	# Count label positioned as overlay in bottom-right corner
	var count_label: Label = Label.new()
	count_label.name = "CountLabel"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	count_label.add_theme_constant_override("outline_size", 2)
	# Anchor to bottom-right of the panel
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	count_label.position = Vector2(-2, -2)
	panel.add_child(count_label)
	_slot_count_labels.append(count_label)

	# Key binding label at bottom center
	var key_label: Label = Label.new()
	key_label.name = "KeyLabel"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 9)
	key_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.6))
	key_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	key_label.add_theme_constant_override("outline_size", 1)
	var key_text: String = str((index + 1) % 10)
	key_label.text = key_text
	key_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	key_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.add_child(key_label)

	return panel


func _apply_default_style(panel: PanelContainer) -> void:
	## Apply the default (unselected) slot style with 2px warm border.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.14, 0.75)
	style.set_border_width_all(2)
	style.border_color = Color(0.55, 0.50, 0.40, 0.7)
	style.set_corner_radius_all(4)
	style.set_shadow_color(Color(0, 0, 0, 0.3))
	style.shadow_size = 2
	panel.add_theme_stylebox_override("panel", style)


func _apply_selected_style(panel: PanelContainer) -> void:
	## Apply the selected slot style with golden 3px border and brighter bg.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.20, 0.15, 0.9)
	style.set_border_width_all(3)
	style.border_color = Color(1.0, 0.85, 0.3, 0.95)
	style.set_corner_radius_all(4)
	style.set_shadow_color(Color(1.0, 0.85, 0.3, 0.25))
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)


func _update_display() -> void:
	for i: int in _slot_controls.size():
		var slot: Control = _slot_controls[i]
		var icon: TextureRect = _slot_icons[i] if i < _slot_icons.size() else null
		var count_label: Label = _slot_count_labels[i] if i < _slot_count_labels.size() else null
		var item: Dictionary = InventoryManager.get_hotbar_item(i)
		if item.is_empty() or item.get("id", &"") == &"":
			if icon:
				icon.texture = null
			if count_label:
				count_label.text = ""
			slot.tooltip_text = ""
		else:
			if icon:
				icon.texture = _get_item_icon(item["id"])
			var info: Dictionary = InventoryManager.get_item_info(item["id"])
			var amount: int = item.get("amount", 0)
			if count_label:
				var is_tool: bool = info.get("category", "") == "工具"
				if is_tool:
					count_label.text = ""
				else:
					count_label.text = str(amount) if amount >= 1 else ""
			# Tooltip shows item display name and quantity
			var name_str: String = info.get("name", String(item["id"]))
			slot.tooltip_text = "%s (数量: %d)" % [name_str, amount]

	# Update the selected item name label above hotbar
	if _name_label:
		var selected_item: Dictionary = InventoryManager.get_selected_item()
		if selected_item.is_empty() or selected_item.get("id", &"") == &"":
			_name_label.text = ""
		else:
			var info: Dictionary = InventoryManager.get_item_info(selected_item["id"])
			var name_str: String = info.get("name", String(selected_item["id"]))
			var amount: int = selected_item.get("amount", 0)
			_name_label.text = "%s (数量: %d)" % [name_str, amount]

	_update_selection_highlight()


func _on_selection_changed(slot: int) -> void:
	_selected_index = slot
	_update_selection_highlight()


func _update_selection_highlight() -> void:
	for i: int in _slot_controls.size():
		var slot: Control = _slot_controls[i]
		if i == _selected_index:
			_apply_selected_style(slot)
		else:
			_apply_default_style(slot)


func _get_item_icon(item_id: StringName) -> Texture2D:
	return InventoryManager.get_item_icon(item_id)


func _unhandled_input(event: InputEvent) -> void:
	for i: int in InventoryManager.hotbar_size:
		var action: String = "hotbar_%d" % ((i + 1) % 10)
		if event.is_action_pressed(action):
			InventoryManager.select_hotbar_slot(i)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("scroll_up"):
		InventoryManager.select_hotbar_slot(InventoryManager.selected_hotbar_slot - 1)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("scroll_down"):
		InventoryManager.select_hotbar_slot(InventoryManager.selected_hotbar_slot + 1)
		get_viewport().set_input_as_handled()
