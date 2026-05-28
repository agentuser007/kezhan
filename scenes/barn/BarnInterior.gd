class_name BarnInterior
extends Node2D

var animals: Array[AnimalBase] = []
var max_occupancy: float = 10.0
var current_occupancy: float = 0.0

@onready var feed_trough: Interactable = $FeedTrough
@onready var water_trough: Interactable = $WaterTrough
@onready var incubator: Interactable = $Incubator
@onready var control_box: Interactable = $ControlBox


func _ready() -> void:
	BarnData.is_barn_scene_active = true
	EventBus.new_day_started.connect(_on_new_day)
	EventBus.player_interacted.connect(_on_player_interacted)
	_sync_from_barn_data()


func add_animal(animal: AnimalBase) -> bool:
	var space: float = _get_space_cost(animal)
	if current_occupancy + space > max_occupancy:
		return false
	animals.append(animal)
	current_occupancy += space
	add_child(animal)
	return true


func remove_animal(animal: AnimalBase) -> void:
	animals.erase(animal)
	current_occupancy -= _get_space_cost(animal)
	remove_child(animal)
	animal.queue_free()


func _get_space_cost(animal: AnimalBase) -> float:
	if animal.is_baby:
		return 0.5
	return 1.0


func feed_all(feed_item: StringName) -> int:
	var total_fed: int = 0
	for animal: AnimalBase in animals:
		if animal.current_state != AnimalBase.AnimalState.DEAD:
			var needed: int = 1 if animal.is_baby else animal.daily_feed_cost
			if InventoryManager.has_item(feed_item, needed):
				InventoryManager.remove_item(feed_item, needed)
				animal.fed_today = true
				total_fed += 1
	return total_fed


func water_all() -> void:
	for animal: AnimalBase in animals:
		if animal.current_state != AnimalBase.AnimalState.DEAD:
			animal.water()


func collect_all_products() -> Dictionary:
	var collected: Dictionary = {}
	for animal: AnimalBase in animals:
		if animal.products_ready > 0:
			var amount: int = animal.collect_products()
			var item_id: StringName = animal.product_item_id
			if collected.has(item_id):
				collected[item_id] += amount
			else:
				collected[item_id] = amount
	return collected


func _on_new_day(_day: int) -> void:
	current_occupancy = 0.0
	for animal: AnimalBase in animals:
		current_occupancy += _get_space_cost(animal)
	_remove_dead_animals()
	# Sync updated animal data back to BarnData
	_sync_to_barn_data()


func _remove_dead_animals() -> void:
	var to_remove: Array[AnimalBase] = []
	for animal: AnimalBase in animals:
		if animal.current_state == AnimalBase.AnimalState.DEAD:
			to_remove.append(animal)
	for animal: AnimalBase in to_remove:
		remove_animal(animal)


func _on_player_interacted(target: Interactable) -> void:
	if target == feed_trough:
		var feed_type: StringName = _get_feed_type_for_animals()
		feed_all(feed_type)
	elif target == water_trough:
		water_all()
	elif target == control_box:
		# Open Barn Management UI panel (with unlock check)
		if not UnlockManager.check_and_warn(&"barn_manage"):
			return
		var panel: Control = GameUI.get_panel("BarnManagementUI")
		if panel and panel.has_method("setup"):
			panel.setup(self)
			GameUI.open_panel(panel)


func _get_feed_type_for_animals() -> StringName:
	for animal: AnimalBase in animals:
		return animal.feed_item_id
	return &"PoultryFeed"


func _quick_feed_and_collect() -> void:
	var feed_type: StringName = _get_feed_type_for_animals()
	feed_all(feed_type)
	water_all()
	collect_all_products()


func get_save_data() -> Array:
	var data: Array = []
	for animal: AnimalBase in animals:
		data.append(animal.get_save_data())
	return data


func _exit_tree() -> void:
	# Sync animal data back to BarnData before exiting
	_sync_to_barn_data()
	BarnData.is_barn_scene_active = false


func _sync_from_barn_data() -> void:
	# Clear existing animals
	for animal in animals:
		remove_child(animal)
		animal.queue_free()
	animals.clear()
	current_occupancy = 0.0

	# Load animals from BarnData
	var animal_data_list: Array[Dictionary] = BarnData.get_animals()
	for data in animal_data_list:
		var animal: AnimalBase = _create_animal_from_data(data)
		if animal:
			# Add to animals array and as child node
			animals.append(animal)
			add_child(animal)
			# Position near spawn area with random offset
			animal.global_position = _get_random_spawn_position()
			# Update occupancy
			current_occupancy += _get_space_cost(animal)


func _create_animal_from_data(data: Dictionary) -> AnimalBase:
	var animal := AnimalBase.new()
	# Set exported properties from dictionary
	animal.animal_id = data.get("animal_id", &"")
	animal.animal_type = data.get("animal_type", &"")
	animal.display_name = data.get("display_name", "")
	animal.daily_feed_cost = data.get("daily_feed_cost", 2)
	animal.daily_water_cost = data.get("daily_water_cost", 1)
	animal.feed_item_id = data.get("feed_item_id", &"")
	animal.product_item_id = data.get("product_item_id", &"")
	animal.product_cycle_days = data.get("product_cycle_days", 4)
	animal.maturity_days = data.get("maturity_days", 4)
	# Set runtime state from dictionary
	animal.current_state = data.get("current_state", 0) as AnimalBase.AnimalState
	animal.is_baby = data.get("is_baby", true)
	animal.age_days = data.get("age_days", 0)
	animal.hunger_days = data.get("hunger_days", 0)
	animal.fed_today = data.get("fed_today", false)
	animal.watered_today = data.get("watered_today", false)
	animal.products_ready = data.get("products_ready", 0)
	animal.cycle_days_elapsed = data.get("cycle_days_elapsed", 0)
	animal.weak_recovery_remaining = data.get("weak_recovery_remaining", 0)
	# Visual setup - create a simple colored sprite for now
	_setup_animal_visual(animal)
	return animal


func _setup_animal_visual(animal: AnimalBase) -> void:
	var sprite := AnimatedSprite2D.new()
	# Create simple placeholder frames
	var frames := SpriteFrames.new()
	# Add a placeholder animation frame using a colored rectangle
	# For pig: pink color, for chicken: yellow color
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	if animal.animal_type == &"Pig":
		img.fill(Color(1.0, 0.6, 0.7))  # Pink for pig
	elif animal.animal_type == &"Chicken":
		img.fill(Color(1.0, 0.9, 0.3))  # Yellow for chicken
	else:
		img.fill(Color(0.8, 0.8, 0.8))  # Gray default
	var tex := ImageTexture.create_from_image(img)
	frames.add_frame("idle", tex)
	frames.add_frame("idle_baby", tex)
	frames.add_frame("weak", tex)
	frames.add_frame("dead", tex)
	sprite.sprite_frames = frames
	sprite.animation = "idle_baby" if animal.is_baby else "idle"
	animal.add_child(sprite)


func _get_random_spawn_position() -> Vector2:
	# Try to get spawn area position, otherwise use a default position
	if has_node("AnimalSpawnArea"):
		var spawn_area := get_node("AnimalSpawnArea")
		var pos := spawn_area.global_position
		# Add some random offset
		pos.x += randf_range(-20, 20)
		pos.y += randf_range(-20, 20)
		return pos
	return Vector2(400, 300)  # Default position if spawn area not found


func _sync_to_barn_data() -> void:
	# Sync all animals back to BarnData
	for animal in animals:
		var animal_data := _animal_to_dict(animal)
		BarnData.update_animal(animal.animal_id, animal_data)


func _animal_to_dict(animal: AnimalBase) -> Dictionary:
	return {
		"animal_id": animal.animal_id,
		"animal_type": animal.animal_type,
		"display_name": animal.display_name,
		"is_baby": animal.is_baby,
		"age_days": animal.age_days,
		"hunger_days": animal.hunger_days,
		"fed_today": animal.fed_today,
		"watered_today": animal.watered_today,
		"products_ready": animal.products_ready,
		"cycle_days_elapsed": animal.cycle_days_elapsed,
		"current_state": animal.current_state,
		"weak_recovery_remaining": animal.weak_recovery_remaining,
		"daily_feed_cost": animal.daily_feed_cost,
		"daily_water_cost": animal.daily_water_cost,
		"feed_item_id": animal.feed_item_id,
		"product_item_id": animal.product_item_id,
		"product_cycle_days": animal.product_cycle_days,
		"base_product_amount":
		animal._get_base_product_amount() if animal.has_method("_get_base_product_amount") else 10,
		"maturity_days": animal.maturity_days,
		"max_hunger_days": 8,  # Default, could be exported
		"weak_threshold_days": 2,
		"weak_recovery_days": 2,
		"space_occupied": 1.0 if not animal.is_baby else 0.5,
	}
