class_name Interactable
extends Area2D

@export var interaction_name: String = ""
@export var interaction_hint: String = ""
@export var interact_priority: int = 0

signal interaction_started
signal interaction_finished

var is_highlighted: bool = false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0


func interact() -> void:
	EventBus.player_interacted.emit(self)


func highlight() -> void:
	is_highlighted = true


func unhighlight() -> void:
	is_highlighted = false


func get_interaction_text() -> String:
	if interaction_hint != "":
		return interaction_hint
	if interaction_name != "":
		return "[空格] %s" % interaction_name
	return "[空格] 交互"
