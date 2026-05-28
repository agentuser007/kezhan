class_name SceneTransitionZone
extends Area2D

@export var target_scene: String = ""
@export var spawn_point_name: StringName = &""
@export var transition_direction: Vector2 = Vector2.ZERO

var _is_player_inside: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		_is_player_inside = true
		if target_scene != "":
			EventBus.scene_change_requested.emit(target_scene, spawn_point_name)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		_is_player_inside = false
