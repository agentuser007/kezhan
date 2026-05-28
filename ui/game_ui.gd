extends CanvasLayer

var _open_panel: Control = null
var _locked: bool = false
var _just_opened: bool = false

@onready var day_night_cycle: CanvasLayer = $DayNightCycle
@onready var hud_layer: CanvasLayer = $HUDLayer
@onready var panel_layer: CanvasLayer = $PanelLayer
@onready var transition_layer: CanvasLayer = $TransitionLayer
@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect

@onready var hud_root: Control = $HUDLayer/HUDRoot
@onready var status_bars: Control = $HUDLayer/StatusBars
@onready var hotbar: Control = $HUDLayer/HotbarRoot
@onready var interaction_prompt: Control = $HUDLayer/InteractionPrompt
@onready var gold_row: Control = $HUDLayer/GoldRow
@onready var event_notifier: Control = $HUDLayer/EventNotifier
@onready var time_event_indicator: Control = $HUDLayer/TimeEventIndicator
@onready var farm_hud: Control = $HUDLayer/FarmHUD


func _ready() -> void:
	layer = 10
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	EventBus.screen_transition_started.connect(_on_transition_started)
	EventBus.screen_transition_finished.connect(_on_transition_finished)
	EventBus.inventory_changed.connect(_update_gold)
	EventBus.player_stats_changed.connect(_update_gold)
	_setup_gold_icon()
	_setup_gold_bg.call_deferred()
	_setup_hotbar_bg.call_deferred()
	_setup_backpack_hud_button.call_deferred()


func show_game_ui() -> void:
	visible = true
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	_update_gold()
	_update_farm_ui_visibility()


func hide_game_ui() -> void:
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_DISABLED


func is_panel_open() -> bool:
	return _open_panel != null and _open_panel.visible


func open_panel(panel: Control, locked: bool = false) -> void:
	if _open_panel != null and _open_panel != panel:
		_close_current_panel()
	if panel == null:
		return
	_open_panel = panel
	_locked = locked
	_just_opened = true
	_open_panel.visible = true
	get_tree().paused = true
	EventBus.game_paused.emit(true)


func close_panel() -> void:
	_close_current_panel()


func _close_current_panel() -> void:
	if _open_panel != null:
		_open_panel.visible = false
		_open_panel = null
	_locked = false
	get_tree().paused = false
	EventBus.game_paused.emit(false)


func fade_in(duration: float = 0.5) -> void:
	fade_rect.visible = true
	fade_rect.color.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween.finished


func fade_out(duration: float = 0.5) -> void:
	fade_rect.color.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween.finished
	fade_rect.visible = false


func _on_transition_started() -> void:
	if fade_rect:
		fade_rect.visible = true
		var tween: Tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 0.4)


func _on_transition_finished() -> void:
	if fade_rect:
		var tween: Tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 0.0, 0.3)
		await tween.finished
		fade_rect.visible = false


func get_panel(panel_name: StringName) -> Control:
	if panel_layer:
		return panel_layer.get_node_or_null(String(panel_name))
	return null


func _setup_gold_icon() -> void:
	var gold_icon: TextureRect = get_node_or_null("HUDLayer/GoldRow/GoldIcon")
	if gold_icon:
		var tex: Texture2D = load("res://ui/inventory/tools and items/Gold.png")
		if tex:
			gold_icon.texture = tex
		else:
			var placeholder := ColorRect.new()
			placeholder.color = Color(1, 0.85, 0, 1)
			placeholder.custom_minimum_size = Vector2(20, 20)
			gold_icon.add_child(placeholder)


func _setup_gold_bg() -> void:
	var gold_bg: PanelContainer = get_node_or_null("HUDLayer/GoldRow/GoldBg")
	if gold_bg:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.5)
		style.set_border_width_all(1)
		style.border_color = Color(0.7, 0.6, 0.2, 0.6)
		style.set_corner_radius_all(3)
		gold_bg.add_theme_stylebox_override("panel", style)


func _setup_hotbar_bg() -> void:
	if hotbar:
		var bg := PanelContainer.new()
		bg.name = "HotbarBg"
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.45)
		style.set_corner_radius_all(4)
		bg.add_theme_stylebox_override("panel", style)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hotbar.add_child(bg)
		hotbar.move_child(bg, 0)


func _update_gold() -> void:
	var gold_label: Label = get_node_or_null("HUDLayer/GoldRow/GoldLabel")
	if gold_label:
		gold_label.text = "%d 金" % PlayerData.gold
		gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
		gold_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		gold_label.add_theme_constant_override("outline_size", 2)


func _input(event: InputEvent) -> void:
	if _locked:
		return
	if event.is_action_pressed("toggle_inventory"):
		print("GameUI: toggle_inventory key pressed, is panel open: ", is_panel_open())
		if is_panel_open():
			close_panel()
		else:
			open_panel(panel_layer.get_node_or_null("InventoryPanel"))
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause"):
		if is_panel_open():
			close_panel()
		else:
			open_panel(panel_layer.get_node_or_null("PauseMenu"))
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_farm_info"):
		if is_panel_open() and _open_panel == panel_layer.get_node_or_null("FarmInfoPanel"):
			close_panel()
		elif not is_panel_open():
			var farm_panel: Control = panel_layer.get_node_or_null("FarmInfoPanel")
			if farm_panel and _is_farm_scene():
				farm_panel.show_panel()
				open_panel(farm_panel)
		get_viewport().set_input_as_handled()
	if is_panel_open() and not _just_opened and event.is_action_pressed("interact"):
		close_panel()
		get_viewport().set_input_as_handled()
	_just_opened = false


func _is_farm_scene() -> bool:
	var current_scene: Node = get_tree().current_scene
	return current_scene != null and current_scene.has_node("DirtLayer")


func _update_farm_ui_visibility() -> void:
	if farm_hud:
		farm_hud.visible = _is_farm_scene()


func _setup_backpack_hud_button() -> void:
	if hotbar == null:
		return
	var bp_btn := Button.new()
	bp_btn.name = "BackpackHUDButton"
	bp_btn.text = "背包 (Tab)"
	bp_btn.custom_minimum_size = Vector2(80, 40)
	bp_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bp_btn.focus_mode = Control.FOCUS_NONE
	bp_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	bp_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	bp_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bp_btn.grow_vertical = Control.GROW_DIRECTION_BOTH
	bp_btn.offset_left = -110
	bp_btn.offset_top = -20
	bp_btn.offset_right = -30
	bp_btn.offset_bottom = 20

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.12, 0.12, 0.14, 0.8)
	style_normal.set_border_width_all(1)
	style_normal.border_color = Color(0.7, 0.6, 0.2, 0.6)
	style_normal.set_corner_radius_all(4)
	bp_btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.22, 0.2, 0.15, 0.9)
	style_hover.set_border_width_all(1.5)
	style_hover.border_color = Color(1.0, 0.85, 0.3, 0.8)
	style_hover.set_corner_radius_all(4)
	bp_btn.add_theme_stylebox_override("hover", style_hover)

	bp_btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
	bp_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8, 1.0))
	bp_btn.add_theme_font_size_override("font_size", 12)

	hotbar.add_child(bp_btn)
	bp_btn.move_to_front()
	bp_btn.pressed.connect(_on_backpack_hud_pressed)


func _on_backpack_hud_pressed() -> void:
	print("GameUI: Backpack HUD button clicked")
	if is_panel_open():
		close_panel()
	else:
		open_panel(panel_layer.get_node_or_null("InventoryPanel"))
