class_name GuestNPC
extends Interactable

# GuestNPC handles seating, pathfinding, ordering, serving, and checkout.

enum GuestState { SPAWNED, WALKING_TO_SEAT, SEATED_WAITING, EATING, LEAVING }

var current_state: GuestState = GuestState.SPAWNED
var assigned_seat: Node2D = null
var ordered_recipe_id: StringName = &""
var ordered_recipe_name: String = ""
var ordered_item_id: StringName = &""

var travel_path: Array[Vector2] = []
var current_path_index: int = 0
var movement_speed: float = 80.0

var patience_timer: float = 40.0 # Time player has to serve the guest
var eating_timer: float = 3.0 # Eating time
var bubble_rect: ColorRect = null
var bubble_label: Label = null

func _ready() -> void:
	super._ready()
	add_to_group("guests")
	interaction_name = "招待顾客"
	interaction_hint = "[空格] 招待顾客"
	
	# Create order bubble UI
	_create_order_bubble()
	
	# Assign open seat
	assigned_seat = TavernManager.get_random_open_seat()
	if assigned_seat == null:
		# No open seats, leave immediately
		current_state = GuestState.LEAVING
		var entrance = get_tree().current_scene.get_node_or_null("inn_entrance")
		var exit_pos = entrance.position if entrance else Vector2(200, 280)
		_generate_path_to(exit_pos)
	else:
		TavernManager.set_seat_occupied(assigned_seat, self)
		current_state = GuestState.WALKING_TO_SEAT
		_generate_path_to(assigned_seat.position)


func _create_order_bubble() -> void:
	bubble_rect = ColorRect.new()
	bubble_rect.custom_minimum_size = Vector2(80, 26)
	bubble_rect.color = Color(0.15, 0.15, 0.15, 0.9)
	# Center anchor relative to GuestNPC Node2D position
	bubble_rect.position = Vector2(-40, -45)
	
	# Add a border outline
	var border = ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(0.9, 0.8, 0.4, 0.8)
	border.editor_only = false
	bubble_rect.add_child(border)

	bubble_label = Label.new()
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble_label.add_theme_font_size_override("font_size", 10)
	bubble_label.add_theme_color_override("font_color", Color(1, 1, 1))
	bubble_label.text = "..."
	bubble_rect.add_child(bubble_label)
	
	add_child(bubble_rect)
	bubble_rect.visible = false


func _generate_path_to(target_pos: Vector2) -> void:
	var root = get_tree().current_scene
	if root and root.has_method("get_grid_path"):
		travel_path = root.get_grid_path(position, target_pos)
	else:
		travel_path = [position, target_pos]
	current_path_index = 0


func _process(delta: float) -> void:
	match current_state:
		GuestState.WALKING_TO_SEAT:
			_move_along_path(delta, GuestState.SEATED_WAITING)
		GuestState.LEAVING:
			_move_along_path(delta, GuestState.SPAWNED)
			if current_state == GuestState.SPAWNED:
				_destroy_guest()
		GuestState.SEATED_WAITING:
			# Progress patience timer
			patience_timer -= delta
			_update_bubble_text()
			if patience_timer <= 0:
				_leave_angry()
		GuestState.EATING:
			eating_timer -= delta
			if eating_timer <= 0:
				_finish_eating()


func _move_along_path(delta: float, next_state: GuestState) -> void:
	if travel_path.is_empty() or current_path_index >= travel_path.size():
		current_state = next_state
		if current_state == GuestState.SEATED_WAITING:
			_choose_and_order()
		return
		
	var target = travel_path[current_path_index]
	var dir = (target - position).normalized()
	var dist = position.distance_to(target)
	var move_dist = movement_speed * delta
	
	if move_dist >= dist:
		position = target
		current_path_index += 1
	else:
		position += dir * move_dist


func _choose_and_order() -> void:
	var menu = TavernManager.get_todays_menu()
	if menu.is_empty():
		# Default fallback menu
		ordered_recipe_id = &"hongshaorou"
	else:
		ordered_recipe_id = menu[randi() % menu.size()]
		
	# Lookup recipe output item
	var recipe = InventoryManager.get_recipe(ordered_recipe_id)
	if not recipe.is_empty():
		ordered_recipe_name = recipe.get("name", "红烧肉")
		ordered_item_id = StringName(recipe.get("output_id", "DishHongshaorou"))
	else:
		ordered_recipe_name = "红烧肉"
		ordered_item_id = &"DishHongshaorou"
		
	bubble_rect.visible = true
	_update_bubble_text()


func _update_bubble_text() -> void:
	if bubble_label == null:
		return
	if current_state == GuestState.SEATED_WAITING:
		bubble_label.text = "想吃: %s\n(%ds)" % [ordered_recipe_name, int(patience_timer)]
	elif current_state == GuestState.EATING:
		bubble_label.text = "大口咀嚼中..."
	elif current_state == GuestState.LEAVING:
		bubble_label.text = "多谢款待!"


func interact() -> void:
	super.interact()
	if current_state != GuestState.SEATED_WAITING:
		return
		
	if GameUI:
		var serve_ui = GameUI.get_panel(&"ServeUI")
		if serve_ui:
			serve_ui.setup(self)
			GameUI.open_panel(serve_ui)


func _finish_eating() -> void:
	current_state = GuestState.LEAVING
	bubble_label.text = "多谢款待!"
	
	# Free the seat
	if assigned_seat:
		TavernManager.set_seat_empty(assigned_seat)
		
	var entrance = get_tree().current_scene.get_node_or_null("inn_entrance")
	var exit_pos = entrance.position if entrance else Vector2(200, 280)
	_generate_path_to(exit_pos)


func _leave_angry() -> void:
	current_state = GuestState.LEAVING
	bubble_label.text = "走人了! 太慢了!"
	TavernManager.add_reputation(-1.5)
	
	if assigned_seat:
		TavernManager.set_seat_empty(assigned_seat)
		
	var entrance = get_tree().current_scene.get_node_or_null("inn_entrance")
	var exit_pos = entrance.position if entrance else Vector2(200, 280)
	_generate_path_to(exit_pos)


func _destroy_guest() -> void:
	queue_free()
