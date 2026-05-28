extends CharacterBody2D

@export var move_speed: float = 160.0
@export var acceleration: float = 800.0
@export var friction: float = 600.0
@export var interaction_radius: float = 48.0
@export var charge_threshold: float = 0.48

var input_direction: Vector2 = Vector2.ZERO
var is_mouse_dragging: bool = false
var is_interacting: bool = false
var is_action_locked: bool = false

var _tool_hold_time: float = 0.0
var _is_holding_tool: bool = false

var current_highlighted: Interactable = null
var _nearby_interactables: Array[Interactable] = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_collision: CollisionShape2D = $InteractionArea/CollisionShape2D


func _ready() -> void:
	add_to_group("player")
	interaction_area.collision_layer = 0
	interaction_area.collision_mask = 4
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	if interaction_collision:
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = interaction_radius
		interaction_collision.shape = shape
	EventBus.hotbar_selection_changed.connect(_on_hotbar_changed)
	_load_sprite_frames()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("use_tool"):
		_on_tool_pressed()
	if event.is_action_released("use_tool"):
		_on_tool_released()
	if event.is_action_pressed("left_click"):
		if not is_mouse_dragging:
			_try_click_interact(event)
			_try_click_farm(event)
	if event.is_action_released("left_click"):
		is_mouse_dragging = false


func _physics_process(delta: float) -> void:
	if is_action_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _is_holding_tool:
		_tool_hold_time += delta

	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if Input.is_action_pressed("left_click"):
		var mouse_pos: Vector2 = get_global_mouse_position()
		var dir_to_mouse: Vector2 = (mouse_pos - global_position).normalized()
		if dir_to_mouse.length() > 0.1:
			is_mouse_dragging = true
			input_direction = dir_to_mouse

	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * move_speed, acceleration * delta)
		PlayerData.facing_direction = input_direction.normalized()
		_update_animation(input_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		_play_idle_animation()

	move_and_slide()
	_update_highlight()


func _update_animation(dir: Vector2) -> void:
	if sprite == null:
		return
	var anim_name: String = "walk_"
	if absf(dir.x) > absf(dir.y):
		if dir.x > 0:
			sprite.flip_h = true
			anim_name += "left"
		else:
			sprite.flip_h = false
			anim_name += "left"
	else:
		sprite.flip_h = false
		anim_name += "down" if dir.y > 0 else "up"
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


func _play_idle_animation() -> void:
	if sprite == null:
		return
	var anim_name: String = "idle_"
	var dir: Vector2 = PlayerData.facing_direction
	if absf(dir.x) > absf(dir.y):
		if dir.x > 0:
			sprite.flip_h = true
			anim_name += "left"
		else:
			sprite.flip_h = false
			anim_name += "left"
	else:
		sprite.flip_h = false
		anim_name += "down" if dir.y > 0 else "up"
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


func _update_highlight() -> void:
	if _nearby_interactables.is_empty():
		if current_highlighted != null:
			current_highlighted.unhighlight()
			current_highlighted = null
			EventBus.interaction_highlight_changed.emit(null)
		return

	var closest: Interactable = null
	var closest_dist: float = INF
	for interactable: Interactable in _nearby_interactables:
		if not is_instance_valid(interactable):
			continue
		var dist: float = global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = interactable

	if closest != current_highlighted:
		if current_highlighted != null:
			current_highlighted.unhighlight()
		current_highlighted = closest
		if current_highlighted != null:
			current_highlighted.highlight()
		EventBus.interaction_highlight_changed.emit(current_highlighted)


func _try_interact() -> void:
	if current_highlighted != null and is_instance_valid(current_highlighted):
		is_interacting = true
		current_highlighted.interact()
		is_interacting = false


func _try_click_interact(event: InputEvent) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collision_mask = 4
	var results: Array[Dictionary] = space_state.intersect_point(query)
	for result: Dictionary in results:
		var collider: CollisionObject2D = result.get("collider", null) as CollisionObject2D
		if collider is Interactable:
			var interactable: Interactable = collider as Interactable
			if _nearby_interactables.has(interactable):
				interactable.interact()
				return


func _on_interaction_area_entered(area: Area2D) -> void:
	if area is Interactable:
		_nearby_interactables.append(area as Interactable)


func _on_interaction_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_nearby_interactables.erase(area as Interactable)
		if area == current_highlighted:
			current_highlighted.unhighlight()
			current_highlighted = null


func _on_hotbar_changed(_slot: int) -> void:
	pass


func _get_facing_cell() -> Vector2i:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return Vector2i.MIN
	var tile_size: int = world_map.tile_size
	var target_pos: Vector2 = global_position + PlayerData.facing_direction * tile_size
	return world_map.dirt_layer.local_to_map(target_pos)


func _get_player_cell() -> Vector2i:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return Vector2i.MIN
	return world_map.dirt_layer.local_to_map(global_position)


func _get_cell_at_mouse(mouse_pos: Vector2) -> Vector2i:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return Vector2i.MIN
	return world_map.dirt_layer.local_to_map(mouse_pos)


func _get_world_map() -> Node2D:
	var current_scene: Node = get_tree().current_scene
	if current_scene and current_scene.has_node("DirtLayer"):
		return current_scene
	return null


func _on_tool_pressed() -> void:
	var item_id: StringName = InventoryManager.get_selected_item_id()
	if item_id == &"":
		return
	match item_id:
		&"WateringCan", &"Sickle":
			_is_holding_tool = true
			_tool_hold_time = 0.0
		&"Hoe":
			_execute_hoe_action()
		&"Axe":
			_execute_axe_action()
		&"Hammer":
			_execute_hammer_action()
		_:
			var info: Dictionary = InventoryManager.get_item_info(item_id)
			if info.get("category", &"") == &"种子":
				_execute_seed_spread_action(item_id)
			else:
				_execute_farm_action(_get_facing_cell())


func _on_tool_released() -> void:
	if not _is_holding_tool:
		return
	_is_holding_tool = false
	var is_charged: bool = _tool_hold_time >= charge_threshold
	_tool_hold_time = 0.0
	var item_id: StringName = InventoryManager.get_selected_item_id()
	match item_id:
		&"WateringCan":
			if is_charged:
				_execute_water_circle_action()
			else:
				_execute_farm_action(_get_facing_cell())
		&"Sickle":
			if is_charged:
				_execute_sickle_circle_action()
			else:
				_execute_farm_action(_get_facing_cell())


func _try_click_farm(_event: InputEvent) -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dist: float = global_position.distance_to(mouse_pos)
	if dist > interaction_radius * 2.0:
		return
	var cell: Vector2i = _get_cell_at_mouse(mouse_pos)
	if cell == Vector2i.MIN:
		return
	var tile: FarmTileData = world_map.get_tile_at(cell)
	if tile == null and not world_map.has_junk_at(cell):
		return
	_execute_farm_action(cell)


func _execute_farm_action(cell: Vector2i) -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	var item_id: StringName = InventoryManager.get_selected_item_id()
	if item_id == &"":
		return

	var success: bool = false
	var anim_suffix: String = _get_facing_anim_suffix()

	match item_id:
		&"Hoe":
			success = world_map.till_tile(cell)
			if success:
				_play_tool_anim("hoe", anim_suffix)
				AudioManager.play_sfx(&"hoe")
		&"WateringCan":
			success = world_map.water_tile(cell)
			if success:
				_play_tool_anim("water", anim_suffix)
				AudioManager.play_sfx(&"watering")
		&"Sickle":
			success = world_map.harvest_tile(cell)
			if success:
				_play_tool_anim("sickle", anim_suffix)
				AudioManager.play_sfx(&"harvest")
			else:
				success = world_map.clear_weeds_at(cell)
				if success:
					_play_tool_anim("sickle", anim_suffix)
					AudioManager.play_sfx(&"sickle")
				else:
					success = world_map.clear_junk_weeds_at(cell)
					if success:
						_play_tool_anim("sickle", anim_suffix)
						AudioManager.play_sfx(&"sickle")
		&"Fertilizer":
			success = world_map.fertilize_tile(cell)
			if success:
				AudioManager.play_sfx(&"seeds")
		&"WeedingSickle":
			success = world_map.clear_weeds_at(cell)
			if success:
				AudioManager.play_sfx(&"sickle")
		&"PestRemedy":
			success = world_map.clear_pests_at(cell)
		&"Axe":
			success = world_map.chop_wood_at(cell)
			if success:
				_play_tool_anim("axe", anim_suffix)
				AudioManager.play_sfx(&"axe")
		&"Hammer":
			success = world_map.smash_stone_at(cell)
			if not success:
				success = world_map.until_tile(cell)
			if success:
				_play_tool_anim("hammer", anim_suffix)
				AudioManager.play_sfx(&"hammer")
		_:
			var info: Dictionary = InventoryManager.get_item_info(item_id)
			if info.get("category", &"") == &"种子":
				success = world_map.plant_tile(cell, item_id)
				if success:
					_play_tool_anim("seeds", "")
					AudioManager.play_sfx(&"seeds")

	if success:
		EventBus.farm_tile_state_changed.emit(cell, 0)
		EventBus.notification_requested.emit(_action_feedback_text(item_id))
	elif (
		(
			item_id
			in [
				&"Hoe",
				&"WateringCan",
				&"Sickle",
				&"Fertilizer",
				&"WeedingSickle",
				&"PestRemedy",
				&"Axe",
				&"Hammer"
			]
		)
		or InventoryManager.get_item_info(item_id).get("category", &"") == &"种子"
	):
		EventBus.notification_requested.emit("操作失败")


func _execute_hoe_action() -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	var facing_cell: Vector2i = _get_facing_cell()
	var cells: Array[Vector2i] = world_map.get_hoe_cells(facing_cell)
	var count: int = world_map.till_tiles(cells)
	if count > 0:
		_play_tool_anim("hoe", _get_facing_anim_suffix())
		AudioManager.play_sfx(&"hoe")
		EventBus.notification_requested.emit("耕地完成 ×%d" % count)
	else:
		EventBus.notification_requested.emit("无法耕地")


func _execute_seed_spread_action(seed_id: StringName) -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	if not InventoryManager.has_item(seed_id, 1):
		return
	var player_cell: Vector2i = _get_player_cell()
	var count: int = world_map.plant_tiles_around(player_cell, seed_id)
	if count > 0:
		_play_tool_anim("seeds", "")
		AudioManager.play_sfx(&"seeds")
		EventBus.notification_requested.emit("播种完成 ×%d" % count)
	else:
		EventBus.notification_requested.emit("无法播种")


func _execute_water_circle_action() -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	var facing_cell: Vector2i = _get_facing_cell()
	var cells: Array[Vector2i] = world_map.get_circle_cells(facing_cell)
	var count: int = world_map.water_tiles(cells)
	if count > 0:
		_play_tool_anim("water", _get_facing_anim_suffix())
		AudioManager.play_sfx(&"watering")
		EventBus.notification_requested.emit("浇水完成 ×%d" % count)
	else:
		EventBus.notification_requested.emit("无法浇水")


func _execute_sickle_circle_action() -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	var facing_cell: Vector2i = _get_facing_cell()
	var cells: Array[Vector2i] = world_map.get_circle_cells(facing_cell)
	var weed_count: int = world_map.clear_weeds_in_cells(cells)
	var junk_count: int = world_map.clear_junk_weeds_in_cells(cells)
	var total: int = weed_count + junk_count
	if total > 0:
		_play_tool_anim("sickle", _get_facing_anim_suffix())
		AudioManager.play_sfx(&"sickle")
		EventBus.notification_requested.emit("除草完成 ×%d" % total)
	else:
		EventBus.notification_requested.emit("周围没有杂草")


func _execute_axe_action() -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	var cell: Vector2i = _get_facing_cell()
	if world_map.chop_wood_at(cell):
		_play_tool_anim("axe", _get_facing_anim_suffix())
		AudioManager.play_sfx(&"axe")
		EventBus.notification_requested.emit("砍伐完成 - 柴火×2")
	else:
		EventBus.notification_requested.emit("无法砍伐")


func _execute_hammer_action() -> void:
	var world_map: Node2D = _get_world_map()
	if world_map == null:
		return
	var cell: Vector2i = _get_facing_cell()
	if world_map.smash_stone_at(cell):
		_play_tool_anim("hammer", _get_facing_anim_suffix())
		AudioManager.play_sfx(&"hammer")
		EventBus.notification_requested.emit("碎石完成 - 石头")
	elif world_map.until_tile(cell):
		_play_tool_anim("hammer", _get_facing_anim_suffix())
		AudioManager.play_sfx(&"hammer")
		EventBus.notification_requested.emit("反耕完成")
	else:
		EventBus.notification_requested.emit("无法使用锤子")


func _get_facing_anim_suffix() -> String:
	var dir: Vector2 = PlayerData.facing_direction
	if absf(dir.x) > absf(dir.y):
		return "left"
	return "down" if dir.y > 0 else "up"


func _play_tool_anim(tool_name: String, suffix: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim_name: String = tool_name + "_" + suffix
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	elif tool_name == "seeds" and sprite.sprite_frames.has_animation("seeds"):
		sprite.play("seeds")


func _action_feedback_text(item_id: StringName) -> String:
	var feedback: Dictionary = {
		&"Hoe": "耕地完成",
		&"WateringCan": "浇水完成",
		&"Sickle": "收获完成",
		&"Fertilizer": "施肥完成",
		&"WeedingSickle": "除草完成",
		&"PestRemedy": "除虫完成",
		&"Axe": "砍伐完成",
		&"Hammer": "锤击完成",
	}
	if feedback.has(item_id):
		return feedback[item_id]
	var info: Dictionary = InventoryManager.get_item_info(item_id)
	if info.get("category", &"") == &"种子":
		return "播种完成 - " + str(info.get("name", ""))
	return "操作完成"


func _load_sprite_frames() -> void:
	if sprite == null:
		return
	var path: String = "res://resources/player_sprite_frames.tres"
	var sf: SpriteFrames = null
	if ResourceLoader.exists(path):
		sf = load(path) as SpriteFrames
	if sf == null:
		sf = _build_sprite_frames()
	if sf != null:
		sprite.sprite_frames = sf
		if sf.has_animation("idle_down"):
			sprite.play("idle_down")


func _build_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var A := "res://player/animations/"
	var _idle := A + "idle/"
	var _walk := A + "walking/"
	var _axe := A + "axe/"
	var _hoe := A + "hoe/"
	var _hammer := A + "hammer/"
	var _sickle := A + "sickle/"
	var _water := A + "watering/"
	var _hold := A + "hold/"
	var _bag := A + "bag/"
	var _seeds := A + "seeds/"
	var _pass := A + "passingOut/"

	_ba(sf, "idle_down", true, 5.0, [_idle + "Idle Down.png"])
	_ba(sf, "idle_up", true, 5.0, [_idle + "Idle Up.png"])
	_ba(sf, "idle_left", true, 5.0, [_idle + "Idle Left.png"])
	_ba(sf, "walk_down", true, 5.0, [_walk + "Down4.png", _walk + "Down5.png"])
	_ba(sf, "walk_up", true, 5.0, [_walk + "Up1.png", _walk + "Up2.png"])
	_ba(sf, "walk_left", true, 5.0, [_walk + "left1.png", _walk + "left2.png"])
	_ba(sf, "axe_down", false, 12.5, _sq(_axe, "axeDown", 1, 12) + [_idle + "Idle Down.png"])
	_ba(sf, "axe_up", false, 12.5, _sq(_axe, "axeUp", 1, 12) + [_idle + "Idle Up.png"])
	_ba(sf, "axe_left", false, 12.5, _sq(_axe, "axeLeft", 1, 12) + [_idle + "Idle Left.png"])
	_ba(sf, "hoe_down", false, 12.5, _sq(_hoe, "hoeDown", 1, 11) + [_idle + "Idle Down.png"])
	_ba(sf, "hoe_up", false, 12.5, _sq(_hoe, "hoeUp", 1, 11) + [_idle + "Idle Up.png"])
	_ba(sf, "hoe_left", false, 12.5, _sq(_hoe, "hoeLeft", 1, 11) + [_idle + "Idle Left.png"])
	_ba(
		sf,
		"hammer_down",
		false,
		12.5,
		_sq(_hammer, "hammerDown", 1, 12) + [_idle + "Idle Down.png"]
	)
	_ba(sf, "hammer_up", false, 12.5, _sq(_hammer, "hammerUp", 1, 12) + [_idle + "Idle Up.png"])
	_ba(
		sf,
		"hammer_left",
		false,
		12.5,
		_sq(_hammer, "hammerLeft", 1, 12) + [_idle + "Idle Left.png"]
	)
	_ba(
		sf,
		"sickle_down",
		false,
		12.5,
		_sq(_sickle, "sickleDown", 1, 11) + [_idle + "Idle Down.png"]
	)
	_ba(sf, "sickle_up", false, 12.5, _sq(_sickle, "sickleUp", 1, 11) + [_idle + "Idle Up.png"])
	_ba(
		sf,
		"sickle_left",
		false,
		12.5,
		_sq(_sickle, "sickleLeft", 1, 11) + [_idle + "Idle Left.png"]
	)
	_ba(sf, "hold_idle_down", true, 5.0, [_hold + "holdDownIdle.png"])
	_ba(sf, "hold_idle_up", true, 5.0, [_hold + "holdUpIdle.png"])
	_ba(sf, "hold_idle_left", true, 5.0, [_hold + "holdLeftIdle.png"])
	_ba(sf, "hold_walk_down", true, 5.0, [_hold + "holdDownWalk1.png", _hold + "holdDownWalk2.png"])
	_ba(sf, "hold_walk_up", true, 5.0, [_hold + "holdUpWalk1.png", _hold + "holdUpWalk2.png"])
	_ba(sf, "hold_walk_left", true, 5.0, [_hold + "holdLeftWalk1.png", _hold + "holdLeftWalk2.png"])
	_ba(
		sf,
		"pass_out",
		false,
		2.5,
		(
			_sq(_pass, "passOut", 1, 11)
			+ [
				_pass + "passOut11.png",
				_pass + "passOut11.png",
				_pass + "passOut11.png",
				_pass + "passOut11.png",
				_pass + "passOut11.png"
			]
		)
	)

	ResourceSaver.save(sf, "res://resources/player_sprite_frames.tres")
	return sf


func _ba(sf: SpriteFrames, name: String, loop: bool, speed: float, frame_paths: Array) -> void:
	sf.add_animation(name)
	sf.set_animation_loop(name, loop)
	sf.set_animation_speed(name, speed)
	for path: String in frame_paths:
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			sf.add_frame(name, tex)


func _sq(base: String, pattern: String, start: int, end: int) -> Array:
	var result: Array = []
	for i: int in range(start, end + 1):
		result.append(base + pattern + str(i) + ".png")
	return result
