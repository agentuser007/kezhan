class_name PondInteractable
extends Interactable


func _ready() -> void:
	super._ready()
	interaction_name = "鱼塘"
	interaction_hint = "[空格] 鱼塘"


func interact() -> void:
	super.interact()
	if PlayerData.ranching_level < 3:
		EventBus.player_interacted.emit(self)
		print("鱼塘：需养殖等级3解锁")
		return
	_open_pond_ui()


func _open_pond_ui() -> void:
	EventBus.player_interacted.emit(self)
	print("鱼塘：养殖等级已满足，鱼塘系统待实现")
