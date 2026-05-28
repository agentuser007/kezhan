extends Control

signal dialogue_finished

@onready var bg_panel: PanelContainer = $BgPanel
@onready var name_label: Label = $BgPanel/MarginContainer/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $BgPanel/MarginContainer/VBoxContainer/TextLabel
@onready var continue_hint: Label = $BgPanel/MarginContainer/VBoxContainer/ContinueHint

var _is_active: bool = false
var _can_advance: bool = false
var _is_typing: bool = false
var _pages: PackedStringArray = []
var _current_page: int = 0
var _char_index: int = 0
var _full_text: String = ""
var _type_timer: float = 0.0
var _type_speed: float = 0.03


func _ready() -> void:
	visible = false
	if continue_hint:
		continue_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		continue_hint.add_theme_font_size_override("font_size", 12)
		continue_hint.text = ""


func _process(delta: float) -> void:
	if not _is_typing:
		return
	var settings: Control = GameUI.get_panel(&"SettingsPanel") if GameUI else null
	var speed_mult: float = 1.0
	if settings and settings.has_method("get_text_speed"):
		speed_mult = settings.get_text_speed() / 3.0
	_type_timer += delta
	while _type_timer >= _type_speed / speed_mult and _char_index < _full_text.length():
		_type_timer -= _type_speed / speed_mult
		_char_index += 1
		if text_label:
			text_label.visible_characters = _char_index
	if _char_index >= _full_text.length():
		_is_typing = false
		_show_advance_hint()


func show_dialogue(speaker_name: String, text: String) -> void:
	_pages = text.split("|PAGE|")
	if _pages.is_empty():
		_pages = [text]
	_current_page = 0
	_is_active = true
	_can_advance = false
	if name_label:
		name_label.text = speaker_name if speaker_name != "" else "???"
	_show_page(_current_page)
	visible = true


func _show_page(page_index: int) -> void:
	if page_index < 0 or page_index >= _pages.size():
		return
	_full_text = _pages[page_index]
	_char_index = 0
	_is_typing = true
	_type_timer = 0.0
	if text_label:
		text_label.text = _full_text
		text_label.visible_characters = 0
	if continue_hint:
		continue_hint.text = ""


func _show_advance_hint() -> void:
	if continue_hint == null:
		return
	if _current_page < _pages.size() - 1:
		continue_hint.text = "点击继续"
	else:
		continue_hint.text = "点击关闭"


func _advance() -> void:
	if _is_typing:
		_is_typing = false
		_char_index = _full_text.length()
		if text_label:
			text_label.visible_characters = -1
		_show_advance_hint()
		return
	_current_page += 1
	if _current_page >= _pages.size():
		hide_dialogue()
	else:
		_can_advance = false
		_show_page(_current_page)


func hide_dialogue() -> void:
	_is_active = false
	_can_advance = false
	_is_typing = false
	_pages.clear()
	_current_page = 0
	visible = false
	dialogue_finished.emit()


func _gui_input(event: InputEvent) -> void:
	if not _is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		_advance()
		accept_event()
		_can_advance = true
	if event.is_action_pressed("interact"):
		_advance()
		accept_event()
		_can_advance = true
