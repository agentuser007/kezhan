extends Control

const MAX_SLOTS: int = 3

@onready var resume_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SettingsButton
@onready var save_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SaveButton
@onready var load_button: Button = $PanelContainer/MarginContainer/VBoxContainer/LoadButton
@onready var quit_button: Button = $PanelContainer/MarginContainer/VBoxContainer/QuitButton

var _slot_panel: Control = null
var _slot_mode: String = ""


func _ready() -> void:
	if resume_button:
		resume_button.pressed.connect(_on_resume)
	if settings_button:
		settings_button.pressed.connect(_on_settings)
	if save_button:
		save_button.pressed.connect(_on_save)
	if load_button:
		load_button.pressed.connect(_on_load)
	if quit_button:
		quit_button.pressed.connect(_on_quit)


func _on_resume() -> void:
	GameUI.close_panel()


func _on_settings() -> void:
	var settings: Control = GameUI.get_panel(&"SettingsPanel")
	if settings:
		GameUI.open_panel(settings)


func _on_save() -> void:
	_show_slot_panel("save")


func _on_load() -> void:
	_show_slot_panel("load")


func _on_quit() -> void:
	GameUI.close_panel()
	SceneManagerAutoload.go_to_main_menu()


func _show_slot_panel(mode: String) -> void:
	_slot_mode = mode
	if _slot_panel:
		_slot_panel.queue_free()
	_slot_panel = Control.new()
	_slot_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	_slot_panel.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -160.0
	panel.offset_top = -120.0
	panel.offset_right = 160.0
	panel.offset_bottom = 120.0
	_slot_panel.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "保存到..." if mode == "save" else "读取存档..."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var slots: Array[Dictionary] = GameManager.get_save_slots()
	for i: int in MAX_SLOTS:
		var slot_data: Dictionary = slots[i] if i < slots.size() else {"slot": i + 1, "exists": false}
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(240, 36)
		if slot_data.get("exists", false):
			btn.text = "存档%d - 第%d天 %s" % [slot_data.slot, slot_data.get("day", 1), slot_data.get("season", "春")]
		else:
			btn.text = "存档%d - 空" % (i + 1)
		if mode == "load" and not slot_data.get("exists", false):
			btn.disabled = true
		btn.pressed.connect(_on_slot_selected.bind(slot_data.get("slot", i + 1), slot_data.get("exists", false)))
		vbox.add_child(btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "取消"
	cancel_btn.pressed.connect(_on_slot_cancel)
	vbox.add_child(cancel_btn)

	add_child(_slot_panel)


func _on_slot_selected(slot: int, exists: bool) -> void:
	if _slot_panel:
		_slot_panel.queue_free()
		_slot_panel = null
	if _slot_mode == "save":
		GameManager.save_game(slot)
	elif _slot_mode == "load" and exists:
		GameManager.load_game(slot)
	GameUI.close_panel()


func _on_slot_cancel() -> void:
	if _slot_panel:
		_slot_panel.queue_free()
		_slot_panel = null
