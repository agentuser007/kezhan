class_name BedInteractable
extends Interactable


func _ready() -> void:
	super._ready()
	interaction_name = "睡觉"
	interaction_hint = "[空格] 睡觉"


func interact() -> void:
	super.interact()
	if TimeManager.is_sleeping:
		return
	_show_sleep_confirm()


func _show_sleep_confirm() -> void:
	EventBus.player_interacted.emit(self)
	var dialog: Control = GameUI.get_panel(&"SleepConfirmDialog")
	if dialog:
		GameUI.open_panel(dialog)
	else:
		TimeManager.start_sleep()
