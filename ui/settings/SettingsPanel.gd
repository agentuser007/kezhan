extends Control

signal close_requested

const SETTINGS_PATH: String = "user://settings.cfg"

@onready var master_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MasterSlider
@onready var music_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SFXSlider
@onready var resolution_option: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/ResolutionOption
@onready var fullscreen_check: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/FullscreenCheck
@onready var text_speed_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/TextSpeedSlider
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

var _resolutions: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1366, 768),
	Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1440), Vector2i(3840, 2160),
]


func _ready() -> void:
	_load_settings()
	if master_slider:
		master_slider.value_changed.connect(_on_master_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if resolution_option:
		_populate_resolutions()
		resolution_option.item_selected.connect(_on_resolution_selected)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if text_speed_slider:
		text_speed_slider.value_changed.connect(_on_text_speed_changed)
	if back_button:
		back_button.pressed.connect(_on_back)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		if master_slider:
			master_slider.value = 0.0
		if music_slider:
			music_slider.value = 0.0
		if sfx_slider:
			sfx_slider.value = 0.0
		if text_speed_slider:
			text_speed_slider.value = 3.0
		return
	if master_slider:
		master_slider.value = config.get_value("audio", "master", 0.0)
	if music_slider:
		music_slider.value = config.get_value("audio", "music", 0.0)
	if sfx_slider:
		sfx_slider.value = config.get_value("audio", "sfx", 0.0)
	if text_speed_slider:
		text_speed_slider.value = config.get_value("gameplay", "text_speed", 3.0)
	if fullscreen_check:
		fullscreen_check.button_pressed = config.get_value("display", "fullscreen", false)
	if resolution_option:
		var res_idx: int = config.get_value("display", "resolution_index", 1)
		resolution_option.selected = res_idx


func _save_settings() -> void:
	var config := ConfigFile.new()
	if master_slider:
		config.set_value("audio", "master", master_slider.value)
	if music_slider:
		config.set_value("audio", "music", music_slider.value)
	if sfx_slider:
		config.set_value("audio", "sfx", sfx_slider.value)
	if text_speed_slider:
		config.set_value("gameplay", "text_speed", text_speed_slider.value)
	if fullscreen_check:
		config.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	if resolution_option:
		config.set_value("display", "resolution_index", resolution_option.selected)
	config.save(SETTINGS_PATH)


func _on_master_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)
	_save_settings()


func _on_music_changed(value: float) -> void:
	if AudioServer.bus_count > 1:
		AudioServer.set_bus_volume_db(1, value)
	_save_settings()


func _on_sfx_changed(value: float) -> void:
	if AudioServer.bus_count > 2:
		AudioServer.set_bus_volume_db(2, value)
	_save_settings()


func _on_text_speed_changed(value: float) -> void:
	_save_settings()


func get_text_speed() -> float:
	if text_speed_slider:
		return text_speed_slider.value
	return 3.0


func _populate_resolutions() -> void:
	if resolution_option == null:
		return
	for res: Vector2i in _resolutions:
		resolution_option.add_item("%dx%d" % [res.x, res.y])


func _on_resolution_selected(index: int) -> void:
	if index < _resolutions.size():
		var res: Vector2i = _resolutions[index]
		get_viewport().set_deferred("size", res)
	_save_settings()


func _on_fullscreen_toggled(is_on: bool) -> void:
	if is_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func _on_back() -> void:
	close_requested.emit()
	if get_parent() and not get_parent().has_method("new_game"):
		GameUI.close_panel()
	else:
		visible = false
