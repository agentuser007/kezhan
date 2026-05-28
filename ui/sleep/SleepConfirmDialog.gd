extends Control

@onready var rest_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RestButton
@onready var cancel_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var prompt_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PromptLabel


func _ready() -> void:
	if rest_button:
		rest_button.pressed.connect(_on_rest)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel)


func _on_rest() -> void:
	GameUI.close_panel()
	TimeManager.start_sleep()


func _on_cancel() -> void:
	GameUI.close_panel()


func show_sleep_prompt() -> void:
	if prompt_label == null:
		return
	var hour: int = TimeManager.current_hour
	var stamina_pct: float = float(PlayerData.current_stamina) / float(maxi(PlayerData.max_stamina, 1))
	var hint: String = ""
	if hour >= 21:
		hint = "夜已深，宜早休息。"
	elif stamina_pct < 0.3:
		hint = "体力已近枯竭，建议休息恢复。"
	elif PlayerData.current_hp < PlayerData.max_hp / 2:
		hint = "伤势较重，休息可回复生命。"
	else:
		hint = "是否休息至次日清晨？"
	prompt_label.text = hint
