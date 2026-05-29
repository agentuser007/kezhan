extends Node2D

var astar: AStarGrid2D = null
const CELL_SIZE: int = 16
var spawn_timer: float = 6.0 # First guest spawns after 6 seconds

func _ready() -> void:
	_init_astar()
	TavernManager.register_seat($Seat1)
	TavernManager.register_seat($Seat2)
	print("InnInterior: Registered seats in TavernManager.")


func _exit_tree() -> void:
	TavernManager.unregister_seat($Seat1)
	TavernManager.unregister_seat($Seat2)
	print("InnInterior: Unregistered seats in TavernManager.")


func _process(delta: float) -> void:
	if astar == null:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(12.0, 18.0) # Spawn every 12 to 18 seconds
		spawn_guest()


func spawn_guest() -> void:
	var open_seat = TavernManager.get_random_open_seat()
	if open_seat == null:
		print("InnInterior: No open seats, skipping guest spawn.")
		return
		
	var guest = Area2D.new()
	guest.set_script(load("res://scenes/inn/guest_controller.gd"))
	
	# Warm brown ColorRect for guest representation
	var bg_rect = ColorRect.new()
	bg_rect.name = "Visuals"
	bg_rect.custom_minimum_size = Vector2(24, 24)
	bg_rect.position = Vector2(-12, -12)
	bg_rect.color = Color(0.85, 0.45, 0.25)
	
	var border = ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(0.1, 0.1, 0.1)
	border.editor_only = false
	bg_rect.add_child(border)
	
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.text = "客"
	bg_rect.add_child(label)
	
	guest.add_child(bg_rect)
	
	# CollisionShape2D for interaction Area2D
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	col.shape = shape
	guest.add_child(col)
	
	var entrance = get_node_or_null("inn_entrance")
	guest.position = entrance.position if entrance else Vector2(200, 280)
	
	add_child(guest)
	print("InnInterior: Spawned new guest NPC.")


func _init_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, 85, 48) # Covers screen bounds at 16px cell size
	astar.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	# Mark static obstacles as solid (Stove, FermentationJar, MenuBoard)
	_mark_node_solid(get_node_or_null("Stove"), Vector2(60, 30))
	_mark_node_solid(get_node_or_null("FermentationJar"), Vector2(24, 40))
	_mark_node_solid(get_node_or_null("MenuBoard"), Vector2(30, 50))
	print("InnInterior: AStarGrid2D initialized.")


func _mark_node_solid(node: Node2D, size: Vector2) -> void:
	if node == null:
		return
	var pos = node.position - size / 2.0
	var start_cell = Vector2i(int(pos.x / CELL_SIZE), int(pos.y / CELL_SIZE))
	var end_cell = Vector2i(int((pos.x + size.x) / CELL_SIZE), int((pos.y + size.y) / CELL_SIZE))
	for x in range(start_cell.x, end_cell.x + 1):
		for y in range(start_cell.y, end_cell.y + 1):
			if astar.region.has_point(Vector2i(x, y)):
				astar.set_point_solid(Vector2i(x, y), true)


func get_grid_path(from: Vector2, to: Vector2) -> Array[Vector2]:
	if astar == null:
		return [from, to]
	var start_cell = Vector2i(int(from.x / CELL_SIZE), int(from.y / CELL_SIZE))
	var end_cell = Vector2i(int(to.x / CELL_SIZE), int(to.y / CELL_SIZE))
	
	# Temporarily make target walkable so A* can find path ending on it
	var was_solid = astar.is_point_solid(end_cell)
	if was_solid:
		astar.set_point_solid(end_cell, false)
		
	var path_cells = astar.get_id_path(start_cell, end_cell)
	
	if was_solid:
		astar.set_point_solid(end_cell, true)
		
	var world_path: Array[Vector2] = []
	for cell in path_cells:
		world_path.append(Vector2(cell.x * CELL_SIZE + CELL_SIZE/2.0, cell.y * CELL_SIZE + CELL_SIZE/2.0))
	return world_path


func get_save_data() -> Dictionary:
	var jars_data: Dictionary = {}
	for jar in get_tree().get_nodes_in_group("fermentation_jars"):
		jars_data[String(jar.jar_id)] = jar.get_save_data()
	
	var stoves_data: Dictionary = {}
	for stove in get_tree().get_nodes_in_group("cooking_stations"):
		stoves_data[String(stove.station_id)] = {
			"state": stove.current_state,
			"recipe_id": String(stove.current_recipe_id),
			"progress": stove.cooking_progress,
			"duration": stove.cooking_duration
		}
	
	return {
		"jars": jars_data,
		"stoves": stoves_data
	}


func load_save_data(data: Dictionary) -> void:
	var jars_data = data.get("jars", {})
	for jar in get_tree().get_nodes_in_group("fermentation_jars"):
		var key = String(jar.jar_id)
		if jars_data.has(key):
			jar.load_save_data(jars_data[key])
			
	var stoves_data = data.get("stoves", {})
	for stove in get_tree().get_nodes_in_group("cooking_stations"):
		var key = String(stove.station_id)
		if stoves_data.has(key):
			var sdata = stoves_data[key]
			stove.current_state = sdata.get("state", 0)
			stove.current_recipe_id = StringName(sdata.get("recipe_id", ""))
			stove.cooking_progress = sdata.get("progress", 0.0)
			stove.cooking_duration = sdata.get("duration", 30.0)
