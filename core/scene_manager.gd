extends Node

var _current_scene_path: String = ""
var _pending_scene: String = ""
var _pending_spawn: StringName = &""
var _is_transitioning: bool = false

## Cache scene data (e.g. farm tiles) so it persists across scene transitions
## without requiring a full save/load cycle.  Key = scene path, Value = dictionary.
var _scene_data_cache: Dictionary = {}


func _ready() -> void:
	EventBus.scene_change_requested.connect(_on_scene_change_requested)


func _on_scene_change_requested(scene_path: String, spawn_point: StringName = &"") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_pending_scene = scene_path
	_pending_spawn = spawn_point

	# Cache current scene data before leaving so it can be restored later.
	# Skip if the cache already holds data for this path (e.g. pre-populated
	# by GameManager.load_game with save-file data that must take precedence).
	var current_scene: Node = get_tree().current_scene
	print("SceneManager: Current scene is: ", current_scene)
	if current_scene and current_scene.has_method("get_save_data"):
		if not _current_scene_path.is_empty():
			var save_data = current_scene.get_save_data()
			print("SceneManager: Caching scene data for ", _current_scene_path, ": ", save_data)
			_scene_data_cache[_current_scene_path] = save_data

	EventBus.screen_transition_started.emit()

	if GameUI and GameUI.fade_rect:
		await GameUI.fade_in(0.4)
	else:
		await get_tree().create_timer(0.5).timeout

	PlayerData.current_scene = scene_path
	PlayerData.player_position = Vector2.ZERO
	get_tree().change_scene_to_file(scene_path)
	_current_scene_path = scene_path

	await get_tree().tree_changed

	# Restore cached scene data if the new scene supports it
	var new_scene: Node = get_tree().current_scene
	print("SceneManager: New scene is: ", new_scene)
	if new_scene and new_scene.has_method("load_save_data"):
		if _scene_data_cache.has(scene_path):
			var cached_data = _scene_data_cache[scene_path]
			print("SceneManager: Restoring scene data for ", scene_path, ": ", cached_data)
			new_scene.load_save_data(cached_data)
		else:
			print("SceneManager: No cached data found for ", scene_path)

	_position_player_at_spawn()

	# Ensure all inventory UIs refresh after a scene transition
	EventBus.inventory_changed.emit()

	EventBus.screen_transition_finished.emit()
	_is_transitioning = false


func _position_player_at_spawn() -> void:
	if _pending_spawn == &"":
		return
	var player_nodes: Array[Node] = get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		return
	var player: Node2D = player_nodes[0] as Node2D
	if player == null:
		return
	var root: Node = get_tree().current_scene
	if root:
		var marker: Node2D = _find_spawn_marker(root, _pending_spawn)
		if marker:
			player.global_position = marker.global_position


func _find_spawn_marker(node: Node, marker_name: StringName) -> Node2D:
	if node is Marker2D and node.name == marker_name:
		return node as Marker2D
	for child: Node in node.get_children():
		var found: Node2D = _find_spawn_marker(child, marker_name)
		if found:
			return found
	return null


func get_current_scene_path() -> String:
	return _current_scene_path


func go_to_main_menu() -> void:
	_is_transitioning = true
	# Cache current scene data before leaving
	var current_scene: Node = get_tree().current_scene
	if current_scene and current_scene.has_method("get_save_data"):
		_scene_data_cache[_current_scene_path] = current_scene.get_save_data()
	TimeManager.game_started = false
	if GameUI:
		GameUI.hide_game_ui()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
	_current_scene_path = ""
	_is_transitioning = false


func clear_scene_cache() -> void:
	_scene_data_cache.clear()


## Pre-populate the cache for a specific scene path.
## Used by GameManager.load_game() so that save-file data is applied
## when the scene transition completes, instead of requiring a manual
## load_save_data() call that races with the async transition.
func preload_scene_cache(scene_path: String, data: Dictionary) -> void:
	print("SceneManager: Preloading scene cache for ", scene_path, ": ", data)
	_scene_data_cache[scene_path] = data
