extends Control

@onready var page_one: Control = $PageOne
@onready var page_two: Control = $PageTwo

@onready var revenue_label: Label = $PageOne/VBox/RevenueLabel
@onready var reputation_label: Label = $PageOne/VBox/ReputationLabel
@onready var harvest_label: Label = $PageOne/VBox/HarvestLabel
@onready var next_button: Button = $PageOne/NextButton

@onready var training_container: VBoxContainer = $PageTwo/VBox/TrainingContainer
@onready var confirm_button: Button = $PageTwo/ConfirmButton
@onready var penalty_label: Label = $PageTwo/PenaltyLabel

var _yesterday_revenue: float = 0.0
var _yesterday_reputation_change: float = 0.0
var _yesterday_harvests: Array[String] = []
var _wushu_submenu: VBoxContainer = null

const WUSHU_OPTIONS: Array[StringName] = [
	&"拳法", &"腿法", &"剑术", &"内功",
]


func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	page_one.visible = true
	page_two.visible = false


func show_summary(revenue: float, reputation_change: float, harvests: Array[String]) -> void:
	_yesterday_revenue = revenue
	_yesterday_reputation_change = reputation_change
	_yesterday_harvests = harvests

	# Rolling number tween
	var tween: Tween = create_tween()
	
	if revenue_label:
		revenue_label.text = "营业额: 0.0 金"
		if revenue > 0.0:
			tween.tween_method(
				func(v: float): revenue_label.text = "营业额: %.1f 金" % v,
				0.0, revenue, 1.2
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			revenue_label.text = "营业额: 0.0 金"
			
	if reputation_label:
		reputation_label.text = "美誉度: +0.0"
		if reputation_change != 0.0:
			var sign_char: String = "+" if reputation_change > 0 else ""
			tween.parallel().tween_method(
				func(v: float): reputation_label.text = "美誉度: %s%.1f" % [sign_char if v >= 0 else "", v],
				0.0, reputation_change, 1.2
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			reputation_label.text = "美誉度: +0.0"

	if harvest_label:
		harvest_label.text = "收获: %s" % ", ".join(harvests) if harvests.size() > 0 else "无"

	var page_one_vbox: VBoxContainer = page_one.get_node_or_null("VBox") if page_one else null
	var info_label: Label = page_one_vbox.get_node_or_null("InfoLabel") if page_one_vbox else null
	if info_label == null:
		info_label = Label.new()
		info_label.name = "InfoLabel"
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var vbox: VBoxContainer = $PageOne/VBox
		vbox.add_child(info_label)
		vbox.move_child(info_label, vbox.get_child_count() - 1)
	info_label.text = "体力 %d/%d | 烹饪 Lv.%d | 金币 %d" % [
		PlayerData.current_stamina, PlayerData.max_stamina,
		PlayerData.cooking_level, PlayerData.gold
	]

	page_one.visible = true
	page_one.modulate.a = 1.0
	page_one.scale = Vector2.ONE
	page_two.visible = false
	visible = true


func _on_next_pressed() -> void:
	if page_one == null or page_two == null:
		return
		
	# Play clink / page flip BGM / SFX
	if AudioManager:
		AudioManager.play_sfx(&"bell")

	# Paper flip fade and scale transition
	var transition_tween: Tween = create_tween()
	transition_tween.tween_property(page_one, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	transition_tween.parallel().tween_property(page_one, "scale", Vector2(0.9, 0.9), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	transition_tween.tween_callback(func():
		page_one.visible = false
		page_one.scale = Vector2.ONE
		page_one.modulate.a = 1.0
		
		page_two.visible = true
		page_two.modulate.a = 0.0
		page_two.scale = Vector2(1.1, 1.1)
		
		if TimeManager.is_penalty_wake:
			penalty_label.visible = true
			penalty_label.text = "因过度劳累，错过了今日晨练"
			_set_training_enabled(false)
		else:
			penalty_label.visible = false
			_set_training_enabled(true)
			_load_yesterday_training()
	)
	
	transition_tween.tween_property(page_two, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	transition_tween.parallel().tween_property(page_two, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_confirm_pressed() -> void:
	_save_training_selection()
	GameUI.close_panel()
	DayTurnoverProcessor.confirm_summary()


func _set_training_enabled(enabled: bool) -> void:
	if training_container == null:
		return
	for child: Node in training_container.get_children():
		if child is CheckBox:
			child.disabled = not enabled
		if child is VBoxContainer:
			for sub: Node in child.get_children():
				if sub is CheckBox:
					sub.disabled = not enabled


func _load_yesterday_training() -> void:
	if training_container == null:
		return
	for child: Node in training_container.get_children():
		if child is CheckBox:
			var key: StringName = StringName(child.name)
			if PlayerData.morning_training.has(key):
				child.button_pressed = PlayerData.morning_training[key]
	_ensure_wushu_submenu()
	var wushu_check: CheckBox = training_container.get_node_or_null("武学")
	if wushu_check and wushu_check.button_pressed:
		_show_wushu_options()
		var saved: StringName = PlayerData.morning_training_wushu_selection
		if not saved.is_empty() and _wushu_submenu:
			for opt: CheckBox in _wushu_submenu.get_children():
				if StringName(opt.name) == saved:
					opt.button_pressed = true
					break


func _ensure_wushu_submenu() -> void:
	if _wushu_submenu != null:
		return
	_wushu_submenu = VBoxContainer.new()
	_wushu_submenu.name = "WushuSubmenu"
	_wushu_submenu.add_theme_constant_override("separation", 2)
	_wushu_submenu.offset_left = 20.0
	for opt_name: StringName in WUSHU_OPTIONS:
		var opt := CheckBox.new()
		opt.name = String(opt_name)
		opt.text = String(opt_name)
		opt.add_theme_font_size_override("font_size", 12)
		opt.pressed.connect(_on_wushu_option_selected.bind(opt))
		_wushu_submenu.add_child(opt)
	training_container.add_child(_wushu_submenu)
	var wushu_check: CheckBox = training_container.get_node_or_null("武学")
	if wushu_check:
		wushu_check.toggled.connect(_on_wushu_toggled)


func _on_wushu_toggled(is_on: bool) -> void:
	if is_on:
		_show_wushu_options()
	else:
		_hide_wushu_options()


func _show_wushu_options() -> void:
	if _wushu_submenu:
		_wushu_submenu.visible = true


func _hide_wushu_options() -> void:
	if _wushu_submenu:
		_wushu_submenu.visible = false
		for opt: CheckBox in _wushu_submenu.get_children():
			opt.button_pressed = false


func _on_wushu_option_selected(opt: CheckBox) -> void:
	if not opt.button_pressed:
		return
	for other: CheckBox in _wushu_submenu.get_children():
		if other != opt:
			other.button_pressed = false


func _save_training_selection() -> void:
	if training_container == null:
		return
	for child: Node in training_container.get_children():
		if child is CheckBox:
			var key: StringName = StringName(child.name)
			PlayerData.morning_training[key] = child.button_pressed
	PlayerData.morning_training_wushu_selection = &""
	if _wushu_submenu and _wushu_submenu.visible:
		for opt: CheckBox in _wushu_submenu.get_children():
			if opt.button_pressed:
				PlayerData.morning_training_wushu_selection = StringName(opt.name)
				break
