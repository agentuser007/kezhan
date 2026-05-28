extends Control

@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var hp_bar: ProgressBar = $HPBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var sanity_bar: ProgressBar = $SanityBar
@onready var stamina_label: Label = $StaminaBar/Label

var _bg_style: StyleBoxTexture = null
var _fill_style: StyleBoxTexture = null
var _styles_applied: bool = false
var _fallback_applied: bool = false
var _hp_label: Label = null
var _mana_label: Label = null
var _sanity_label: Label = null


func _ready() -> void:
	_setup_styles()
	_create_bar_labels()
	EventBus.inventory_changed.connect(_update_display)
	EventBus.player_stats_changed.connect(_update_display)
	_update_display()


func _setup_styles() -> void:
	var bg_tex: Texture2D = load("res://ui/energy/Energy Bar Background.png")
	var fill_tex: Texture2D = load("res://ui/energy/Energy Bar Filled.png")
	if bg_tex:
		_bg_style = StyleBoxTexture.new()
		_bg_style.texture = bg_tex
	if fill_tex:
		_fill_style = StyleBoxTexture.new()
		_fill_style.texture = fill_tex
	_styles_applied = false


func _create_bar_labels() -> void:
	if hp_bar:
		_hp_label = Label.new()
		_hp_label.name = "HPLabel"
		_style_bar_label(_hp_label, "生命")
		hp_bar.add_child(_hp_label)
	if mana_bar:
		_mana_label = Label.new()
		_mana_label.name = "ManaLabel"
		_style_bar_label(_mana_label, "真气")
		mana_bar.add_child(_mana_label)
	if sanity_bar:
		_sanity_label = Label.new()
		_sanity_label.name = "SanityLabel"
		_style_bar_label(_sanity_label, "神智")
		sanity_bar.add_child(_sanity_label)


func _style_bar_label(label: Label, prefix: String) -> void:
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 4.0
	label.offset_top = -1.0
	label.offset_right = -4.0
	label.offset_bottom = 1.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_font_size_override("font_size", 11)
	label.text = prefix
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_fallback_styles() -> void:
	if _fallback_applied:
		return
	_fallback_applied = true
	if _styles_applied:
		return
	var bars: Array[Dictionary] = [
		{"bar": stamina_bar, "color": Color(0.2, 0.75, 0.2, 0.9)},
		{"bar": hp_bar, "color": Color(0.85, 0.15, 0.15, 0.9)},
		{"bar": mana_bar, "color": Color(0.2, 0.4, 0.9, 0.9)},
		{"bar": sanity_bar, "color": Color(0.6, 0.2, 0.8, 0.9)},
	]
	for entry: Dictionary in bars:
		var bar: ProgressBar = entry["bar"]
		if bar == null:
			continue
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.12, 0.12, 0.12, 0.8)
		bg.set_border_width_all(1)
		bg.border_color = Color(0.4, 0.4, 0.4, 0.7)
		bg.set_corner_radius_all(3)
		var fill := StyleBoxFlat.new()
		fill.bg_color = entry["color"]
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)


func _update_display() -> void:
	_apply_fallback_styles()
	if stamina_bar:
		stamina_bar.max_value = PlayerData.max_stamina
		stamina_bar.value = PlayerData.current_stamina
		if not _styles_applied and _bg_style and _fill_style:
			stamina_bar.add_theme_stylebox_override("background", _bg_style)
			stamina_bar.add_theme_stylebox_override("fill", _fill_style)
			_styles_applied = true
	if hp_bar:
		hp_bar.max_value = PlayerData.max_hp
		hp_bar.value = PlayerData.current_hp
	if mana_bar:
		mana_bar.max_value = PlayerData.max_mana
		mana_bar.value = PlayerData.current_mana
	if sanity_bar:
		sanity_bar.max_value = PlayerData.max_sanity
		sanity_bar.value = PlayerData.current_sanity
	if stamina_label:
		stamina_label.text = "体力 %d/%d" % [PlayerData.current_stamina, PlayerData.max_stamina]
		stamina_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		stamina_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		stamina_label.add_theme_constant_override("outline_size", 2)
	if _hp_label:
		_hp_label.text = "生命 %d/%d" % [PlayerData.current_hp, PlayerData.max_hp]
	if _mana_label:
		_mana_label.text = "真气 %d/%d" % [PlayerData.current_mana, PlayerData.max_mana]
	if _sanity_label:
		_sanity_label.text = "神智 %d/%d" % [PlayerData.current_sanity, PlayerData.max_sanity]
