class_name AnimalBase
extends CharacterBody2D

enum AnimalState { HEALTHY, HUNGRY, WEAK, DEAD }

@export var animal_id: StringName = &""
@export var animal_type: StringName = &""
@export var display_name: String = ""
@export var daily_feed_cost: int = 2
@export var daily_water_cost: int = 1
@export var feed_item_id: StringName = &""
@export var product_item_id: StringName = &""
@export var product_cycle_days: int = 4
@export var maturity_days: int = 4

var current_state: AnimalState = AnimalState.HEALTHY
var is_baby: bool = true
var age_days: int = 0
var hunger_days: int = 0
var weak_recovery_remaining: int = 0
var fed_today: bool = false
var watered_today: bool = false
var products_ready: int = 0
var cycle_days_elapsed: int = 0

var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var wander_speed: float = 20.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_indicator: Sprite2D = $StateIndicator


func _ready() -> void:
	EventBus.new_day_started.connect(_on_new_day)
	_pick_wander_target()


func _physics_process(delta: float) -> void:
	if current_state == AnimalState.DEAD:
		velocity = Vector2.ZERO
		return

	wander_timer -= delta
	if wander_timer <= 0.0:
		_pick_wander_target()
		wander_timer = randf_range(2.0, 5.0)

	var dir: Vector2 = wander_target - global_position
	if dir.length() > 4.0:
		velocity = dir.normalized() * wander_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _pick_wander_target() -> void:
	var parent: Node2D = get_parent() as Node2D
	if parent:
		var bounds: Rect2 = _get_wander_bounds()
		wander_target = Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
	else:
		wander_target = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))


func _get_wander_bounds() -> Rect2:
	return Rect2(global_position - Vector2(80, 80), Vector2(160, 160))


func feed() -> bool:
	var feed_needed: int = 1 if is_baby else daily_feed_cost
	if not InventoryManager.remove_item(feed_item_id, feed_needed):
		return false
	fed_today = true
	return true


func water() -> bool:
	watered_today = true
	return true


func collect_products() -> int:
	if products_ready <= 0:
		return 0
	var collected: int = products_ready
	products_ready = 0
	InventoryManager.add_item(product_item_id, collected)
	EventBus.animal_product_collected.emit(animal_type, product_item_id, collected)
	return collected


func _on_new_day(_day: int) -> void:
	age_days += 1

	if is_baby and age_days >= maturity_days:
		is_baby = false

	var _state_before: int = current_state

	if not fed_today or not watered_today:
		hunger_days += 1
		if hunger_days >= 2:
			current_state = AnimalState.WEAK
			weak_recovery_remaining = 2
		if hunger_days >= 8:
			current_state = AnimalState.DEAD
			_die()
			return
	else:
		if current_state == AnimalState.WEAK:
			weak_recovery_remaining -= 1
			if weak_recovery_remaining <= 0:
				current_state = AnimalState.HEALTHY
		else:
			hunger_days = 0
			current_state = AnimalState.HEALTHY

	# Emit signal when state actually changed
	if current_state != _state_before:
		EventBus.animal_state_changed.emit(animal_id, current_state)

	if current_state == AnimalState.HEALTHY and not is_baby:
		cycle_days_elapsed += 1
		if cycle_days_elapsed >= product_cycle_days:
			cycle_days_elapsed = 0
			products_ready += _get_base_product_amount()

	fed_today = false
	watered_today = false
	_update_visual()


func _get_base_product_amount() -> int:
	return 10


func _die() -> void:
	EventBus.animal_state_changed.emit(animal_id, AnimalState.DEAD)


func _update_visual() -> void:
	if sprite:
		var anim: String = "idle_baby" if is_baby else "idle"
		if current_state == AnimalState.WEAK:
			anim = "weak"
		if current_state == AnimalState.DEAD:
			anim = "dead"
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
	if state_indicator:
		state_indicator.visible = (current_state != AnimalState.HEALTHY)


func get_save_data() -> Dictionary:
	return {
		"animal_id": String(animal_id),
		"animal_type": String(animal_type),
		"state": current_state,
		"is_baby": is_baby,
		"age_days": age_days,
		"hunger_days": hunger_days,
		"weak_recovery": weak_recovery_remaining,
		"fed_today": fed_today,
		"watered_today": watered_today,
		"products_ready": products_ready,
		"cycle_days": cycle_days_elapsed,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
	}


func load_save_data(data: Dictionary) -> void:
	current_state = data.get("state", AnimalState.HEALTHY) as AnimalState
	is_baby = data.get("is_baby", true)
	age_days = data.get("age_days", 0)
	hunger_days = data.get("hunger_days", 0)
	weak_recovery_remaining = data.get("weak_recovery", 0)
	fed_today = data.get("fed_today", false)
	watered_today = data.get("watered_today", false)
	products_ready = data.get("products_ready", 0)
	cycle_days_elapsed = data.get("cycle_days", 0)
	global_position = Vector2(data.get("pos_x", 0), data.get("pos_y", 0))
	_update_visual()
