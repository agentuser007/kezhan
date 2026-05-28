extends Control

const MAX_SLOTS: int = 3

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var co_op_button: Button = $VBoxContainer/CoOpButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@onready var load_panel: Control = $LoadPanel
@onready var settings_panel: Control = $SettingsPanel

@onready
var load_close_button: Button = $LoadPanel/PanelContainer/MarginContainer/VBoxContainer/CloseButton

var _slot_buttons: Array[Button] = []
var _slot_labels: Array[Label] = []


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game)
	load_game_button.pressed.connect(_on_load_game)
	co_op_button.pressed.connect(_on_co_op)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	co_op_button.disabled = true
	if load_panel:
		load_panel.visible = false
	if settings_panel:
		settings_panel.visible = false
	if load_close_button:
		load_close_button.pressed.connect(_on_load_close)
	_build_save_slots()
	_apply_button_styles()


func _build_save_slots() -> void:
	var vbox: VBoxContainer = $LoadPanel/PanelContainer/MarginContainer/VBoxContainer
	var empty_label: Label = vbox.get_node_or_null("EmptyLabel")
	var slots_info: Array[Dictionary] = GameManager.get_save_slots()
	var has_saves: bool = false
	for s: Dictionary in slots_info:
		if s.get("exists", false):
			has_saves = true
			break
	if empty_label:
		empty_label.visible = not has_saves
	for i: int in MAX_SLOTS:
		var slot_data: Dictionary = (
			slots_info[i] if i < slots_info.size() else {"slot": i + 1, "exists": false}
		)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(240, 36)
		if slot_data.get("exists", false):
			btn.text = (
				"存档%d - 第%d天 %s 声望%.0f"
				% [
					slot_data.slot,
					slot_data.get("day", 1),
					slot_data.get("season", "春"),
					slot_data.get("reputation", 0.0)
				]
			)
		else:
			btn.text = "存档%d - 空" % (i + 1)
		btn.pressed.connect(
			_on_slot_selected.bind(slot_data.get("slot", i + 1), slot_data.get("exists", false))
		)
		vbox.add_child(btn)
		vbox.move_child(btn, vbox.get_child_count() - 2)
		_slot_buttons.append(btn)


func _on_slot_selected(slot: int, exists: bool) -> void:
	if exists:
		GameManager.load_game(slot)
	else:
		GameManager.new_game()


func _apply_button_styles() -> void:
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.08, 0.04, 0.9)
	btn_style.border_color = Color(0.76, 0.65, 0.35, 0.9)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(4)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.14, 0.07, 0.95)
	var btn_pressed: StyleBoxFlat = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.08, 0.05, 0.02, 0.95)
	for btn: Button in [
		new_game_button, load_game_button, co_op_button, settings_button, quit_button
	]:
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_color_override("font_color", Color(0.9, 0.82, 0.55))
		btn.add_theme_color_override("font_hover_color", Color(1, 0.92, 0.65))
		btn.add_theme_font_size_override("font_size", 18)


func _on_new_game() -> void:
	GameManager.new_game()


func _on_load_game() -> void:
	if load_panel:
		load_panel.visible = true


func _on_co_op() -> void:
	pass


func _on_settings() -> void:
	if settings_panel:
		settings_panel.visible = true


func _on_quit() -> void:
	GameManager.quit_game()


func _on_load_close() -> void:
	if load_panel:
		load_panel.visible = false
