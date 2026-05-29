class_name SeatInteractable
extends Interactable

var _is_seated: bool = false
var _seated_player: CharacterBody2D = null


func _ready() -> void:
	super._ready()
	interaction_name = "入座"
	interaction_hint = "[空格] 入座"


func interact() -> void:
	super.interact()
	if _is_seated:
		_stand_up()
	else:
		_sit_down()


func _sit_down() -> void:
	_is_seated = true
	interaction_name = "站起"
	interaction_hint = "[空格] 站起"
	_seated_player = get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if _seated_player:
		_seated_player.set_physics_process(false)
	EventBus.interaction_highlight_changed.emit(self)


func _stand_up() -> void:
	_is_seated = false
	interaction_name = "入座"
	interaction_hint = "[空格] 入座"
	if _seated_player and is_instance_valid(_seated_player):
		_seated_player.set_physics_process(true)
	_seated_player = null
	EventBus.interaction_highlight_changed.emit(self)


func force_stand_up() -> void:
	if _is_seated:
		_stand_up()


func is_player_seated() -> bool:
	return _is_seated

