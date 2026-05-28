extends Node

## Persistent storage for barn animals. Bridges shop purchases and barn scene.
## Animals are stored as dictionaries so they survive scene transitions.

signal animal_added(animal_data: Dictionary)
signal animal_removed(animal_id: StringName)

const MAX_BARN_CAPACITY: float = 10.0

## Array of dictionaries, each representing an animal's persistent state
var _animals: Array[Dictionary] = []

## Flag to indicate if the barn scene is currently active
var is_barn_scene_active: bool = false


func _ready() -> void:
	EventBus.new_day_started.connect(_on_new_day)


## Get all animals
func get_animals() -> Array[Dictionary]:
	return _animals


## Get current occupancy (babies = 0.5, adults = 1.0)
func get_occupancy() -> float:
	var occ: float = 0.0
	for a in _animals:
		occ += 0.5 if a.get("is_baby", true) else 1.0
	return occ


## Check if barn has room for a new animal
func has_room(is_baby: bool = true) -> bool:
	var needed: float = 0.5 if is_baby else 1.0
	return get_occupancy() + needed <= MAX_BARN_CAPACITY


## Add an animal from a template dictionary
func add_animal(animal_template: Dictionary) -> bool:
	if not has_room(animal_template.get("is_baby", true)):
		return false
	var animal: Dictionary = animal_template.duplicate()
	if not animal.has("animal_id"):
		animal["animal_id"] = &"animal_%d" % _animals.size() + Time.get_ticks_msec()
	# Set defaults
	animal.setdefault("is_baby", true)
	animal.setdefault("age_days", 0)
	animal.setdefault("hunger_days", 0)
	animal.setdefault("fed_today", false)
	animal.setdefault("watered_today", false)
	animal.setdefault("products_ready", 0)
	animal.setdefault("cycle_days_elapsed", 0)
	animal.setdefault("current_state", 0)  # AnimalBase.AnimalState.HEALTHY
	animal.setdefault("weak_recovery_remaining", 0)
	_animals.append(animal)
	animal_added.emit(animal)
	return true


## Remove an animal by id
func remove_animal(animal_id: StringName) -> void:
	for i in range(_animals.size()):
		if _animals[i].get("animal_id", &"") == animal_id:
			_animals.remove_at(i)
			animal_removed.emit(animal_id)
			return


## Get animal by id
func get_animal(animal_id: StringName) -> Dictionary:
	for a in _animals:
		if a.get("animal_id", &"") == animal_id:
			return a
	return {}


## Update an animal's data (called when barn scene syncs back)
func update_animal(animal_id: StringName, data: Dictionary) -> void:
	for i in range(_animals.size()):
		if _animals[i].get("animal_id", &"") == animal_id:
			_animals[i] = data
			return


## Process daily growth for all animals (called when barn scene is NOT loaded)
func _on_new_day(day: int) -> void:
	# Skip processing if barn scene is active as it handles daily processing
	if is_barn_scene_active:
		return

	# Only process if BarnInterior is not currently handling it
	# BarnInterior will call update_animal() when it processes, so we skip here
	# if the barn scene is active. For now, we process all animals here.
	# The BarnInterior will sync from this data when it loads.
	var to_remove: Array[int] = []
	for i in range(_animals.size()):
		var a: Dictionary = _animals[i]
		# Age
		a["age_days"] = a.get("age_days", 0) + 1
		if a.get("is_baby", true) and a["age_days"] >= a.get("maturity_days", 4):
			a["is_baby"] = false

		# Hunger
		if not a.get("fed_today", false) or not a.get("watered_today", false):
			a["hunger_days"] = a.get("hunger_days", 0) + 1
		else:
			a["hunger_days"] = 0

		# State transitions
		var state: int = a.get("current_state", 0)
		var hunger: int = a.get("hunger_days", 0)
		var max_hunger: int = a.get("max_hunger_days", 8)
		var weak_threshold: int = a.get("weak_threshold_days", 2)

		if state != 3:  # Not DEAD
			if hunger >= max_hunger:
				a["current_state"] = 3  # DEAD
			elif hunger >= weak_threshold:
				a["current_state"] = 2  # WEAK
			elif state == 2:  # Was WEAK, check recovery
				if a.get("fed_today", false) and a.get("watered_today", false):
					a["weak_recovery_remaining"] = a.get("weak_recovery_remaining", 2) - 1
					if a["weak_recovery_remaining"] <= 0:
						a["current_state"] = 0  # HEALTHY
						a["weak_recovery_remaining"] = 0

		# Product cycle (only healthy adults)
		if a.get("current_state", 0) == 0 and not a.get("is_baby", true):
			a["cycle_days_elapsed"] = a.get("cycle_days_elapsed", 0) + 1
			if a["cycle_days_elapsed"] >= a.get("product_cycle_days", 4):
				a["products_ready"] = a.get("products_ready", 0) + a.get("base_product_amount", 10)
				a["cycle_days_elapsed"] = 0

		# Reset daily flags
		a["fed_today"] = false
		a["watered_today"] = false

		# Mark dead for removal
		if a.get("current_state", 0) == 3:
			to_remove.append(i)

	# Remove dead animals (reverse order to preserve indices)
	to_remove.reverse()
	for idx in to_remove:
		var removed: Dictionary = _animals.pop_at(idx)
		animal_removed.emit(removed.get("animal_id", &""))


## Save/load
func get_save_data() -> Dictionary:
	return {"animals": _animals}


func load_save_data(data: Dictionary) -> void:
	_animals.clear()
	var saved: Array = data.get("animals", [])
	for a in saved:
		_animals.append(a)


func reset() -> void:
	_animals.clear()
